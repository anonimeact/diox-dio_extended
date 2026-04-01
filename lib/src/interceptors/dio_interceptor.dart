import 'dart:async';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:dio_extended/src/interceptors/ansi_color.dart';

/// {@template dio_custom_interceptor}
/// Dio interceptor for automatic token refresh and retry mechanism.
///
/// - Detects token expiration (default: 401)
/// - Refreshes token using [TokenRefreshCallback]
/// - Queues concurrent requests while refreshing
/// - Retries failed requests after refresh completes
///
/// Log colors:
/// 🔐 Refresh in progress → yellow
/// 🔑 Success → green
/// ❌ Failure → red
/// {@endtemplate}
class DioInterceptor extends Interceptor {
  static const String _retryAfterRefreshKey = 'diox_retried_after_refresh';
  static const String skipRefreshExtraKey = 'diox_skip_refresh';
  static const String _internalRefreshRequestKey =
      'diox_internal_refresh_request';
  static final Object _refreshZoneKey = Object();

  final Dio dio;
  final TokenRefreshCallback refreshTokenCallback;
  final int tokenExpiredCode;
  Completer<void>? _refreshCompleter;

  DioInterceptor({
    required this.dio,
    required this.refreshTokenCallback,
    this.tokenExpiredCode = 401,
  });

  /// Interceptor responsible for dynamically setting the appropriate
  /// `Content-Type` header based on the request payload.
  ///
  /// Behavior:
  ///
  /// • **Multipart / FormData request**
  ///   When `options.data` is a `FormData` instance, the request is considered
  ///   a multipart upload. Multipart requests **must not** use a JSON
  ///   Content-Type, because Dio needs to generate its own multipart boundary.
  ///   Therefore:
  ///     - The `Content-Type` header is removed
  ///     - `options.contentType` is set to `null` to let Dio generate the correct
  ///       `multipart/form-data; boundary=...` header automatically
  ///
  /// • **Regular JSON request**
  ///   If the request is not multipart, it is treated as a regular JSON request.
  ///   In this case, the Content-Type is explicitly set to `application/json`.
  ///
  /// This prevents errors such as:
  /// `Invalid argument (contentType): Unable to set different values for contentType and the content-type header.`
  /// which occur when multipart requests accidentally inherit a JSON Content-Type.
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (Zone.current[_refreshZoneKey] == true) {
      options.extra[_internalRefreshRequestKey] = true;
    }

