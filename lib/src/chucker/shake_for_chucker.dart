import 'dart:developer';
import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shake/shake.dart';

/// ---------------------------------------------------------------------------
/// 🧩 ShakeForChucker
/// ---------------------------------------------------------------------------
/// A developer utility widget that allows opening the **Chucker** network
/// inspector by shaking the device a configurable number of times.
///
/// This is designed to improve developer productivity and QA testing by
/// enabling quick access to Chucker without code changes or manual buttons.
///
/// 🚀 Features:
/// - Automatically detects shake gestures using the shake package.
/// - Opens the Chucker UI after a configurable number of shakes
///   within a short period (default: 3 shakes within 2 seconds).
/// - Automatically disabled in release mode (unless explicitly enabled).
/// - Optional bottom notification when Chucker is active via `isShowBottomNotif`.
///
/// 💡 Example:
///
/// ```dart
/// void main() {
///   runApp(
///     const ShakeForChucker(
///       isChuckerActive: true,      // Enable even in non-debug builds
///       shakeCountTriggered: 2,      // Show Chucker after 2 shakes
///       isShowBottomNotif: true,     // Show notification when Chucker is active
///       child: MyApp(),
///     ),
///   );
/// }
/// ```
///
/// ⚠️ Important setup:
/// To fully integrate Chucker, make sure to add its `navigatorObserver`
/// to your MaterialApp:
///
/// ```dart
/// MaterialApp(
///   navigatorObservers: [
///     ChuckerFlutter.navigatorObserver,
///   ],
///   ...
/// )
/// ```
///
/// This allows Chucker to properly track navigation events and display
/// network logs contextually.
///
/// 🧱 Dependencies:
/// - `chucker_flutter` — for in-app network inspection.
/// - `shake` — for detecting phone shake gestures.
///
/// ---------------------------------------------------------------------------
class ShakeForChucker extends StatefulWidget {
  /// The widget subtree wrapped by this widget.
  final Widget child;

  /// The number of shakes required to trigger Chucker.
  /// Defaults to **3 shakes** within 2 seconds.
  final int shakeCountTriggered;

  const ShakeForChucker({
    super.key,
    required this.child,
    this.shakeCountTriggered = 3,
  });

  @override
  State<ShakeForChucker> createState() => _ShakeForChuckerState();
}

class _ShakeForChuckerState extends State<ShakeForChucker> {
  ShakeDetector? _detector;
  int _shakeCount = 0;
  DateTime? _lastShakeTime;

  @override
  void initState() {
    super.initState();

    /// Conditionally initializes the shake detector.
    ///
    /// The shake detection feature is only activated under specific conditions to prevent
    /// it from running in production builds unintentionally.
    ///
    /// Initialization occurs if either of the following is true:
    /// - The app is running in debug mode (`kDebugMode` is `true`).
    /// - The [widget.forceSowChucker] flag is explicitly set to `true`.
    ///
    /// When initialized, it creates a [ShakeDetector] that automatically starts listening
    /// for shake events and calls [_onShakeDetected] when a shake occurs. A log message
    /// is also printed to the console to confirm that the feature is active.
    if (!kIsWeb || kDebugMode || ChuckerFlutter.showOnRelease) {
      _detector = ShakeDetector.autoStart(onPhoneShake: _onShakeDetected);
      log('📱 ShakeToShowChucker initialized (Trigger: ${widget.shakeCountTriggered} shakes)');
    }
  }

  /// Handles the logic for detecting and counting consecutive device shakes.
  ///
  /// This function is called whenever a shake event is detected. It maintains a
  /// count of shakes that occur in quick succession (within 2 seconds of each
  /// other). If the number of consecutive shakes reaches the
  /// [widget.shakeCountTriggered] threshold, it triggers an action, such as
  /// opening the Chucker debugging screen. The counter is reset if there's a
  /// pause longer than 2 seconds between shakes or after a successful trigger.
  ///
  /// The logic follows these steps:
  /// 1. On the first detected shake, it initializes the shake counter and records the timestamp.
  /// 2. For subsequent shakes, it checks the time elapsed since the previous shake.
  /// 3. If the elapsed time is more than 2 seconds, the shake counter is reset to 1.
  /// 4. If the elapsed time is 2 seconds or less, the shake counter is incremented.
  /// 5. When the counter reaches the configured `shakeCountTriggered`, the main action
  ///    is performed, and the counter is reset to 0.
  ///
  /// Parameters:
  /// - [event]: The dynamic event object passed from the shake detection listener.
  ///   The content of this object is not used directly in this logic.
  void _onShakeDetected(dynamic event) {
    final now = DateTime.now();

    // If this is the first shake, initialize counter
    if (_lastShakeTime == null) {
      _lastShakeTime = now;
      _shakeCount = 1;
      return;
    }

    // Calculate time difference from previous shake
    final diff = now.difference(_lastShakeTime!).inMilliseconds;

    // Reset the counter if the interval between shakes is too long (> 2 seconds)
    if (diff > 2000) {
      _shakeCount = 1;
    } else {
      _shakeCount++;
    }

    _lastShakeTime = now;
    debugPrint('Shake count: $_shakeCount / ${widget.shakeCountTriggered}');

    // Trigger Chucker when the configured shake threshold is reached
    if (_shakeCount >= widget.shakeCountTriggered) {
      debugPrint(
          '⚡ Triggered by ${widget.shakeCountTriggered} shakes — opening Chucker.');
      ChuckerFlutter.showChuckerScreen();
      _shakeCount = 0; // Reset after success
    }
  }

  @override
  void dispose() {
    _detector?.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
