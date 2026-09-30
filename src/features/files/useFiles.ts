import { computed, onScopeDispose, ref, watch, type Ref } from 'vue'
import { toAppError, type AppError } from '../../shared/errors'
import { listFiles, previewFile } from './api'
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

  const filteredEntries = computed(() => {
    const query = search.value.trim().toLocaleLowerCase()
    return entries.value.filter((entry) => entry.name.toLocaleLowerCase().includes(query))
  })
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
    filteredEntries,
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
