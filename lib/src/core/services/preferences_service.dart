import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app preferences and onboarding state
class PreferencesService {
  static const String _keyOnboardingComplete = 'onboarding_complete';
  static const String _keyRememberMe = 'remember_me';
  static const String _keySavedEmail = 'saved_email';
  static const String _keySavedPassword = 'saved_password';

  /// Check if user has completed onboarding
  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingComplete) ?? false;
  }

  /// Mark onboarding as complete
  static Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingComplete, true);
  }

  /// Reset onboarding (for testing)
  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOnboardingComplete);
  }

  /// Check if Remember Me is enabled
  static Future<bool> isRememberMeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRememberMe) ?? false;
  }

  /// Save login credentials for Remember Me
  static Future<void> saveLoginCredentials({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberMe, rememberMe);

    if (rememberMe) {
      await prefs.setString(_keySavedEmail, email);
      await prefs.setString(_keySavedPassword, password);
    } else {
      // Clear saved credentials if Remember Me is unchecked
      await prefs.remove(_keySavedEmail);
      await prefs.remove(_keySavedPassword);
    }
  }

  /// Get saved email
  static Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySavedEmail);
  }

  /// Get saved password
  static Future<String?> getSavedPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySavedPassword);
  }

  /// Clear saved login credentials
  static Future<void> clearLoginCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRememberMe);
    await prefs.remove(_keySavedEmail);
    await prefs.remove(_keySavedPassword);
  }
}
