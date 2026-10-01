import { invoke, isTauri } from '@tauri-apps/api/core'

export interface LogEntry {
  level: string
  text: string
}

function requireDesktop() {
  if (!isTauri()) {
    throw {
      code: 'desktop_required',
      message: 'Le logcat est disponible dans l’application desktop.',
      details: 'Lancez npm run tauri dev pour accéder aux appareils.',
    }
  }
}

export async function readLogcat(deviceId: string): Promise<LogEntry[]> {
  requireDesktop()
  return invoke('read_logcat', { deviceId })
}

export async function clearLogcat(deviceId: string): Promise<void> {
  requireDesktop()
  return invoke('clear_logcat', { deviceId })
}
