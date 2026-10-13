import { getCurrentWindow, type Window } from '@tauri-apps/api/window';

export interface WindowControlsService {
  minimize(): Promise<void>;
  toggleMaximize(): Promise<void>;
  close(): Promise<void>;
  isMaximized(): Promise<boolean>;
  onResized(handler: () => void): Promise<() => void>;
}

export function createTauriWindowControls(
  window: Window = getCurrentWindow(),
): WindowControlsService {
  return {
    minimize: () => window.minimize(),
    toggleMaximize: () => window.toggleMaximize(),
    close: () => window.close(),
    isMaximized: () => window.isMaximized(),
    async onResized(handler) {
      return window.onResized(() => handler());
    },
  };
}

/** Stand-in for browsers and demos, where no native window exists. */
export function createStubWindowControls(): WindowControlsService {
  return {
    async minimize() {},
    async toggleMaximize() {},
    async close() {},
    async isMaximized() {
      return false;
    },
    async onResized() {
      return () => {};
    },
  };
}
