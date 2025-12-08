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
    if (options.data is FormData) {
      options.headers.remove('Content-Type');
      options.contentType = null;
    } else {
      options.contentType = Headers.jsonContentType;
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

    assert(() {
      developer.log(
          '${AnsiColor.magenta} 🔐 Token expired. Refreshing...${AnsiColor.reset}',
          name: 'DIO-EXTENDED');
      return true;
    }());

    if (_refreshCompleter != null) {
      try {
        // Waiting refresh token finish when _refreshCompleter != null
        await _refreshCompleter!.future;

        // Retry request when refresh token complete
        final retryResponse = await _retryRequest(err.requestOptions);
        return handler.resolve(retryResponse);
      } catch (_) {
        // All concurent will failed if refreshing token failed
        return handler.reject(err);
      }
    }

    // Init new Completer
    _refreshCompleter = Completer<void>();

    try {
      final newHeaders = await refreshTokenCallback();
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
      // Safely duplicate main request options with updated headers
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
    final newOptions = req.copyWith(
      headers: {
        ...req.headers,
        ...dio.options.headers,
      },
    );
    return dio.fetch(newOptions);
  }
}

/// Callback to refresh authentication tokens.
/// Should return new headers, e.g. `{ 'Authorization': 'Bearer <token>' }`.
typedef TokenRefreshCallback = Future<Map<String, dynamic>> Function();
