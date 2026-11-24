import 'package:flutter/material.dart';

extension AxisExtensions on Axis {
  /// The axis at a right angle to this one.
  Axis get opposite => this == Axis.vertical ? Axis.horizontal : Axis.vertical;
}

extension AxisDirectionExtensions on AxisDirection {
  /// Vertical for up and down, horizontal for left and right.
  Axis get axis => axisDirectionToAxis(this);
}
