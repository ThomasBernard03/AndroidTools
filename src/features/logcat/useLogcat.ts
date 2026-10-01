import { computed, onScopeDispose, ref, watch, type Ref } from 'vue'
import { toAppError, type AppError } from '../../shared/errors'
import { clearLogcat, readLogcat, type LogEntry } from './api'

export function useLogcat(deviceId: Readonly<Ref<string>>) {
  const entries = ref<(LogEntry & { id: number })[]>([])
  const level = ref('all')
  const paused = ref(false)
  const loading = ref(false)
  const clearing = ref(false)
  const error = ref<AppError | null>(null)
  const notice = ref('')
  const filtered = computed(() =>
    entries.value.filter((entry) => level.value === 'all' || entry.level === level.value),
  )
  let previous = new Map<string, number>()
  let sequence = 0
  let version = 0
  let disposed = false
  let running = false
  let pending: 'read' | 'clear' | null = null
  let timer: ReturnType<typeof setTimeout> | undefined

  function cancelTimer() {
    clearTimeout(timer)
    timer = undefined
  }

  function append(snapshot: LogEntry[]) {
    const counts = new Map<string, number>()
    const added: (LogEntry & { id: number })[] = []
    for (const entry of snapshot) {
      const count = (counts.get(entry.text) ?? 0) + 1
      counts.set(entry.text, count)
      if (count > (previous.get(entry.text) ?? 0)) added.push({ ...entry, id: ++sequence })
    }
    previous = counts
    if (added.length) entries.value = [...entries.value, ...added].slice(-5000)
  }

  async function drain() {
    if (running || disposed) return
    running = true
    try {
      while (pending && !disposed) {
        const operation = pending
        pending = null
        const id = deviceId.value
        const token = version
        const current = () => !disposed && token === version
        if (!id) continue
        loading.value = true
        error.value = null
        try {
          if (operation === 'clear') {
            await clearLogcat(id)
            if (current()) {
              entries.value = []
              previous.clear()
              notice.value = 'Le journal Android a été effacé.'
              if (!paused.value) pending = 'read'
            }
          } else {
            const result = await readLogcat(id)
            if (current()) append(result)
          }
        } catch (reason) {
          if (current()) error.value = toAppError(reason)
        } finally {
          if (current()) {
            loading.value = false
            clearing.value = false
          }
        }
      }
    } finally {
      running = false
      if (!disposed && deviceId.value && !paused.value && !error.value) {
        timer = setTimeout(() => request('read'), 1000)
      }
    }
  }

  function request(operation: 'read' | 'clear') {
    if (disposed || !deviceId.value || clearing.value) return
    cancelTimer()
    version++
    pending = operation
    clearing.value = operation === 'clear'
    notice.value = ''
    void drain()
  }

  function togglePause() {
    if (clearing.value) return
    paused.value = !paused.value
    cancelTimer()
    version++
    pending = null
    loading.value = false
    if (!paused.value) request('read')
  }

  watch(
    deviceId,
    () => {
      cancelTimer()
      version++
      pending = null
      entries.value = []
      previous.clear()
      error.value = null
      notice.value = ''
      loading.value = false
      clearing.value = false
      paused.value = false
      if (deviceId.value) request('read')
    },
    { immediate: true, flush: 'sync' },
  )

  onScopeDispose(() => {
    disposed = true
    version++
    pending = null
    cancelTimer()
  })

  return {
    entries,
    filtered,
    level,
    paused,
    loading,
    clearing,
    error,
    notice,
    togglePause,
    refresh: () => request('read'),
    clear: () => request('clear'),
  }
}
