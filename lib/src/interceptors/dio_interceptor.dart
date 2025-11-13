import 'dart:async';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';

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

  // ANSI colors
  static const _yellow = '\x1B[33m';
  static const _green = '\x1B[32m';
  static const _red = '\x1B[31m';
  static const _reset = '\x1B[0m';

  DioInterceptor({
    required this.dio,
    required this.refreshTokenCallback,
    this.tokenExpiredCode = 401,
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;

    if (status == tokenExpiredCode) {
      assert(() {
        developer.log('$_yellow 🔐 Token expired. Refreshing...$_reset', name: 'DIO-EXTENDED');
        return true;
      }());

      if (_refreshCompleter != null) {
        await _refreshCompleter!.future;
      } else {
        _refreshCompleter = Completer<void>();

        try {
          final newHeaders = await refreshTokenCallback();
          dio.options.headers.addAll(newHeaders);
          _refreshCompleter!.complete();

          assert(() {
            developer.log('$_green 🔑 Token refreshed successfully$_reset', name: 'DIO-EXTENDED');
            return true;
          }());
        } catch (e, st) {
          _refreshCompleter!.completeError(e);
          developer.log(
            '$_red❌ Token refresh failed: $e$_reset',
            name: 'DIO-EXTENDED',
            level: 1000,
            error: e,
            stackTrace: st,
          );
          return handler.reject(err);
        } finally {
          _refreshCompleter = null;
        }
      }

      try {
        final req = err.requestOptions;

        // Safely duplicate request options with updated headers
        final RequestOptions newOptions = req.copyWith(
          headers: {
            ...req.headers,
            ...dio.options.headers,
          },
        );

        final Response<dynamic> newResponse = await dio.fetch(newOptions);

        assert(() {
          developer.log(
            '$_green🚀 Retried request successfully after token refresh$_reset',
            name: 'DIO-EXTENDED',
          );
          return true;
        }());

        return handler.resolve(newResponse);
      } catch (e) {
        developer.log(
          '$_red❌ Retried request failed after token refresh: $e$_reset',
          name: 'DIO-EXTENDED',
          level: 1000,
        );
        return handler.reject(DioException(requestOptions: err.requestOptions, error: e));
      }
    }

    handler.next(err);
  }
}

/// Callback to refresh authentication tokens.
/// Should return new headers, e.g. `{ 'Authorization': 'Bearer <token>' }`.
typedef TokenRefreshCallback = Future<Map<String, dynamic>> Function();
