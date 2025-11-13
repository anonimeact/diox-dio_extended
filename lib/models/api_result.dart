/// {@template api_result}
/// A generic wrapper class used to standardize and simplify
/// how API responses are represented across the app.
///
/// This class is useful when you want to unify success,
/// and failure results under a single type.
/// It’s especially handy for working with Dio or repository
/// layers where network errors must be caught gracefully.
///
/// Example:
/// ```dart
/// final result = await apiService.getUser();
///
/// if (result.isSuccess) {
///   print('User data: ${result.data}');
/// } else {
///   print('Error: ${result.message}');
/// }
/// ```
/// {@endtemplate}
class ApiResult<T> {
  /// The parsed or decoded data returned from the API.
  final T? data;

  /// The error message (if any) returned by the API or generated locally.
  final String? message;

  /// The HTTP status code of the API response (if available).
  final int? statusCode;

  /// Private constructor — use the factory constructors instead.
  const ApiResult._({this.data, this.message, this.statusCode});

  // ---------------------------------------------------------------------------
  // 🟢 FACTORY CONSTRUCTORS
  // ---------------------------------------------------------------------------

  /// Creates a successful API result containing [data].
  factory ApiResult.success(T data, {int? statusCode}) => ApiResult._(data: data, statusCode: statusCode);

  /// Creates a failed API result with an [error] message.
  factory ApiResult.failure(String error, {int? statusCode}) => ApiResult._(message: error, statusCode: statusCode);

  // ---------------------------------------------------------------------------
  // 📋 GETTERS
  // ---------------------------------------------------------------------------

  /// Returns `true` if the result contains data.
  bool get isSuccess => data != null;

  /// Returns `true` if there is an error message.
  bool get isFailure => message != null;

  // ---------------------------------------------------------------------------
  // 🧭 UTILITIES
  // ---------------------------------------------------------------------------

  /// Converts this result into a human-readable string for logging/debugging.
  @override
  String toString() {
    if (isSuccess) () => 'ApiResult.success(status: $statusCode, data: $data)';
    return 'ApiResult.failure(status: $statusCode, error: $message)';
  }

  /// Convenience method to transform the `data` field
  /// (for example, mapping DTOs to domain models).
  ApiResult<R> map<R>(R Function(T data) transform) {
    if (isSuccess && data != null) () => ApiResult.success(transform(data as T), statusCode: this.statusCode);
    return ApiResult.failure(message ?? 'Unknown error', statusCode: this.statusCode);
  }
}
