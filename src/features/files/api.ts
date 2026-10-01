import { invoke } from '@tauri-apps/api/core'
import { open, save } from '@tauri-apps/plugin-dialog'
import type { FileEntry, FileListing, FilePreview } from './types'

export async function chooseUpload(directory: boolean): Promise<string | null> {
  const path = await open({
    directory,
    multiple: false,
    title: directory ? 'Envoyer un dossier' : 'Envoyer un fichier',
  })
  return typeof path === 'string' ? path : null
}

export async function chooseDownload(entry: FileEntry): Promise<string | null> {
  if (entry.kind === 'directory') {
    const parent = await open({
      directory: true,
      multiple: false,
      title: 'Choisir le dossier de destination',
    })
    return typeof parent === 'string' ? `${parent}/${entry.name}` : null
  }
  return save({ defaultPath: entry.name, title: 'Télécharger le fichier' })
}

export function downloadEntry(deviceId: string, path: string, localPath: string): Promise<void> {
  return invoke('download_entry', { deviceId, path, localPath })
}
export function uploadEntry(deviceId: string, path: string, localPath: string): Promise<void> {
  return invoke('upload_entry', { deviceId, path, localPath })
}
export function createDirectory(deviceId: string, path: string, name: string): Promise<void> {
  return invoke('create_directory', { deviceId, path, name })
}
export function deleteEntry(deviceId: string, path: string): Promise<void> {
  return invoke('delete_entry', { deviceId, path })
}

export function listFiles(deviceId: string, path: string): Promise<FileListing> {
  return invoke('list_files', { deviceId, path })
}

export function previewFile(deviceId: string, path: string): Promise<FilePreview> {
  return invoke('preview_file', { deviceId, path })
}
