import { invoke, isTauri } from '@tauri-apps/api/core'
import type { DeviceError, DeviceInfo, DeviceSummary } from './types'

function requireDesktop() {
  if (!isTauri()) {
    throw {
      code: 'desktop_required',
      message: 'La connexion USB est disponible dans l’application desktop.',
      details: 'Lancez npm run tauri dev pour accéder aux appareils.',
    } satisfies DeviceError
  }
}

export async function listDevices(): Promise<DeviceSummary[]> {
  requireDesktop()
  return invoke('list_devices')
}

export async function getDeviceInfo(deviceId: string): Promise<DeviceInfo> {
  requireDesktop()
  return invoke('get_device_info', { deviceId })
}

export function toDeviceError(error: unknown): DeviceError {
  if (
    typeof error === 'object' &&
    error !== null &&
    'code' in error &&
    typeof error.code === 'string' &&
    'message' in error &&
    typeof error.message === 'string' &&
    'details' in error &&
    typeof error.details === 'string'
  ) {
    return { code: error.code, message: error.message, details: error.details }
  }
  return {
    code: 'unexpected',
    message: 'Une erreur inattendue est survenue. Réessayez.',
    details: error instanceof Error ? error.message : String(error),
  }
}
