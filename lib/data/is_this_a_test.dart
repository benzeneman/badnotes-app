import 'dart:io';

import 'package:flutter/foundation.dart';

/// Whether this is running under `flutter test` rather than as the app.
/// Always false in a release build.
@pragma('vm:platform-const-if', !kDebugMode)
final isThisATest =
    kDebugMode && Platform.environment.containsKey('FLUTTER_TEST');
