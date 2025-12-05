/// A powerful Flutter library that enhances Dio with a simplified API response
/// handler and adds a convenient 'shake-to-debug' feature to open Chucker.
///
/// This package is designed to streamline your networking layer and improve your
/// debugging workflow. It provides two main components:
///
/// 1.  **Dio Extensions (`dio_extended.dart`)**: A wrapper around the Dio HTTP client
///     that standardizes all responses into an `ApiResult<T>` object. This
///     abstracts away the boilerplate `try-catch` logic, status code checking,
///     and JSON parsing, allowing you to write cleaner and more resilient code.
///
/// 2.  **Shake for Chucker (`shake_for_chucker.dart`)**: A widget that enables
///     developers to instantly open the Chucker network inspection screen by
///     simply shaking their device. This is incredibly useful for debugging
///     network issues on a physical device without needing to navigate through
///     the app's UI.
///
/// ## Quick Start
///
/// To get started, follow these three simple steps:
///
/// 1.  **Wrap your application** with the `ShakeForChucker` widget to enable the
///     shake gesture. This should be done at the root of your app.
///
/// 2.  **Create an instance** of the `DioExtended` client in your widget or
///     service class where you will be making API calls.
///
/// 3.  **Make API calls** using the simplified methods like `get`, `post`, etc.
///     The call will return an `ApiResult`. You can then check the `isSuccess`
///     property to handle the response appropriately.
///
library;

export 'src/dio_extended.dart';
export 'src/chucker/shake_for_chucker.dart';
export 'src/chucker/shake_chucker_configs.dart';
