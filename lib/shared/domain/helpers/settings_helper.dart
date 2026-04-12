abstract class SettingsHelper {
  Future<String> getThemeMode();
  Future<void> setThemeMode(String mode);

  Future<bool> getCrashReportingDisabled();
  Future<void> setCrashReportingDisabled(bool disabled);
}
