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

  /// Whether this result represents a successful response.
  ///
  /// This flag is set explicitly at construction time rather than being
  /// inferred from [data]. This means a successful response is still
  /// considered successful even when its [data] is `null` (e.g. an HTTP
  /// `204 No Content` response or an endpoint that legitimately returns
  /// an empty body).
  final bool _isSuccess;

  /// Private constructor — use the factory constructors instead.
  const ApiResult._({
    this.data,
    this.message,
    this.statusCode,
    bool isSuccess = false,
  }) : _isSuccess = isSuccess;

  // ---------------------------------------------------------------------------
  // 🟢 FACTORY CONSTRUCTORS
  // ---------------------------------------------------------------------------

  /// Creates a successful API result containing [data].
  ///
  /// [data] may be `null` for responses that carry no body (for example a
  /// `204 No Content` response or an `ApiResult<void>`).
  factory ApiResult.success(T? data, {int? statusCode}) =>
      ApiResult._(data: data, statusCode: statusCode, isSuccess: true);

  /// Creates a failed API result with an [error] message.
  factory ApiResult.failure(String error, {int? statusCode}) =>
      ApiResult._(message: error, statusCode: statusCode);

  /// Creates an idle state result.
  factory ApiResult.idle() => ApiResult._();

  // ---------------------------------------------------------------------------
  // 📋 GETTERS
  // ---------------------------------------------------------------------------

  /// Returns `true` if the request completed successfully.
  ///
  /// Unlike previous versions, this no longer depends on [data] being
  /// non-null, so successful responses with an empty body are reported
  /// correctly.
  bool get isSuccess => _isSuccess;

  /// Returns `true` if the request failed.
  bool get isFailure => !_isSuccess && message != null;

  /// Returns `true` if this result is in its initial idle state
  /// (neither a success nor a failure).
  bool get isIdle => !_isSuccess && message == null;

  // ---------------------------------------------------------------------------
  // 🧭 UTILITIES
  // ---------------------------------------------------------------------------

  /// Converts this result into a human-readable string for logging/debugging.
  @override
  String toString() {
    if (isSuccess) {
      return 'ApiResult.success(status: $statusCode, data: $data)';
    }
    if (isIdle) {
      return 'ApiResult.idle()';
    }
    return 'ApiResult.failure(status: $statusCode, error: $message)';
  }

  /// Convenience method to transform the `data` field
  /// (for example, mapping DTOs to domain models).
  ApiResult<R> map<R>(R Function(T data) transform) {
    if (isSuccess) {
      return ApiResult.success(transform(data as T), statusCode: statusCode);
    }
    return ApiResult.failure(message ?? 'Unknown error',
        statusCode: statusCode);
  }
}
