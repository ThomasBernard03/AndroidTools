export interface FileEntry {
  name: string
  kind: 'directory' | 'file' | 'symlink' | 'other'
  size: number | null
  modifiedAt: number | null
  permissions: string | null
}

export interface FileListing {
  path: string
  entries: FileEntry[]
}

export interface FilePreview {
  text: string
  truncated: boolean
}
