import { computed, onScopeDispose, ref, watch, type Ref } from 'vue'
import { toAppError, type AppError } from '../../shared/errors'
import {
  listFiles,
  previewFile,
  downloadEntry,
  uploadEntry,
  createDirectory,
  deleteEntry,
  chooseUpload,
  chooseDownload,
} from './api'
import type { FileEntry, FilePreview } from './types'

export function useFiles(deviceId: Readonly<Ref<string>>) {
  const path = ref('/sdcard')
  const entries = ref<FileEntry[]>([])
  const search = ref('')
  const error = ref<AppError | null>(null)
  const loading = ref(false)
  const selectedEntry = ref<FileEntry | null>(null)
  const preview = ref<FilePreview | null>(null)
  const previewError = ref<AppError | null>(null)
  const loadingPreview = ref(false)

  const matches = computed(() => {
    const query = search.value.trim().toLocaleLowerCase()
    return query
      ? entries.value.filter((entry) => entry.name.toLocaleLowerCase().includes(query))
      : []
  })
  const matchIndex = ref(0)
  const activeMatch = computed(() => matches.value[matchIndex.value]?.name)
  watch(
    matches,
    () => {
      matchIndex.value = 0
    },
    { flush: 'sync' },
  )
  function moveMatch(delta: number) {
    if (matches.value.length)
      matchIndex.value = (matchIndex.value + delta + matches.value.length) % matches.value.length
  }
  const operating = ref(false)
  const operationError = ref<AppError | null>(null)
  const operationMessage = ref('')
  const writable = computed(() => !['/data', '/data/data'].includes(path.value))
  const breadcrumbs = computed(() => {
    const parts = path.value.split('/').filter(Boolean)
    return [
      { name: 'Racine', path: '/' },
      ...parts.map((name, index) => ({ name, path: `/${parts.slice(0, index + 1).join('/')}` })),
    ]
  })
  const privatePackage = computed(() =>
    path.value.startsWith('/data/data/') ? path.value.split('/')[3] : null,
  )

  type Request = { kind: 'list' | 'preview'; deviceId: string; path: string; version: number }
  let pending: Request | null = null
  let running = false
  let disposed = false
  let version = 0
  let locationVersion = 0

  async function operate(
    action: (id: string, directory: string, current: () => boolean) => Promise<boolean>,
    message: string,
    reload = true,
  ) {
    if (disposed || operating.value || loading.value || !deviceId.value) return false
    const id = deviceId.value
    const directory = path.value
    const token = locationVersion
    const current = () => !disposed && token === locationVersion
    operating.value = true
    operationError.value = null
    operationMessage.value = ''
    try {
      const done = await action(id, directory, current)
      if (current() && done) {
        if (reload) refresh()
        operationMessage.value = message
      }
      return done && !disposed && deviceId.value === id
    } catch (reason) {
      if (current()) operationError.value = toAppError(reason)
      return false
    } finally {
      operating.value = false
    }
  }

  const childPath = (directory: string, name: string) =>
    `${directory === '/' ? '' : directory}/${name}`
  function download(entry: FileEntry) {
    return operate(
      async (id, directory, current) => {
        const localPath = await chooseDownload(entry)
        if (!localPath || !current()) return false
        await downloadEntry(id, childPath(directory, entry.name), localPath)
        return true
      },
      'Téléchargement terminé.',
      false,
    )
  }
  function upload(directory: boolean) {
    return operate(async (id, path, current) => {
      const localPath = await chooseUpload(directory)
      if (!localPath || !current()) return false
      await uploadEntry(id, path, localPath)
      return true
    }, 'Envoi terminé.')
  }
  function mkdir(name: string) {
    return operate(async (id, path) => {
      await createDirectory(id, path, name)
      return true
    }, 'Dossier créé.')
  }
  function remove(entry: FileEntry) {
    return operate(async (id, directory) => {
      await deleteEntry(id, childPath(directory, entry.name))
      return true
    }, 'Élément supprimé.')
  }

  async function drain() {
    if (running || disposed) return
    running = true
    try {
      // Keep only the latest intent while a USB read is in flight.
      while (pending && !disposed) {
        const request: Request = pending
        pending = null
        const current = () => !disposed && request.version === version
        try {
          if (request.kind === 'list') {
            const result = await listFiles(request.deviceId, request.path)
            if (current()) {
              path.value = result.path
              entries.value = result.entries
            }
          } else {
            const result = await previewFile(request.deviceId, request.path)
            if (current()) preview.value = result
          }
        } catch (reason) {
          if (current()) {
            if (request.kind === 'list') error.value = toAppError(reason)
            else previewError.value = toAppError(reason)
          }
        } finally {
          if (current()) {
            loading.value = false
            loadingPreview.value = false
          }
        }
      }
    } finally {
      running = false
    }
  }

  function closePreview() {
    version++
    pending = null
    selectedEntry.value = null
    preview.value = null
    previewError.value = null
    loadingPreview.value = false
  }

  function navigate(destination: string) {
    if (disposed) return
    locationVersion++
    operationError.value = null
    operationMessage.value = ''
    closePreview()
    path.value = destination
    entries.value = []
    search.value = ''
    error.value = null
    loading.value = Boolean(deviceId.value)
    if (!deviceId.value) return
    pending = { kind: 'list', deviceId: deviceId.value, path: destination, version }
    void drain()
  }

  function openEntry(entry: FileEntry) {
    if (disposed || loading.value || !deviceId.value) return
    const destination = `${path.value === '/' ? '' : path.value}/${entry.name}`
    if (entry.kind === 'directory') {
      navigate(destination)
    } else if (entry.kind === 'file') {
      closePreview()
      selectedEntry.value = entry
      loadingPreview.value = true
      pending = { kind: 'preview', deviceId: deviceId.value, path: destination, version }
      void drain()
    }
  }

  function parent() {
    navigate(path.value.slice(0, path.value.lastIndexOf('/')) || '/')
  }

  function refresh() {
    if (!loading.value) navigate(path.value)
  }

  watch(deviceId, () => navigate('/sdcard'), { immediate: true, flush: 'sync' })
  onScopeDispose(() => {
    disposed = true
    version++
    pending = null
  })

  return {
    path,
    entries,
    search,
    matches,
    matchIndex,
    activeMatch,
    moveMatch,
    operating,
    operationError,
    operationMessage,
    writable,
    download,
    upload,
    mkdir,
    remove,
    breadcrumbs,
    privatePackage,
    error,
    loading,
    selectedEntry,
    preview,
    previewError,
    loadingPreview,
    navigate,
    parent,
    refresh,
    openEntry,
    closePreview,
  }
}
