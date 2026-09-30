import { invoke, isTauri } from '@tauri-apps/api/core'
import { getCurrentWebview, type DragDropEvent } from '@tauri-apps/api/webview'
import { open } from '@tauri-apps/plugin-dialog'
import type { AppError } from '../../shared/errors'
import type { ApkReport } from './types'

function requireDesktop() {
  if (!isTauri()) {
    throw {
      code: 'desktop_required',
      message: 'Ouvrez l’application desktop pour analyser un APK.',
      details: 'Lancez npm run tauri dev.',
    } satisfies AppError
  }
}

export async function chooseApk(): Promise<string | null> {
  requireDesktop()
  return open({
    multiple: false,
    directory: false,
    title: 'Analyser un APK',
    filters: [{ name: 'Application Android', extensions: ['apk'] }],
  })
}

export async function analyzeApk(path: string): Promise<ApkReport> {
  requireDesktop()
  return invoke('analyze_apk', { path })
}

export async function listenForApkDrop(
  callback: (event: DragDropEvent) => void,
): Promise<() => void> {
  if (!isTauri()) return () => {}
  return getCurrentWebview().onDragDropEvent((event) => callback(event.payload))
}