    if (options.data is FormData) {
      _removeContentTypeHeader(options.headers);
      options.contentType = null;
    } else {
      final hasContentTypeInHeader = _hasContentTypeHeader(options.headers);
      final hasExplicitContentType = options.contentType != null;
      if (!hasContentTypeInHeader && !hasExplicitContentType) {
        options.contentType = Headers.jsonContentType;
      }
    }
    handler.next(options);
  }

  /// Interceptor responsible for handling Dio errors, including token-expiration scenarios.
  ///
  /// • If the server responds with the configured `tokenExpiredCode`,
  ///   the interceptor attempts to refresh the token using the provided
  ///   `refreshTokenCallback`.
  ///
  /// • After the token is refreshed, the original request can be retried.
  ///
  /// • If the error is unrelated to token expiration, it is passed through
  ///   unchanged.
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    if (status != tokenExpiredCode) {
      return handler.next(err);
    }

    final shouldSkipRefresh =
        err.requestOptions.extra[skipRefreshExtraKey] == true ||
            err.requestOptions.extra[_internalRefreshRequestKey] == true;
    if (shouldSkipRefresh) {
      return handler.next(err);
    }

    final alreadyRetried =
        err.requestOptions.extra[_retryAfterRefreshKey] == true;
    if (alreadyRetried) {
      assert(() {
        developer.log(
          '${AnsiColor.red} ❌ Request still unauthorized after retry. Skipping refresh to prevent loop.${AnsiColor.reset}',
          name: 'DIO-EXTENDED',
          level: 1000,
        );
        return true;
      }());
      return handler.next(err);
    }

    assert(() {
      developer.log('${AnsiColor.magenta} 🔐 Token expired. ${AnsiColor.reset}',
          name: 'DIO-EXTENDED');
      return true;
    }());

    if (_refreshCompleter != null) {
      try {
        // Wait for the in-flight token refresh to complete.
        await _refreshCompleter!.future;

        // Retry the original request after refresh succeeds.
        final retryResponse = await _retryRequest(err.requestOptions);
        return handler.resolve(retryResponse);
      } catch (_) {
        // If refresh fails, all queued requests should fail as well.
        return handler.reject(err);
      }
    }

    // Create a new completer to queue concurrent requests.
    _refreshCompleter = Completer<void>()
      // Prevent unhandled async error when no queued request is awaiting.
      ..future.catchError((_) {});

    try {
      assert(() {
        developer.log(
            '${AnsiColor.magenta} 🔐 Refreshing token... ${AnsiColor.reset}',
            name: 'DIO-EXTENDED');
        return true;
      }());
      final newHeaders = await runZoned<Future<Map<String, dynamic>>>(
        () => refreshTokenCallback(),
        zoneValues: {_refreshZoneKey: true},
      );
      dio.options.headers.addAll(newHeaders);
      _refreshCompleter!.complete();

      assert(() {
        developer.log(
            '${AnsiColor.green} 🔑 Token refreshed successfully${AnsiColor.reset}',
            name: 'DIO-EXTENDED');
        return true;
      }());
    } catch (e, st) {
      _refreshCompleter!.completeError(e);
      developer.log(
        '${AnsiColor.red} ❌ Token refresh failed: $e${AnsiColor.reset}',
        name: 'DIO-EXTENDED',
        level: 1000,
        error: e,
        stackTrace: st,
      );
      return handler.reject(err);
    } finally {
      _refreshCompleter = null;
    }

    try {
      // Safely duplicate request options with refreshed headers.
      final retryResponse = await _retryRequest(err.requestOptions);

      assert(() {
        developer.log(
          '${AnsiColor.green} 🚀 Retried request successfully after token refresh${AnsiColor.reset}',
          name: 'DIO-EXTENDED',
        );
        return true;
      }());

      return handler.resolve(retryResponse);
    } catch (e) {
      developer.log(
        '${AnsiColor.red} ❌ Retried request failed after token refresh: $e${AnsiColor.reset}',
        name: 'DIO-EXTENDED',
        level: 1000,
      );
      return handler
          .reject(DioException(requestOptions: err.requestOptions, error: e));
    }
  }

  Future<Response> _retryRequest(RequestOptions req) {
    final isFormData = req.data is FormData;
    final retryData = isFormData ? (req.data as FormData).clone() : req.data;
    final retryHeaders = Map<String, dynamic>.from(req.headers)
      ..addAll(dio.options.headers);
    final retryExtra = Map<String, dynamic>.from(req.extra)
      ..[_retryAfterRefreshKey] = true;
    String? retryContentType = req.contentType;
    if (isFormData) {
      _removeContentTypeHeader(retryHeaders);
      retryContentType = null;
    } else if (retryContentType != null) {
      // Avoid duplicate content-type definitions when contentType is explicit.
      _removeContentTypeHeader(retryHeaders);
    }

    final newOptions = req.copyWith(
      data: retryData,
      headers: retryHeaders,
      extra: retryExtra,
      contentType: retryContentType,
    );

    return dio.fetch(newOptions);
  }

  bool _removeContentTypeHeader(Map<String, dynamic> headers) {
    String? contentTypeKey;
    for (final key in headers.keys) {
      if (key.toLowerCase() == Headers.contentTypeHeader) {
        contentTypeKey = key;
        break;
      }
    }
    if (contentTypeKey == null) {
      return false;
    }
    headers.remove(contentTypeKey);
    return true;
  }

  bool _hasContentTypeHeader(Map<String, dynamic> headers) {
    for (final key in headers.keys) {
      if (key.toLowerCase() == Headers.contentTypeHeader) {
        return true;
      }
    }
    return false;
  }
}

/// Callback to refresh authentication tokens.
/// Should return new headers, e.g. `{ 'Authorization': 'Bearer <token>' }`.
typedef TokenRefreshCallback = Future<Map<String, dynamic>> Function();
