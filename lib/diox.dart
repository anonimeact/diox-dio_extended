/// A powerful Flutter library that enhances Dio with a simplified API response
/// handler.
///
/// This package is designed to streamline your networking layer and improve your
/// debugging workflow. It provides a core networking component:
///
/// 1.  **Dio Extensions (`dio_extended.dart`)**: A wrapper around the Dio HTTP client
///     that standardizes all responses into an `ApiResult<T>` object. This
///     abstracts away the boilerplate `try-catch` logic, status code checking,
///     and JSON parsing, allowing you to write cleaner and more resilient code.
///
/// ## Quick Start
///
/// To get started, follow these simple steps:
///
/// 1.  **Create an instance** of the `DioExtended` client in your widget or
///     service class where you will be making API calls.
///
/// 2.  **Make API calls** using the simplified methods like `get`, `post`, etc.
///     The call will return an `ApiResult`. You can then check the `isSuccess`
///     property to handle the response appropriately.
///
library;

export 'src/dio_extended.dart';
