import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:dio_extended/src/interceptors/ansi_color.dart';
import 'package:flutter/foundation.dart';

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
  final String requestColor;
  final String responseColor;
  final String errorColor;

  const LogApiInterceptor({
    this.requestColor = AnsiColor.brightCyan,
    this.responseColor = AnsiColor.brightGreen,
    this.errorColor = AnsiColor.red,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    assert(() {
      final msg = StringBuffer()
        ..writeln(
            '$requestColor🚀 [REQUEST] ${options.method} ${options.uri} #')
        ..writeln('$requestColor Headers: ${options.headers}');

      try {
        // --- Detect FormData ---
        if (options.data is FormData) {
          final formData = options.data as FormData;

          // Fields
          final fields = {
            for (var field in formData.fields) field.key: field.value,
          };

          // Files metadata only (not actual bytes)
          final files = formData.files.map((f) {
            final file = f.value;
            return {
              "field": f.key,
              "filename": file.filename,
              "contentType": file.contentType.toString(),
              "length": file.length,
            };
          }).toList();

          msg.writeln(
            '$requestColor Body (FormData): '
            '${_prettyPrintJson(data: {
                  "fields": fields,
                  "files": files
                }, color: AnsiColor.cyan)}'
            '${AnsiColor.reset}',
          );
        } else if (options.data != null) {
          msg.writeln(
            '$requestColor Body: ${_prettyPrintJson(data: options.data, color: AnsiColor.cyan)}${AnsiColor.reset}',
          );
        }
      } catch (e) {
        debugPrint("Error logging FormData onRequest");
      }

      developer.log('$requestColor${msg.toString()}', name: 'DIO-EXTENDED');
      return true;
    }());
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    assert(() {
      final msg = StringBuffer()
        ..writeln(
            '$responseColor ✅  [RESPONSE] ${response.statusCode} ${response.requestOptions.uri}${AnsiColor.reset}')
        ..writeln(
            '$responseColor Data: ${_prettyPrintJson(data: response.data, color: AnsiColor.green)}');

      developer.log(msg.toString(), name: 'DIO-EXTENDED');
      return true;
    }());
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    assert(() {
      final msg = StringBuffer()
        ..writeln(
            '$errorColor ❌ [ERROR] ${err.requestOptions.method} ${err.requestOptions.uri}')
        ..writeln('$errorColor Status: ${err.response?.statusCode}')
        ..writeln('$errorColor Message: ${err.message}')
        ..writeln(
            '$errorColor Body: ${_prettyPrintJson(data: err.response?.data, color: AnsiColor.red)}${AnsiColor.reset}');

      developer.log('$errorColor${msg.toString()}${AnsiColor.reset}',
          name: 'DIO-EXTENDED', level: 1000);
      return true;
    }());
    super.onError(err, handler);
  }

  /// Formats a dynamic object into a pretty-printed, multi-line JSON string
  /// and applies a uniform ANSI color to all lines.
  ///
  /// This is particularly useful for logging complex data structures to the console
  /// in a way that is both readable and visually distinct. The function handles
  /// `null` data gracefully by returning an empty string.
  ///
  /// Example:
  /// ```dart
  /// final myData = {
  ///   'id': 1,
  ///   'user': {'name': 'Alice'},
  ///   'items': ['a', 'b']
  /// };
  ///
  /// final coloredJson = _prettyPrintJson(data: myData, color: AnsiColor.cyan);
  /// print(coloredJson);
  /// ```
  ///
  /// The output in the terminal will be:
  /// ```
  /// [CYAN]{
  /// [CYAN]  "id": 1,
  /// [CYAN]  "user": {
  /// [CYAN]    "name": "Alice"
  /// [CYAN]  },
  /// [CYAN]  "items": [
  /// [CYAN]    "a",
  /// [CYAN]    "b"
  /// [CYAN]  ]
  /// [CYAN]}
  /// ```
  /// (Note: `[CYAN]` and `[RESET]` in the example above represent the actual non-printable ANSI codes.)
  ///
  /// Parameters:
  /// - [data]: The object to be converted to a JSON string. If `null`, an empty string is returned.
  /// - [color]: The ANSI color code string to apply to each line. It's recommended to use a constant from the [AnsiColor] class. If `null`, the string 'null' will be prepended to each line.
  ///
  /// Returns:
  /// A formatted, colorized JSON string ready for console output.
  String _prettyPrintJson({Object? data, String? color}) {
    if (data == null) return '';

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    final lines = jsonString.split('\n');

    final coloredLines = lines.asMap().entries.map((entry) {
      final line = entry.value;
      // Bungkus baris dengan warna dan kode reset
      return '$color$line${AnsiColor.reset}';
    }).toList();

    return coloredLines.join('\n');
  }
}
