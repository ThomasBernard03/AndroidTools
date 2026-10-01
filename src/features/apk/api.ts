import { invoke, isTauri } from '@tauri-apps/api/core'
import { getCurrentWebview, type DragDropEvent } from '@tauri-apps/api/webview'
import { open, save } from '@tauri-apps/plugin-dialog'
import type { AppError } from '../../shared/errors'
import type { ApkReport } from './types'

function requireDesktop() {
  if (!isTauri()) {
    throw {
      code: 'desktop_required',
      message: 'Ouvrez l’application desktop pour utiliser les outils APK.',
      details: 'Lancez npm run tauri dev.',
    } satisfies AppError
  }
}

export interface KeystoreRequest {
  outputPath: string
  alias: string
  password: string
  commonName: string
  organization: string
  country: string
  validityDays: number
}

export interface SignRequest {
  apkPath: string
  keystorePath: string
  outputPath: string
  alias: string
  storePassword: string
  keyPassword: string
}

export async function generateKeystore(request: KeystoreRequest): Promise<string> {
  requireDesktop()
  return invoke('generate_keystore', { request })
}

export async function signApk(request: SignRequest): Promise<string> {
  requireDesktop()
  return invoke('sign_apk', { request })
}

export async function chooseToolFile(
  title: string,
  extensions: string[] = [],
): Promise<string | null> {
  requireDesktop()
  return open({
    title,
    multiple: false,
    directory: false,
    filters: extensions.length ? [{ name: title, extensions }] : undefined,
  })
}

export async function chooseToolOutput(kind: 'keystore' | 'apk'): Promise<string | null> {
  requireDesktop()
  return save({
    title: kind === 'keystore' ? 'Enregistrer le keystore' : 'Enregistrer l’APK signé',
    defaultPath: kind === 'keystore' ? 'release.p12' : 'application-signed.apk',
    filters: [
      {
        name: kind === 'keystore' ? 'Keystore PKCS#12' : 'Application Android',
        extensions: kind === 'keystore' ? ['p12'] : ['apk'],
      },
    ],
  })
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

export async function analyzeApk(
  path: string,
): Promise<ApkReport & { historyError?: AppError | null }> {
  requireDesktop()
  return invoke('analyze_apk', { path })
}

export async function listRecentApks(): Promise<string[]> {
  if (!isTauri()) return []
  return invoke('list_recent_apks')
}

export async function removeRecentApk(path: string): Promise<void> {
  requireDesktop()
  return invoke('remove_recent_apk', { path })
}

export async function listenForApkDrop(
  callback: (event: DragDropEvent) => void,
): Promise<() => void> {
  if (!isTauri()) return () => {}
  return getCurrentWebview().onDragDropEvent((event) => callback(event.payload))
}
