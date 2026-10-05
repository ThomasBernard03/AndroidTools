/** USB presence does not imply ADB authorization. IDs identify current connections. */
export interface DeviceSummary {
  id: string;
  name: string;
  serial: string | null;
  /** USB descriptor metadata; these are not Android system properties. */
  manufacturer: string | null;
  product: string | null;
  vendorId: number;
  productId: number;
  warning: string | null;
}

/** Injectable boundary: UI code never needs to know about Tauri or USB. */
export interface DeviceService {
  list(): Promise<DeviceSummary[]>;
}

export class DeviceDiscoveryError extends Error {
  constructor(
    public readonly code: string,
    message: string,
  ) {
    super(message);
    this.name = 'DeviceDiscoveryError';
  }
}
