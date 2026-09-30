import { invoke } from '@tauri-apps/api/core'
import type { FileListing, FilePreview } from './types'

export function listFiles(deviceId: string, path: string): Promise<FileListing> {
  return invoke('list_files', { deviceId, path })
}

export function previewFile(deviceId: string, path: string): Promise<FilePreview> {
  return invoke('preview_file', { deviceId, path })
}
