import 'dart:io';

import 'package:dio/dio.dart';
import 'package:diox/models/api_result.dart';
import 'package:diox/src/interceptors/dio_interceptor.dart';
import 'package:diox/src/interceptors/log_api_interceptor.dart';

/// Defines which HTTP method is used for uploading [FormData].
enum FormDataMethod { post, put }

/// {@template dio_extended}
/// A base class that extends Dio functionality with standardized
/// request handling, error wrapping, and optional token-refresh logic.
///
/// This class provides generic request helpers (`get`, `post`, `put`, `delete`)
/// that automatically return an [ApiResult] — unifying success and error
/// responses for cleaner business logic.
///
/// It also integrates:
/// - Custom logging via [LogApiInterceptor]
/// - Token auto-refresh with [DioCustomInterceptor]
///
/// Example usage:
/// ```dart
/// final dio = DioExtended(
///   baseUrl: 'https://api.example.com',
///   refreshTokenCallback: myRefreshTokenHandler,
/// );
///
/// final result = await dio.get<User>('users/1', decoder: User.fromJson);
///
/// if (result.isSuccess) {
///   print(result.data);
/// } else {
///   print(result.errorMessage);
/// }
/// ```
/// {@endtemplate}
class DioExtended {
  late final Dio _dio;
  final int tokenExpiredCode;

  /// Creates a new DioExtended instance with standardized configuration.
  ///
  /// [baseUrl] must be provided. You can optionally pass [defaultHeaders]
  /// to set global headers (like `Authorization`).
  /// If [refreshTokenCallback] is provided, the token refresh interceptor
  /// will automatically retry requests when a 401 (or custom [tokenExpiredCode]) occurs.
  DioExtended({
    required String baseUrl,
    Map<String, String>? defaultHeaders,
    this.tokenExpiredCode = 401,
    TokenRefreshCallback? refreshTokenCallback,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Accept': 'application/json', ...?defaultHeaders},
      ),
    );

    // Add debug logging interceptor (only active in debug mode)
    _dio.interceptors.add(const LogApiInterceptor());

    // Add token refresh interceptor if a callback is provided
    if (refreshTokenCallback != null) {
      _dio.interceptors.add(
        DioInterceptor(dio: _dio, refreshTokenCallback: refreshTokenCallback, tokenExpiredCode: tokenExpiredCode),
      );
    }
  }

  /// Exposes the underlying Dio instance for direct usage if needed.
  Dio get dio => _dio;

  // ===========================================================================
  // 🧩 GENERIC METHODS (GET, POST, PUT, DELETE)
  // ===========================================================================

  /// Sends a GET request and wraps the result in an [ApiResult].
  Future<ApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    T Function(dynamic data)? decoder,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );

      return _processResponse<T>(response, decoder: decoder);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResult.failure('Unexpected error: $e');
    }
  }

  /// Sends a POST request and wraps the result in an [ApiResult].
  Future<ApiResult<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    T Function(dynamic data)? decoder,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return _processResponse<T>(response, decoder: decoder);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResult.failure('Unexpected error: $e');
    }
  }

  /// Sends a PUT request and wraps the result in an [ApiResult].
  Future<ApiResult<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    T Function(dynamic data)? decoder,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return _processResponse<T>(response, decoder: decoder);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResult.failure('Unexpected error: $e');
    }
  }

  /// Sends a DELETE request and wraps the result in an [ApiResult].
  Future<ApiResult<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic data)? decoder,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return _processResponse<T>(response, decoder: decoder);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResult.failure('Unexpected error: $e');
    }
  }

  // ===========================================================================
  // 📦 FORM DATA UPLOAD
  // ===========================================================================

  /// Uploads multipart [FormData] using either POST or PUT.
  ///
  /// Use [method] to control which HTTP verb is used.
  /// Returns an [ApiResult] that wraps the parsed data or error info.
  Future<ApiResult<T>> sendFormData<T>(
    String path,
    FormData formData, {
    FormDataMethod method = FormDataMethod.post,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    T Function(dynamic data)? decoder,
  }) async {
    try {
      Response response;
      if (method == FormDataMethod.post) {
        response = await _dio.post(
          path,
          data: formData,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress,
        );
      } else {
        response = await _dio.put(
          path,
          data: formData,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress,
        );
      }

      return _processResponse<T>(response, decoder: decoder);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResult.failure('Unexpected error: $e');
    }
  }

  // ===========================================================================
  // 🧠 INTERNAL HELPERS
  // ===========================================================================

  /// Processes a successful Dio [Response] and decodes it to the desired type [T].
  ApiResult<T> _processResponse<T>(Response response, {T Function(dynamic data)? decoder}) {
    final status = response.statusCode ?? 0;

    if (status >= 200 && status < 300) {
      try {
        final body = response.data;
        final decoded = decoder != null ? decoder(body) : body as T?;
        return ApiResult.success(decoded as T, statusCode: status);
      } catch (e) {
        return ApiResult.failure('Failed to decode response: $e', statusCode: status);
      }
    }

    return ApiResult.failure(response.statusMessage ?? 'Request failed', statusCode: status);
  }

  /// Handles Dio-specific exceptions and converts them into [ApiResult]s.
  ApiResult<T> _handleDioError<T>(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return ApiResult.failure('Request timeout', statusCode: e.response?.statusCode);
    }

    if (e.error is SocketException) {
      return ApiResult.failure('No Internet connection', statusCode: e.response?.statusCode);
    }

    final status = e.response?.statusCode;

    final message = e.response?.data?.toString() ?? e.message ?? 'Unknown network error';
    return ApiResult.failure(message, statusCode: status);
  }

  // ===========================================================================
  // 🔐 TOKEN HANDLING
  // ===========================================================================

  /// Override this in subclasses to manually handle token refresh.
  ///
  /// If you pass a [TokenRefreshCallback] in the constructor,
  /// you don't need to override this method.
  Future<Map<String, dynamic>> handleTokenExpired() async => {};
}
