export interface AppSettings {
  crashReportingEnabled: boolean;
}

export type ProjectLink = 'repository' | 'issue' | 'changelog';

export interface SettingsService {
  load(): Promise<AppSettings>;
  setCrashReporting(enabled: boolean): Promise<AppSettings>;
  openProjectLink(link: ProjectLink): Promise<void>;
  openLogsFolder(): Promise<void>;
  checkForUpdates(): Promise<void>;
}

export class SettingsError extends Error {
  constructor(
    public readonly code: string,
    message: string,
  ) {
    super(message);
    this.name = 'SettingsError';
  }
}
