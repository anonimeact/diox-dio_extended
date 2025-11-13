# Dio Extended - DioX

A light wrapper around `dio` that standardizes network calls, error handling,
and optional token refresh logic. `diox` returns a unified `ApiResult<T>` for
all requests so application code can handle success/failure in a consistent
way.

## Summary

- A small Dio wrapper that provides generic request helpers and unified
  responses (`ApiResult<T>`).
- Centralized error handling (timeouts, no-internet, server errors, decode
  failures).
- Optional automatic token refresh with retry support via a refresh callback.
- Built-in logging and easy integration with Chucker (dev-time network inspector).

## Features

- Standardized `ApiResult<T>` wrapper for all network calls
- Generic helpers: `get`, `post`, `put`, `delete`, `sendFormData`
- Decoder callback to map raw response data into domain models
- Optional token refresh via `refreshTokenCallback` (interceptor-based)
- Upload multipart `FormData` with progress callbacks
- Built-in logging (`LogApiInterceptor`) and Chucker gesture helper

## Getting started

1. Add `diox` as a dependency in your `pubspec.yaml` (or use the local package
   if you're developing it).

2. Create an instance of `DioExtended`:

```dart
final api = DioExtended(
  baseUrl: 'https://api.example.com',
  defaultHeaders: {'Accept': 'application/json'},
  refreshTokenCallback: myRefreshHandler, // optional
);
```

## Usage examples

Simple GET with decoding:

```dart
final result = await api.get<User>('users/1',
  decoder: (data) => User.fromJson(data as Map<String, dynamic>),
);

if (result.isSuccess) {
  final user = result.data!; // User
} else {
  print('Error: ${result.message}');
}
```

POST with JSON body:

```dart
final create = await api.post<Post>('posts',
  data: {'title': 'Hello', 'body': 'World'},
  decoder: (d) => Post.fromJson(d as Map<String, dynamic>),
);
```

Upload file (multipart):

```dart
final form = FormData.fromMap({
  'name': 'file',
  'file': MultipartFile.fromFileSync('/path/to/file'),
});

final upload = await api.sendFormData<ResponseModel>('upload', form,
  method: FormDataMethod.post,
  onSendProgress: (sent, total) => print('progress: $sent/$total'),
  decoder: (d) => ResponseModel.fromJson(d as Map<String, dynamic>),
);
```

Token refresh callback signature (example):

```dart
/// Signature used by the internal interceptor to refresh tokens.
/// Implement this to return new headers or tokens used to retry requests.
Future<Map<String, dynamic>> myRefreshHandler() async {
  // call auth endpoint, store new token, return new headers etc.
  return {'Authorization': 'Bearer <new-token>'};
}
```

## Debugging & development

- `LogApiInterceptor` is attached by default (helps during debug builds).
- Use the Chucker helper (`shake_for_chucker.dart`) to show a network
  inspector on device during development.
- Example app available in the `example/` folder — run it to see typical usage.

## Notes & caveats

- `ApiResult.isSuccess` is implemented as `data != null`. If your API may
  legitimately return `null` bodies for successful responses, treat that
  case explicitly.
- When possible, provide a `decoder` to avoid unsafe `as T` casts.
- Default timeouts are 60 seconds — adjust via `Dio` options if needed.

## Contributing

See the top-level CONTRIBUTING guidelines (if any). For issues or feature
requests, open an issue on the repository.

## License

This project follows the repository license (check `LICENSE` file if present).