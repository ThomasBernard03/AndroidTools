export interface AndroidInfo {
  manufacturer: string | null;
  model: string | null;
  androidVersion: string | null;
  apiLevel: string | null;
  securityPatch: string | null;
  buildId: string | null;
  architecture: string | null;
  batteryPercent: number | null;
  batteryStatus: string | null;
  warning: string | null;
}

/** The adapter owns native communication; components never invoke Tauri directly. */
export interface AdbService {
  read(connectionId: string): Promise<AndroidInfo>;
  disconnect(): Promise<void>;
}

export class AdbError extends Error {
  constructor(
    public readonly code: string,
    message: string,
  ) {
    super(message);
    this.name = 'AdbError';
  }
}

export type AdbStatus =
  | 'idle'
  | 'connecting'
  | 'connected'
  | 'unauthorized'
  | 'disconnected'
  | 'error';

export interface AdbState {
  status: AdbStatus;
  info: AndroidInfo | null;
  error: string | null;
}

export const adbStatusLabels: Record<AdbStatus, string> = {
  idle: 'Not checked',
  connecting: 'Connecting…',
  connected: 'Connected',
  unauthorized: 'Authorization required',
  disconnected: 'Disconnected',
  error: 'Unavailable',
};
