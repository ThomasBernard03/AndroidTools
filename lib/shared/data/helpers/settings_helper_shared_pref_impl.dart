import 'package:android_tools/shared/domain/helpers/settings_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsHelperSharedPrefImpl implements SettingsHelper {
  static const String _keyThemeMode = 'theme_mode';
  static const String _defaultThemeMode = 'system';

  static const String _keyCrashReportingDisabled = 'crash_reporting_disabled';
  static const bool _defaultCrashReportingDisabled = false;

  @override
  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyThemeMode) ?? _defaultThemeMode;
  }

  @override
  Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode);
  }

  @override
  Future<bool> getCrashReportingDisabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyCrashReportingDisabled) ??
        _defaultCrashReportingDisabled;
  }

  @override
  Future<void> setCrashReportingDisabled(bool disabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCrashReportingDisabled, disabled);
  }
}
