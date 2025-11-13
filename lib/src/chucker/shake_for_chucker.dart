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
/// - Automatically detects shake gestures using the [shake] package.
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

  /// Whether to enable the shake-to-open feature outside of `kDebugMode`.
  /// Useful for QA or staging builds.
  final bool forceSowChucker;

  /// The number of shakes required to trigger Chucker.
  /// Defaults to **3 shakes** within 2 seconds.
  final int shakeCountTriggered;

  /// Whether to show a bottom notification when Chucker is active.
  /// Defaults to **false**.
  final bool isShowBottomNotif;

  const ShakeForChucker({
    super.key,
    required this.child,
    this.forceSowChucker = false,
    this.shakeCountTriggered = 3,
    this.isShowBottomNotif = false,
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

    ChuckerFlutter.showOnRelease = false;
    ChuckerFlutter.showNotification = widget.isShowBottomNotif;

    // Only start listening in debug mode or if explicitly enabled
    if (kDebugMode || widget.forceSowChucker) {
      _detector = ShakeDetector.autoStart(onPhoneShake: _onShakeDetected);
      log('📱 ShakeToShowChucker initialized '
          '(trigger: ${widget.shakeCountTriggered} shakes)');
    }
  }

  /// Handles the logic for counting shake events.
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
      debugPrint('🟢 Triggered by ${widget.shakeCountTriggered} shakes — opening Chucker.');
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
