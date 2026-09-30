import { invoke, isTauri } from '@tauri-apps/api/core'
import type { DeviceError, DeviceInfo, DeviceSummary } from './types'
export { toAppError as toDeviceError } from '../../shared/errors'

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
