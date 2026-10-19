import 'package:flutter/foundation.dart';

/// Holds view-only state for the sign-in and registration form.
class AuthFormProvider extends ChangeNotifier {
  bool _isRegistering = false;
  bool _passwordVisible = false;

  /// Whether the registration fields are currently shown.
  bool get isRegistering => _isRegistering;

  /// Whether the password field displays its contents.
  bool get passwordVisible => _passwordVisible;

  /// Switches between sign-in and account creation modes.
  void toggleMode() {
    _isRegistering = !_isRegistering;
    notifyListeners();
  }

  /// Toggles password visibility.
  void togglePasswordVisibility() {
    _passwordVisible = !_passwordVisible;
    notifyListeners();
  }
}
