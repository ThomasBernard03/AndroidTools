import { onScopeDispose, ref } from 'vue'
import { toAppError, type AppError } from '../../shared/errors'

export function useApkOperation() {
  const busy = ref(false)
  const error = ref<AppError | null>(null)
  const result = ref('')
  let disposed = false
  onScopeDispose(() => {
    disposed = true
  })

  async function run(operation: () => Promise<string | null>, cleanup: () => void = () => {}) {
    if (busy.value || disposed) return
    busy.value = true
    error.value = null
    result.value = ''
    try {
      const value = await operation()
      if (!disposed && value) result.value = value
    } catch (cause) {
      if (!disposed) error.value = toAppError(cause)
    } finally {
      cleanup()
      if (!disposed) busy.value = false
    }
  }

  return { busy, error, result, run }
}
