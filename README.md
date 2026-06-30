<div align="center">

# 🚀 DioExtended

### A thin, result-based wrapper over [`dio`](https://pub.dev/packages/dio) that makes networking in Flutter clean, safe, and boilerplate-free.

<br/>

[![pub version](https://img.shields.io/pub/v/dio_extended.svg?style=for-the-badge&logo=dart&color=0175C2)](https://pub.dev/packages/dio_extended)
[![pub points](https://img.shields.io/pub/points/dio_extended?style=for-the-badge&logo=flutter&color=02569B)](https://pub.dev/packages/dio_extended/score)
[![license](https://img.shields.io/badge/License-MIT-success.svg?style=for-the-badge)](LICENSE)
[![platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux-blueviolet?style=for-the-badge)](https://pub.dev/packages/dio_extended)

<br/>

`DioExtended` returns a consistent **`ApiResult<T>`** for every request, so error handling and JSON parsing stay simple and predictable. Optional Chucker helpers are exposed from a separate import so the core package stays platform-neutral.

</div>

---

## 📑 Table of Contents

| Section | Description |
| :--- | :--- |
| [✨ Features](#-features) | What you get out of the box |
| [📦 Installation](#-installation) | Add the package to your project |
| [⚡ Quick Start](#-quick-start) | Up and running in 30 seconds |
| [🌐 DioExtended](#-dioextended-simplified-networking) | The core networking client |
| [🔐 Token Refresh](#-token-refresh-optional) | Automatic 401 handling |
| [📳 ShakeForChucker](#-shakeforchucker-debug-with-a-shake) | Debug by shaking your phone |
| [❓ FAQ](#-faq) | Common questions answered |

---

## ✨ Features

| | Feature | Description |
| :---: | :--- | :--- |
| 🧩 | **Simplified API** | Every call returns a clean, typed `ApiResult<T>` interface. |
| 🔄 | **Automatic JSON Parsing** | Decode responses into your models with a simple `parseData` function. |
| 🔐 | **Built-in Token Refresh** | Override one method to auto-handle expired tokens and retry requests. |
| 📳 | **Shake for Debugging** | Open the network inspector with a shake gesture — perfect for QA. |
| 🧱 | **FormData Safe** | Correctly separates `Content-Type` handling for `FormData` vs JSON, even on retry. |

---

## 📦 Installation

Add `dio_extended` to your `pubspec.yaml`:

```yaml
dependencies:
  dio_extended: ^2.0.0
```

Then run:

```bash
flutter pub get
```

> [!NOTE]
> Chucker helpers are available from `package:dio_extended/diox_chucker.dart`.

> [!IMPORTANT]
> Since `2.0.0`, Chucker APIs are no longer exported from `package:dio_extended/diox.dart`. If you use `ShakeForChucker`, `ShakeChuckerConfigs`, or `createChuckerInterceptor()`, add a separate import for `package:dio_extended/diox_chucker.dart`.

---

## ⚡ Quick Start

```dart
import 'package:dio_extended/diox.dart';

class CrudService extends DioExtended {
  CrudService() : super(baseUrl: 'https://jsonplaceholder.typicode.com');

  Future<ApiResult<List<PostModel>>> getPosts() {
    return callApiRequest<List<PostModel>>(
      request: () => get('/posts'),
      parseData: (data) =>
          (data as List).map((e) => PostModel.fromJson(e)).toList(),
    );
  }
}

// ...

final result = await CrudService().getPosts();
if (result.isSuccess) {
  print(result.data); // 🎉 Typed list of PostModel
} else {
  print(result.message); // ⚠️ Friendly error message
}
```

---

## 🌐 DioExtended: Simplified Networking

`DioExtended` is the core of this package. It streamlines HTTP requests and returns a consistent `ApiResult<T>` object for all calls, making error handling and data parsing straightforward.

<details open>
<summary><b>🔧 Initialization</b></summary>

<br/>

Set up your API client with a base URL and default headers. Use `headers` for synchronous values and `headersAsync` when headers need async preparation.

```dart
import 'package:dio_extended/diox.dart';

// Static headers
final api = DioExtended(
  baseUrl: 'https://api.example.com',
  headers: {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  },
);

// Async headers (e.g. fetched from secure storage)
final api = DioExtended(
  baseUrl: 'https://api.example.com',
  headersAsync: _buildAuthHeaders(),
);

static Future<Map<String, String>?> _buildAuthHeaders() async {
  await Future.delayed(const Duration(seconds: 3)); // fetch simulation
  return {
    'Authorization': 'Bearer your_token_here',
    'Custom-Header': 'CustomValue',
  };
}

// Access the underlying Dio instance directly when needed
final dioInstance = api.dio;
```

Prefer a dedicated, independent service? Just extend `DioExtended`:

```dart
class CrudService extends DioExtended {
  CrudService() : super(baseUrl: 'YOUR-BASE-URL');
  // All DioExtended functions are now available here.
}
```

</details>

<details>
<summary><b>📥 GET Request Example</b></summary>

<br/>

Provide a `parseData` function to map the JSON response into your model.

```dart
/// Returns an [ApiResult] with a list of [PostModel] on success.
Future<ApiResult<List<PostModel>>> getPosts() async {
  return await callApiRequest<List<PostModel>>(
    request: () => get('/posts'),
    parseData: (data) => (data as List)
        .map((itemJson) => PostModel.fromJson(itemJson))
        .toList(),
  );
}

/// Single-object variant.
Future<ApiResult<PostModel>> getPost() async {
  return await callApiRequest<PostModel>(
    request: () => get('/posts/1'),
    parseData: (data) => PostModel.fromJson(data),
  );
}
```

Using `callApiRequest` handles fetching **and** parsing. On the business-logic side, just check `isSuccess`:

```dart
final result = await _service.getPosts();
if (result.isSuccess) {
  // ✅ Your logic here — result.data is fully typed
}
```

</details>

---

## 🔐 Token Refresh (Optional)

To handle automatic token refresh, simply override `handleTokenExpired`. The library calls this callback when a request fails with a `401` status (or a custom code via `tokenExpiredCode`), then retries the original request.

> [!TIP]
> - The interceptor safely separates `Content-Type` behavior for `FormData` and non-`FormData` requests, including on retry.
> - In `handleTokenExpired`, return **auth-related headers only** (e.g. `Authorization`). Avoid setting a global `Content-Type` from refresh headers.

```dart
class CrudService extends DioExtended {
  CrudService()
      : super(
          baseUrl: 'https://jsonplaceholder.typicode.com',
          tokenExpiredCode: 401,
        );

  /// Override to fetch a new auth token when the current one expires.
  @override
  Future<dynamic> handleTokenExpired() async {
    final newHeader = await fetchNewAuth();
    // Return as a Map, e.g. {'Authorization': 'Bearer xxx'}
    return newHeader;
  }
}
```

---

## 📳 ShakeForChucker: Debug with a Shake

`ShakeForChucker` integrates with [`chucker_flutter`](https://pub.dev/packages/chucker_flutter) to open the network inspection UI whenever you shake the device — ideal for developers and QA testers.

<details open>
<summary><b>⚙️ Setup</b></summary>

<br/>

Wrap your `MaterialApp` with `ShakeForChucker`, and attach `ShakeChuckerConfigs.navigatorKey` to your app's `navigatorKey`.

```dart
import 'package:flutter/material.dart';
import 'package:dio_extended/diox_chucker.dart';

void main() {
  // Initialize Chucker BEFORE runApp().
  ShakeChuckerConfigs.initialize(
    showOnRelease: true,
    showNotification: true,
  );

  runApp(
    ShakeForChucker(
      // Number of shakes needed to trigger Chucker (default: 3)
      shakeCountTriggered: 3,
      child: MaterialApp(
        title: 'DioExtended Demo',
        // Required so Chucker can show its inspector reliably.
        navigatorKey: ShakeChuckerConfigs.navigatorKey,
        home: const MyHomePage(),
      ),
    ),
  );
}
```

If you also want requests from `DioExtended` to appear in Chucker, register the optional interceptor:

```dart
import 'package:dio_extended/diox.dart';
import 'package:dio_extended/diox_chucker.dart';

final api = DioExtended(
  baseUrl: 'https://api.example.com',
  interceptors: [createChuckerInterceptor()],
);
```

> [!IMPORTANT]
> The older `navigatorObservers: [ShakeChuckerConfigs.navigatorObserver]` approach is now **deprecated**. Use `navigatorKey` instead — it works reliably even with nested navigators.

</details>

---

## ❓ FAQ

<details>
<summary><b>What does <code>callApiRequest</code> return on error?</b></summary>

<br/>

It returns an `ApiResult<T>` with `isSuccess == false` and a human-readable `message`. No exceptions are thrown for expected network/HTTP failures, so you can branch safely on `isSuccess`.

</details>

<details>
<summary><b>Can I still access the raw Dio instance?</b></summary>

<br/>

Yes. Every `DioExtended` exposes the underlying client via `api.dio`, so you can add interceptors, configure timeouts, or call advanced Dio APIs directly.

</details>

<details>
<summary><b>Does Chucker run in release builds?</b></summary>

<br/>

Only if you opt in. Set `showOnRelease: true` in `ShakeChuckerConfigs.initialize(...)`. By default Chucker is intended for debug/QA usage.

</details>

---

<div align="center">

Made with ❤️ for the Flutter community.

⭐ If this package helps you, consider starring the [repository](https://github.com/anonimeact/diox-dio_extended)!

</div>
