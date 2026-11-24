import 'package:flutter/material.dart';

extension ChangeNotifierExtensions on ChangeNotifier {
  /// Tells the listeners of a [ChangeNotifier] something changed, from
  /// outside it: [notifyListeners] is protected, though it's often needed
  /// after changing the notifier's data directly.
  void notifyListenersPlease() {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    notifyListeners();
  }
}
