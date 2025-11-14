# DioExtended

`DioExtended` is a thin wrapper over the `dio` HTTP client that simplifies networking in Flutter. It provides a clean, result-based API (`ApiResult<T>`) for handling requests and responses, reducing boilerplate and making your code more robust.

This package also includes `ShakeForChucker`, a developer helper that allows you to instantly open the Chucker network inspector just by shaking your device.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [DioExtended: Simplified Networking](#dioextended-simplified-networking)
    - [Initialization](#initialization)
    - [GET Request Example](#get-request-example)
    - [Token Refresh (Optional)](#token-refresh-optional)
- [ShakeForChucker: Debug with a Shake](#shakeforchucker-debug-with-a-shake)
    - [Setup](#setup-1)

---

## Features

-   **Simplified API**: Handles requests and responses through a clean `ApiResult<T>` interface.
-   **Automatic JSON Parsing**: Easily decode responses to your model objects with a simple `decoder` function.
-   **Built-in Token Refresh**: Provides a callback mechanism to automatically handle authentication token expiration and retry requests.
-   **Shake for Debugging**: Integrate `ShakeForChucker` to open the network inspector with a simple gesture, perfect for development and QA.

## Installation

Add `dio_extended` to your `pubspec.yaml` file. We'll use `latest` to always get the newest version.

```yaml
dependencies:
  dio_extended: ^latest
```

> **Note**: 
> - The versions for `chucker_flutter` and `shake` are examples. Use the versions compatible with your project.
> - If you see error ***"Abortable' is from 'package:http/src/abortable.dart ...."*** when running, override chucker dependencies with master git version from *https://github.com/syedmurtaza108/chucker-flutter* on ***pubspect.yaml***. Because there are some issues with ***chucker_flutter*** last updated version

    dependency_overrides:
      chucker_flutter:
        git:
          url: https://github.com/syedmurtaza108/chucker-flutter.git
          ref: master

## DioExtended: Simplified Networking

`DioExtended` is the core of this package. It streamlines HTTP requests and returns a consistent `ApiResult<T>` object for all calls, making error handling and data parsing straightforward.

### Initialization

Set up your API client with a base URL and default headers.

```dart
import 'package:dio_extended/dio_extended.dart';

final api = DioExtended(
  baseUrl: 'https://api.example.com',
  headers: {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  },
);

// You can access the underlying Dio instance directly if needed
final dioInstance = api.dio;
```
If you want to create independent service, just do this on our class:
```
class CrudService extends DioExtended {
  CrudService() : super(baseUrl: 'YOUR-BASE-URL');
  /// Here you can use all function from DioExtend
  /// examples of its use are available ini Request Exampel 
}
```

### GET Request Example

Making a GET request is simple. Provide a decoder function to parse the JSON response into your model object.

```dart
  /// Fetches a list of all posts from the API.
  ///
  /// Returns an [ApiResult] containing a list of [PostModel] objects on success,
  /// or an error message on failure.
  Future<ApiResult<List<PostModel>>> getPosts() async {
    return await callApiRequest<List<PostModel>>(
      request: () => get('/posts'),
      parseData: (data) => (data as List)
          .map((itemJson) => PostModel.fromJson(itemJson))
          .toList(),
    );
  }
	
  /// Example for single model
  Future<ApiResult<PostModel>> getPosts() async {
    return await callApiRequest<List<PostModel>>(
      request: () => get('/posts'),
      parseData: (data) => PostModel.fromJson(itemJson)
    );
  }
```
Using *callApiRequest* will make us easier to fetch and parsing with the result model. In controller side (business logic), you can checking the result just using isSuccess or not.

    ```
	    final result = await _service.getPost();
	    if (result.isSuccess) {
			   /// Your logic here
	    }
    ```

### Token Refresh (Optional)

To handle automatic token refresh, just overriding `handleTokenExpired` . The library will automatically use this callback when a request fails with a 401 status code (or you can set other code with `tokenExpiredCode`) and then retry the original request.

```dart
class CrudService extends DioExtended {
  CrudService() : super(baseUrl: 'https://jsonplaceholder.typicode.com', tokenExpiredCode:  401);

  /// Overriding [handleTokenExpired] to fetch new auth key or etc
  @override
  Future<dynamic> handleTokenExpired() async {
    final newHeader = await fetchNewAutn();

    /// Send callback as Map
    /// exemple {'Authentication': 'Bearer xxx'}
    return newHeader;
  }
 }
```
#

## ShakeForChucker: Debug with a Shake

`ShakeForChucker` is a convenient utility for developers and QA testers. It integrates with the `chucker_flutter` package to open the network inspection UI when you shake the device.

### Setup

Wrap your `MaterialApp` with the `ShakeForChucker` widget. Make sure to also add `ChuckerFlutter.navigatorObserver` to your app.

```dart
import 'package:flutter/material.dart';
import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:dio_extended/src/chucker/shake_for_chucker.dart'; // Import path for ShakeForChucker

void main() {
  runApp(
    ShakeForChucker(
      // Set to true to enable in release/staging builds for QA
      forceShowChucker: true, 
      // Number of shakes needed to trigger Chucker (default is 3)
      shakeCountTriggered: 3, 
      // Shows a bottom notification when Chucker is opened
      isShowBottomNotif: true, 
      child: MaterialApp(
        title: 'DioExtended Demo',
        // This observer is required for Chucker to work correctly
        navigatorObservers: [
          ChuckerFlutter.navigatorObserver,
        ],
        home: const MyHomePage(),
      ),
    ),
  );
}
```

#### Important Parameters:

-   **`forceShowChucker`**: When `true`, this feature will be active even in non-debug builds (`kReleaseMode`). This is very useful for testing on staging or QA builds.
-   **`shakeCountTriggered`**: The number of shakes required within a 2-second window to open the Chucker UI.
-   **`isShowBottomNotif`**: If `true`, a small notification will appear at the bottom of the screen to confirm that Chucker has been opened.
