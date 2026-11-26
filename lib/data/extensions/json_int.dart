import 'package:fixnum/fixnum.dart';

/// A whole number read back from a saved note. BSON gives back an [Int64]
/// for any number past 31 bits (a picture's order is a timestamp), and
/// `as int` on one threw, so the note opened as corrupted.
int? jsonInt(Object? value) => value is Int64 ? value.toInt() : value as int?;
