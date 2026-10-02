import { invoke } from '@tauri-apps/api/core'

export interface AppSettings {
  crashReportingEnabled: boolean
  sentryDsn: string | null
}

export type UpdateStatus =
  { status: 'native' } | { status: 'available'; version: string } | { status: 'current' }

export const getSettings = () => invoke<AppSettings>('get_settings')
export const setCrashReporting = (enabled: boolean) =>
  invoke<void>('set_crash_reporting', { enabled })
export const openAppLog = () => invoke<void>('open_app_log')
export const openProjectLink = (link: 'repository' | 'issue' | 'releases') =>
  invoke<void>('open_project_link', { link })
export const checkAppUpdates = () => invoke<UpdateStatus>('check_app_updates')
