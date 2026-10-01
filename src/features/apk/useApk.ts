import { onMounted, onScopeDispose, shallowRef, ref } from 'vue'
import { analyzeApk, chooseApk, listenForApkDrop, listRecentApks, removeRecentApk } from './api'
import { toAppError, type AppError } from '../../shared/errors'
import type { ApkReport } from './types'

export function useApk(onOpen: () => void) {
  const report = shallowRef<ApkReport | null>(null)
  const error = ref<AppError | null>(null)
  const dropError = ref<AppError | null>(null)
  const loading = ref(false)
  const choosing = ref(false)
  const dragging = ref(false)
  const fileName = ref('')
  const recentPaths = ref<string[]>([])
  const historyError = ref<AppError | null>(null)
  const removing = ref(false)
  let historyVersion = 0
  let disposed = false
  let version = 0
  let processing = false
  let pendingPath: string | null = null
  let unlisten: (() => void) | undefined

  async function refreshHistory() {
    const current = ++historyVersion
    try {
      const paths = await listRecentApks()
      if (!disposed && current === historyVersion) recentPaths.value = paths
    } catch (cause) {
      if (!disposed && current === historyVersion) historyError.value = toAppError(cause)
    }
  }

  async function removeRecent(path: string) {
    if (disposed || removing.value) return
    removing.value = true
    historyError.value = null
    historyVersion++
    try {
      await removeRecentApk(path)
      if (!disposed) await refreshHistory()
    } catch (cause) {
      if (!disposed) historyError.value = toAppError(cause)
    } finally {
      if (!disposed) removing.value = false
    }
  }

  async function drain() {
    if (processing) return
    processing = true
    try {
      // Coalesce repeated drops and only display the most recently requested APK.
      while (pendingPath !== null && !disposed) {
        const path = pendingPath
        const current = version
        pendingPath = null
        try {
          const result = await analyzeApk(path)
          if (!disposed) {
            if (current === version) report.value = result
            historyError.value = result.historyError ?? null
            void refreshHistory()
          }
        } catch (cause) {
          if (!disposed && current === version) error.value = toAppError(cause)
        } finally {
          if (!disposed && current === version) loading.value = false
        }
      }
    } finally {
      processing = false
    }
  }

  function analyzePaths(paths: string[]) {
    if (disposed) return
    onOpen()
    version++
    pendingPath = null
    report.value = null
    error.value = null
    loading.value = false
    const path = paths[0]
    fileName.value = path?.split(/[/\\]/).pop() ?? ''
    if (paths.length !== 1 || !path || !/\.apk$/i.test(path)) {
      error.value = {
        code: 'selection',
        message: 'Déposez un seul fichier .apk à la fois.',
        details: '',
      }
      return
    }
    pendingPath = path
    loading.value = true
    void drain()
  }

  async function selectFile() {
    if (choosing.value || disposed) return
    choosing.value = true
    const current = version
    try {
      const path = await chooseApk()
      if (!disposed && current === version && path) analyzePaths([path])
    } catch (cause) {
      if (!disposed && current === version) error.value = toAppError(cause)
    } finally {
      if (!disposed) choosing.value = false
    }
  }

  onMounted(() => {
    void refreshHistory()
  })

  onMounted(async () => {
    try {
      const stop = await listenForApkDrop((event) => {
        if (disposed) return
        if (event.type === 'enter') {
          dragging.value = true
          onOpen()
        } else if (event.type === 'leave') {
          dragging.value = false
        } else if (event.type === 'drop') {
          dragging.value = false
          analyzePaths(event.paths)
        }
      })
      if (disposed) stop()
      else unlisten = stop
    } catch (cause) {
      if (!disposed)
        dropError.value = {
          ...toAppError(cause),
          message: 'Le glisser-déposer est indisponible. Utilisez « Choisir un APK ».',
        }
    }
  })

  onScopeDispose(() => {
    disposed = true
    version++
    pendingPath = null
    unlisten?.()
  })
  return {
    report,
    recentPaths,
    historyError,
    removing,
    removeRecent,
    error,
    dropError,
    loading,
    choosing,
    dragging,
    fileName,
    selectFile,
    analyzePaths,
  }
}
