import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:flutter/material.dart';

/// Provides configuration utilities and integration helpers
/// for Chucker within the `dio_extended` package.
///
/// This class allows the host application to configure Chucker
/// *without importing Chucker directly*, ensuring that the package
/// remains self-contained while exposing only the features needed
/// by the app.
///
/// Usage:
///
/// ```dart
/// void main() {
///   ShakeChuckerConfigs.initialize(
///     showOnRelease: false,
///     showOnNotification: true,
///   );
///
///   runApp(MyApp());
/// }
/// ```
///
/// Then inside your `MaterialApp`:
///
/// ```dart
/// MaterialApp(
///   navigatorObservers: [
///     ShakeChuckerConfigs.navigatorObserver,
///   ],
/// );
/// ```
///
/// This ensures that Chucker is properly initialized before
/// `runApp()` and captures navigation history.
class ShakeChuckerConfigs {
  /// Returns the `NavigatorObserver` used by Chucker to log navigation
  /// events for inspection inside the Chucker UI.
  ///
  /// Attach this to your `MaterialApp.navigatorObservers` list.
  static NavigatorObserver get navigatorObserver =>
      ChuckerFlutter.navigatorObserver;

  /// Initializes Chucker configuration.
  ///
  /// Call this **before `runApp()`** to ensure Chucker is properly
  /// configured during Flutter app startup.
  ///
  /// Parameters:
  ///
  /// - [showOnRelease]
  ///   Determines whether the Chucker UI should be accessible in
  ///   **release builds**. Set to `true` to enable Chucker in release mode.
  ///
  /// - [showNotification]
  ///   Controls whether Chucker should display the floating
  ///   **notification overlay** that allows opening the Chucker inspector.
  ///
  /// Example:
  ///
  /// ```dart
  /// ShakeChuckerConfigs.setup(
  ///   showOnRelease: false,
  ///   showNotification: true,
  /// );
  /// ```
  static void initialize({
    required bool showOnRelease,
    required bool showNotification,
  }) {
    ChuckerFlutter.showOnRelease = showOnRelease;
    ChuckerFlutter.showNotification = showNotification;
  }
}
