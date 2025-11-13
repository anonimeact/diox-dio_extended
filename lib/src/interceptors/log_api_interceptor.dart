import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';

/// {@template log_api_interceptor}
/// Dio interceptor for clean, colorized API logs using `dart:developer.log`.
///
/// Request logs → yellow (`🚀 Request`)
/// Response logs → green (`✅ Response`)
/// Error logs → red (`❌ Error`)
///
/// Works on both Dart & Flutter, safe for long outputs, and pretty prints JSON.
/// {@endtemplate}
class LogApiInterceptor extends Interceptor {
  // ANSI color codes
  static const _yellow = '\x1B[33m';
  static const _green = '\x1B[32m';
  static const _red = '\x1B[31m';
  static const _reset = '\x1B[0m';

  const LogApiInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    assert(() {
      final msg = StringBuffer()
        ..writeln('🚀 [REQUEST] ${options.method} ${options.uri}')
        ..writeln('Headers: ${options.headers}')
        ..writeln('Body: ${_prettyPrintJson(options.data)}$_reset');

      developer.log('$_yellow${msg.toString()}', name: 'DIO-EXTENDED');
      return true;
    }());
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    assert(() {
      final msg = StringBuffer()
        ..writeln('✅ [RESPONSE] ${response.statusCode} ${response.requestOptions.uri}')
        ..writeln('Data: ${_prettyPrintJson(response.data)}$_reset');

      developer.log('$_green${msg.toString()}', name: 'DIO-EXTENDED');
      return true;
    }());
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    assert(() {
      final msg = StringBuffer()
        ..writeln('❌ [ERROR] ${err.requestOptions.method} ${err.requestOptions.uri}')
        ..writeln('Status: ${err.response?.statusCode}')
        ..writeln('Message: ${err.message}')
        ..writeln('Body: ${_prettyPrintJson(err.response?.data)}$_reset');

      developer.log('$_red${msg.toString()}', name: 'DIO-EXTENDED', level: 1000);
      return true;
    }());
    super.onError(err, handler);
  }

  String _prettyPrintJson(Object? data) {
    if (data == null) return '';
    try {
      if (data is String) {
        final decoded = json.decode(data);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      }
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      final text = data.toString();
      return text.length > 2000 ? '${text.substring(0, 2000)}... (truncated)' : text;
    }
  }
}
