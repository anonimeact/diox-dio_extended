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

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;

    if (status == tokenExpiredCode) {
      assert(() {
        developer.log(
            '${AnsiColor.yellow} 🔐 Token expired. Refreshing...${AnsiColor.reset}',
            name: 'DIO-EXTENDED');
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
            '${AnsiColor.green} 🚀 Retried request successfully after token refresh${AnsiColor.reset}',
            name: 'DIO-EXTENDED',
          );
          return true;
        }());

        return handler.resolve(newResponse);
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

    handler.next(err);
  }
}

/// Callback to refresh authentication tokens.
/// Should return new headers, e.g. `{ 'Authorization': 'Bearer <token>' }`.
typedef TokenRefreshCallback = Future<Map<String, dynamic>> Function();
