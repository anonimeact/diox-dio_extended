// ignore_for_file: unintended_html_in_doc_comment

import 'dart:io';

import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:dio/dio.dart';
import 'package:dio_extended/models/api_result.dart';
import 'package:dio_extended/src/interceptors/dio_interceptor.dart';
import 'package:dio_extended/src/interceptors/log_api_interceptor.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

/// Defines which HTTP method is used for uploading [FormData].
enum FormDataMethod { post, put }

/// A collection of global error message constants used across the app.
///
/// Use these messages when displaying fallback or network-related errors
/// to ensure consistent user-facing text throughout the application.
class ErrorMessages {
  /// A generic error message used for unexpected failures or unknown exceptions.
  static const globalError = 'An error occurred, please try again later.';

  /// A networking-specific error message used when the user has connectivity
  /// issues, such as no internet connection or unstable network conditions.
  static const globalNetworkError =
      'An error occurred, please try again later or check your internet connection.';
}

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
/// - Token auto-refresh with [DioInterceptor]
///
/// Example usage:
/// ```dart
/// final dio = DioExtended( baseUrl: 'https://api.example.com');
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
  final Duration timeout;
  final String? globalErrorMessage;
  final String? globalErrorNetworkingMessage;

  /// Creates a new [DioExtended] instance with standardized configuration.
  ///
  /// The [baseUrl] parameter is required and defines the root endpoint used
  /// for all HTTP requests made through this instance.
  ///
  /// You may optionally provide custom [headers] to be applied globally
  /// (e.g., `Authorization`, `Content-Type`, or any other HTTP header).
  ///
  /// The [tokenExpiredCode] is the HTTP status code that indicates the user's
  /// authentication has expired. By default, it uses `401`.
  ///
  /// The [timeout] determines the maximum time allowed for each
  /// request before it triggers a timeout exception. Default is 1 minute.
  ///
  /// The [globalErrorMessage] is a generic fallback error message used when
  /// unexpected or unknown errors occur.
  ///
  /// The [globalErrorNetworkingMessage] is used specifically when network
  /// conditions fail (e.g., no internet connection, DNS failure, or timeout).
  DioExtended({
    required String baseUrl,
    Map<String, String>? headers,
    Future<Map<String, String>?>? headersAsync,
    this.tokenExpiredCode = 401,
    this.timeout = const Duration(minutes: 1),
    this.globalErrorMessage,
    this.globalErrorNetworkingMessage,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: timeout,
        receiveTimeout: timeout,
        sendTimeout: timeout,
        headers: {'Accept': 'application/json'},
      ),
    );

    // Add debug logging interceptor (only active in debug mode)
    _dio.interceptors.add(const LogApiInterceptor());

    // Add chucker interceptor
    _dio.interceptors.add(ChuckerDioInterceptor());

    // Add token refresh interceptor if a callback is provided
    _dio.interceptors.add(
      DioInterceptor(
        dio: _dio,
        refreshTokenCallback: () async => await handleTokenExpired(),
        tokenExpiredCode: tokenExpiredCode,
      ),
    );

    // Apply asynchronous headers if provided
    if (headers != null) {
      _dio.options.headers.addAll(headers);
    } else if (headersAsync != null) {
      headersAsync.then((resolvedHeaders) {
        if (resolvedHeaders != null) {
          _dio.options.headers.addAll(resolvedHeaders);
        }
      });
    }
  }

  /// Exposes the underlying Dio instance for direct usage if needed.
  Dio get dio => _dio;

  // ===========================================================================
  // 🧩 GENERIC METHODS (GET, POST, PUT, DELETE)
  // ===========================================================================

  /// Sends an HTTP GET request to the specified [endpoint].
  ///
  /// This method wraps the Dio GET request, providing a simplified interface.
  /// Any exceptions encountered during the request will be re-thrown.
  ///
  /// To fetch a list of users with pagination:
  /// ```dart
  /// try {
  ///   final response = await apiService.get('/users', query: {'page': 1, 'limit': 10});
  ///   print(response.data);
  /// } on DioException catch (e) {
  ///   print('Error fetching users: $e');
  /// }
  /// ```
  ///
  /// Parameters:
  /// - [endpoint]: The URL path or the full URL for the request (e.g., '/users').
  /// - [query]: Optional query parameters. Typically a `Map<String, dynamic>`.
  ///
  /// Returns:
  /// - A `Future<Response>` that completes with the server's response.
  ///
  /// Throws:
  /// - Any `DioException` (or other exceptions) that occur during the request.
  Future<Response> get(String endpoint, {dynamic query}) async {
    try {
      return await _dio.get(endpoint, queryParameters: query);
    } catch (e) {
      rethrow;
    }
  }

  /// Sends an HTTP POST request to the specified [endpoint].
  ///
  /// This method wraps the Dio POST request, allowing for a request body,
  /// optional query parameters, and custom headers.
  /// Any exceptions encountered during the request will be re-thrown.
  ///
  /// To create a new user with an authorization header:
  /// ```dart
  /// try {
  ///   final newUser = {'name': 'John Doe', 'email': 'john.doe@example.com'};
  ///   final response = await apiService.post(
  ///     '/users',
  ///     body: newUser,
  ///     customheader: {'Authorization': 'Bearer your_token'},
  ///   );
  ///   print('User created with ID: ${response.data['id']}');
  /// } on DioException catch (e) {
  ///   print('Error creating user: $e');
  /// }
  /// ```
  ///
  /// Parameters:
  /// - [endpoint]: The URL path or the full URL for the request (e.g., '/users').
  /// - [body]: The request body, required. Can be a `Map`, `List`, `String`, etc.
  /// - [query]: Optional query parameters. Typically a `Map<String, dynamic>`.
  /// - [customheader]: Optional custom headers. Typically a `Map<String, String>`.
  ///
  /// Returns:
  /// - A `Future<Response>` that completes with the server's response.
  ///
  /// Throws:
  /// - Any `DioException` (or other exceptions) that occur during the request.
  Future<Response> post(String endpoint,
      {required dynamic body, dynamic query, dynamic customheader}) async {
    try {
      return await _dio.post(
        endpoint,
        data: body,
        queryParameters: query,
        options: Options(headers: customheader),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Sends an HTTP PUT request to the specified [endpoint].
  ///
  /// This method is typically used to update an existing resource.
  /// It allows for a request body, optional query parameters, and custom headers.
  /// Any exceptions encountered during the request will be re-thrown.
  ///
  /// To update a user's email address:
  /// ```dart
  /// try {
  ///   final updatedData = {'email': 'new.email@example.com'};
  ///   final response = await apiService.put('/users/123', body: updatedData);
  ///   print('User updated successfully');
  /// } on DioException catch (e) {
  ///   print('Error updating user: $e');
  /// }
  /// ```
  ///
  /// Parameters:
  /// - [endpoint]: The URL path or the full URL for the request (e.g., '/users/123').
  /// - [body]: The request body with the data to update. Can be a `Map`, `List`, `String`, etc.
  /// - [query]: Optional query parameters. Typically a `Map<String, dynamic>`.
  /// - [customheader]: Optional custom headers. Typically a `Map<String, String>`.
  ///
  /// Returns:
  /// - A `Future<Response>` that completes with the server's response.
  ///
  /// Throws:
  /// - Any `DioException` (or other exceptions) that occur during the request.
  Future<Response> put(String endpoint,
      {dynamic body, dynamic query, dynamic customheader}) async {
    try {
      return await _dio.put(
        endpoint,
        data: body,
        queryParameters: query,
        options: Options(headers: customheader),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Sends an HTTP DELETE request to the specified [endpoint].
  ///
  /// This method is used to remove a resource.
  /// It can optionally include a request body and query parameters.
  /// Any exceptions encountered during the request will be re-thrown.
  ///
  /// To delete a user with a specific ID:
  /// ```dart
  /// try {
  ///   final response = await apiService.delete('/users/123');
  ///   print('User deleted successfully');
  /// } on DioException catch (e) {
  ///   print('Error deleting user: $e');
  /// }
  /// ```
  ///
  /// Parameters:
  /// - [endpoint]: The URL path or the full URL for the request (e.g., '/users/123').
  /// - [body]: Optional request body.
  /// - [query]: Optional query parameters. Typically a `Map<String, dynamic>`.
  ///
  /// Returns:
  /// - A `Future<Response>` that completes with the server's response.
  ///
  /// Throws:
  /// - Any `DioException` (or other exceptions) that occur during the request.
  Future<Response> delete(String endpoint,
      {dynamic body, dynamic query}) async {
    try {
      return await _dio.delete(endpoint, data: body, queryParameters: query);
    } catch (e) {
      rethrow;
    }
  }

  /// Supports:
  /// - Single-field multi-file uploads
  /// - Multi-field multi-file uploads
  /// - Multi-field single-file uploads
  /// - Mixed upload modes
  /// - Any combination of files + normal fields
  /// - Automatic MIME type detection for every file
  ///
  /// PARAMETERS:
  /// - [singleFiles] : List<File?> for a single field
  /// - [singleFieldName] : Field name for singleFiles
  /// - [files] : Map<String, List<File?>> representing multi-field uploads
  /// - [body] : additional text fields (Map<String, dynamic>)
  /// - [method] : POST or PUT
  ///
  /// The function automatically:
  /// - Filters out null files
  /// - Detects correct MIME types using `package:mime`
  /// - Converts everything into MultipartFile
  /// - Merges files + body into a single FormData object
  /// - Sends with Dio POST/PUT
  ///
  ///
  /// ---------------------------------------------------------------------------
  /// USAGE EXAMPLES
  ///
  ///
  /// EXAMPLE 1 — Single-field multi-file
  /// -----------------------------------
  ///
  /// await sendFormData(
  ///   "/upload",
  ///   singleFiles: [file1, file2],
  ///   singleFieldName: "images",
  ///   body: {"title": "My Gallery"},
  /// );
  ///
  ///
  /// EXAMPLE 2 — Multi-field single-file
  /// -----------------------------------
  ///
  /// await sendFormData(
  ///   "/upload",
  ///   files: {
  ///     "image_1": [file1],
  ///     "image_2": [file2],
  ///   },
  ///   body: {"user_id": 123},
  /// );
  ///
  ///
  /// EXAMPLE 3 — Multi-field multi-file
  /// -----------------------------------
  ///
  /// await sendFormData(
  ///   "/upload",
  ///   files: {
  ///     "documents": [doc1, doc2],
  ///     "photos": [p1, p2, p3],
  ///   },
  /// );
  ///
  ///
  /// EXAMPLE 4 — Mixed usage
  /// ------------------------
  ///
  /// await sendFormData(
  ///   "/upload-all",
  ///   singleFiles: [avatar],
  ///   singleFieldName: "avatar",
  ///   files: {
  ///     "gallery": [g1, g2, g3],
  ///     "attachments": [a1, a2],
  ///   },
  ///   body: {"description": "Full upload"},
  /// );
  ///
  ///
  /// EXAMPLE 5 — Body only (no files)
  /// ---------------------------------
  ///
  /// await sendFormData(
  ///   "/save",
  ///   body: {"name": "John", "email": "john@mail.com"},
  /// );
  ///
  ///
  /// EXAMPLE 6 — PUT request
  /// ------------------------
  ///
  /// await sendFormData(
  ///   "/update",
  ///   method: FormDataMethod.put,
  ///   singleFiles: [profileImage],
  ///   singleFieldName: "profile_image",
  /// );
  ///
  /// ---------------------------------------------------------------------------
  /// Returns: Dio Response
  /// ---------------------------------------------------------------------------
  Future<Response> sendFormData(
    String endpoint, {
    Map<String, List<File?>>? files, // multi-field multi-file
    List<File?>? singleFiles, // single-field multi-file
    String singleFieldName = 'image', // default name for singleFiles
    Map<String, dynamic>? body, // normal fields
    FormDataMethod method = FormDataMethod.post,
  }) async {
    final Map<String, dynamic> fileMap = {};

    /// INTERNAL HELPER
    /// Converts File -> MultipartFile with automatic MIME detection
    Future<MultipartFile> toMultipart(File file) async {
      final fileName = file.path.split('/').last;

      // Detect MIME type (fallback to binary stream)
      final mime = lookupMimeType(file.path) ?? 'application/octet-stream';

      return MultipartFile.fromFile(
        file.path,
        filename: fileName,
        contentType: MediaType.parse(mime),
      );
    }

    // Handle single-field multi-file
    if (singleFiles != null && singleFiles.isNotEmpty) {
      final validFiles = singleFiles.where((f) => f != null).toList();

      if (validFiles.isNotEmpty) {
        final multipartFiles = await Future.wait(
          validFiles.map((file) => toMultipart(file!)),
        );

        fileMap[singleFieldName] = multipartFiles;
      }
    }

    // Handle multi-field multi-file
    if (files != null && files.isNotEmpty) {
      for (final entry in files.entries) {
        final key = entry.key;
        final validFiles = entry.value.where((f) => f != null).toList();
        if (validFiles.isEmpty) continue;

        final multipartFiles = await Future.wait(
          validFiles.map((file) => toMultipart(file!)),
        );

        fileMap[key] = multipartFiles;
      }
    }

    // Merge body + files into FormData
    final formData = FormData.fromMap({
      ...?body,
      ...fileMap,
    });

    // Execute HTTP request
    return method == FormDataMethod.post
        ? _dio.post(endpoint, data: formData)
        : _dio.put(endpoint, data: formData);
  }

  /// A centralized wrapper for executing API requests and returning a standardized [ApiResult].
  ///
  /// This function simplifies API calls by handling `try-catch` logic, status code
  /// validation, and data parsing in one place. It is designed to work seamlessly
  /// with the [ApiResult] class.
  ///
  /// The generic type `<T>` represents the type of the data object that will be
  /// parsed and returned on a successful request.
  ///
  /// To fetch a single user and parse it into a `User` object, you would first
  /// create a repository function like this:
  ///
  /// ```dart
  /// Future<ApiResult<User>> fetchUser(int userId) async {
  ///   return callApiRequest<User>(
  ///     request: () => _dio.get('/users/$userId'),
  ///     parseData: (json) => User.fromJson(json),
  ///   );
  /// }
  /// ```
  ///
  /// Then, you can use the function and handle the result cleanly:
  ///
  /// ```dart
  /// void getUserData() async {
  ///   final result = await fetchUser(1);
  ///
  ///   if (result.isSuccess) {
  ///     print('User fetched: ${result.data?.name}');
  ///   } else {
  ///     print('Error fetching user: ${result.message}');
  ///   }
  /// }
  /// ```
  ///
  /// Parameters:
  /// - [request]: A function that executes the Dio request and returns a `Future<Response>`.
  ///   This allows the `callApiRequest` method to control the execution within its `try-catch` block.
  /// - [parseData]: A function that takes the raw response data (typically `dynamic` JSON) and returns a
  ///   strongly-typed object of type `T`. This is your data model's `fromJson` factory or a custom parsing logic.
  ///
  /// Returns:
  /// - A `Future<ApiResult<T>>`. On success (status code 200-299), it completes with an
  ///   `ApiResult` where `isSuccess` is `true` and the `data` property holds the parsed object.
  ///   On any other status code or network exception, it completes with an `ApiResult`
  ///   where `isFailure` is `true` and the `message` property contains the error details.
  Future<ApiResult<T>> callApiRequest<T>(
      {required Future<Response> Function() request,
      required T Function(dynamic data) parseData,
      Duration? timeout}) async {
    try {
      final response =
          timeout != null ? await request().timeout(timeout) : await request();
      return _processResponse(response, decoder: parseData);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  /// Processes a Dio [Response] and decodes it to the desired type [T].
  ///
  /// This method checks if the HTTP status code indicates success (200-299).
  /// If successful, it attempts to decode the response body using the provided
  /// [decoder] function. If the decoder is `null`, it casts the body directly to `T`.
  ///
  /// Any errors during decoding (e.g., invalid JSON format) are caught and
  /// converted into an `ApiResult.failure`. Non-successful status codes also
  /// result in a failure.
  ///
  /// Parameters:
  /// - [response]: The Dio [Response] object to process.
  /// - [decoder]: An optional function to parse the response data into a specific type `T`.
  ///   If `null`, the raw response data is cast to `T`.
  ///
  /// Returns:
  /// - An `ApiResult.success<T>` if the status code is successful and decoding is successful.
  /// - An `ApiResult.failure<T>` if the status code is not successful or if decoding fails.
  ApiResult<T> _processResponse<T>(Response response,
      {T Function(dynamic data)? decoder}) {
    final status = response.statusCode ?? 0;

    if (status >= 200 && status < 300) {
      try {
        final body = response.data;
        final decoded = decoder != null ? decoder(body) : body as T?;
        return ApiResult.success(decoded as T, statusCode: status);
      } catch (e) {
        debugPrint('Failed to decode response: $e');
        return ApiResult.failure('Failed to decode response: $e',
            statusCode: status);
      }
    }

    return ApiResult.failure(
        response.statusMessage ?? ErrorMessages.globalError,
        statusCode: status);
  }

  /// Handles Dio-specific exceptions and converts them into a standardized [ApiResult].
  ///
  /// This function provides user-friendly error messages by inspecting the [DioException].
  /// It prioritizes messages from the server response body over generic Dio messages.
  ///
  /// Parameters:
  /// - [e]: The [DioException] caught during a network request.
  ///
  /// Returns:
  /// - Always returns an [ApiResult.failure] with a clear error message and status code.
  ApiResult<T> _handleDioError<T>(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ApiResult.failure('Request timeout',
          statusCode: e.response?.statusCode);
    }

    if (e.error is SocketException) {
      return ApiResult.failure(ErrorMessages.globalNetworkError,
          statusCode: e.response?.statusCode);
    }

    final statusCode = e.response?.statusCode;
    final serverMessage = _extractErrorMessage(e.response?.data);
    final dioMessage = e.message;
    final message = globalErrorMessage ??
        serverMessage ??
        dioMessage ??
        ErrorMessages.globalError;

    return ApiResult.failure(message, statusCode: statusCode);
  }

  /// A helper to safely extract an error message from a dynamic response body.
  ///
  /// Adjust the keys 'message' or 'error' to match your API's error response structure.
  String? _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] ?? data['error']?.toString();
    }
    if (data is String) {
      return data;
    }
    return null;
  }

  // ===========================================================================
  // 🔐 REFRESH TOKEN HANDLING
  // ===========================================================================

  /// Override this in subclasses to manually handle token refresh.
  ///
  /// If you pass a [TokenRefreshCallback] in the constructor,
  /// you don't need to override this method.
  Future<dynamic> handleTokenExpired() async => {};
}
