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
///   navigatorKey: ShakeChuckerConfigs.navigatorKey,
/// );
/// ```
///
/// This ensures that Chucker is properly initialized before
/// `runApp()` and captures navigation history.
class ShakeChuckerConfigs {
  /// Returns the `GlobalKey<NavigatorState>` used by Chucker to display
  /// its inspector UI and notification overlay.
  ///
  /// Attach this to your root `MaterialApp.navigatorKey`. This is the
  /// recommended way to wire Chucker, as it works reliably even with
  /// nested navigators.
  static GlobalKey<NavigatorState> get navigatorKey =>
      ChuckerFlutter.navigatorKey;

  /// Returns the `NavigatorObserver` used by Chucker to log navigation
  /// events for inspection inside the Chucker UI.
  ///
  /// Attach this to your `MaterialApp.navigatorObservers` list.
  @Deprecated(
    'Use ShakeChuckerConfigs.navigatorKey on MaterialApp.navigatorKey '
    'instead. Observer-based wiring is unreliable with nested Navigators.',
  )
  static NavigatorObserver get navigatorObserver =>
      // ignore: deprecated_member_use
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
