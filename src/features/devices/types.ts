import type { AppError } from '../../shared/errors'
export type DeviceError = AppError

export interface DeviceSummary {
  id: string
  name: string
  serial: string | null
  vendorId: string
  productId: string
  usbLocation: string
  accessError: DeviceError | null
}

export interface DeviceInfo {
  deviceId: string
  manufacturer: string | null
  brand: string | null
  model: string | null
  device: string | null
  serial: string | null
  androidVersion: string | null
  apiLevel: string | null
  securityPatch: string | null
  buildId: string | null
  buildFingerprint: string | null
  hardware: string | null
  soc: string | null
  abis: string | null
  bootloader: string | null
}
