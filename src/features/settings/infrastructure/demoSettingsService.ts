import { SettingsError, type SettingsService } from '../domain/settings';

export function createDemoSettingsService(fail = false): SettingsService {
  let crashReportingEnabled = false;
  function check() {
    if (fail)
      throw new SettingsError('demo_failure', 'Simulated settings failure.');
  }
  return {
    async load() {
      check();
      return { crashReportingEnabled };
    },
    async setCrashReporting(enabled) {
      check();
      crashReportingEnabled = enabled;
      return { crashReportingEnabled };
    },
    async openProjectLink() {
      check();
    },
    async openLogsFolder() {
      check();
    },
  };
}
