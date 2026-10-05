import { invoke } from '@tauri-apps/api/core';
import {
  SettingsError,
  type AppSettings,
  type SettingsService,
} from '../domain/settings';

type Invoke = (
  command: string,
  args?: Record<string, unknown>,
) => Promise<unknown>;

export function createTauriSettingsService(
  call: Invoke = invoke,
): SettingsService {
  async function request(command: string, args?: Record<string, unknown>) {
    try {
      return await call(command, args);
    } catch (error) {
      if (
        typeof error === 'object' &&
        error !== null &&
        'code' in error &&
        'message' in error &&
        typeof error.code === 'string' &&
        typeof error.message === 'string'
      ) {
        throw new SettingsError(error.code, error.message);
      }
      throw new SettingsError(
        'unavailable',
        'The settings operation failed. Please retry.',
      );
    }
  }
  async function settings(
    command: string,
    args?: Record<string, unknown>,
  ): Promise<AppSettings> {
    const result = await request(command, args);
    if (
      typeof result !== 'object' ||
      result === null ||
      !('crashReportingEnabled' in result) ||
      typeof result.crashReportingEnabled !== 'boolean'
    ) {
      throw new SettingsError(
        'invalid_response',
        'The settings service returned an invalid response.',
      );
    }
    return { crashReportingEnabled: result.crashReportingEnabled };
  }
  return {
    load: () => settings('load_settings'),
    setCrashReporting: (enabled) =>
      settings('set_crash_reporting', { enabled }),
    async openProjectLink(link) {
      await request('open_project_link', { link });
    },
    async openLogsFolder() {
      await request('open_logs_folder');
    },
    async checkForUpdates() {
      await request('check_app_updates');
    },
  };
}
