import 'package:badnotes/i18n/strings.g.dart';

/// Thrown when signing in to the sync server does not work out.
abstract class LoginFailure implements Exception {
  /// What to tell the user.
  String get message => 'Login failed';
}

/// The encryption password the user typed cannot unlock their files.
class EncLoginFailure extends LoginFailure {
  /// Looked up in the current language when the error is made.
  @override
  final String message = t.login.encLoginStep.wrongEncPassword;
}
