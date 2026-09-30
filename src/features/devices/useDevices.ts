import { computed, onMounted, onScopeDispose, ref, watch } from 'vue'
import { getDeviceInfo, listDevices, toDeviceError } from './api'
import type { DeviceError, DeviceInfo, DeviceSummary } from './types'

export function useDevices() {
  const devices = ref<DeviceSummary[]>([])
  const selectedId = ref('')
  const info = ref<DeviceInfo | null>(null)
  const listError = ref<DeviceError | null>(null)
  const infoError = ref<DeviceError | null>(null)
  const notice = ref('')
  const scanning = ref(false)
  const loadingInfo = ref(false)
  const scanned = ref(false)
  const selectedDevice = computed(() =>
    devices.value.find((device) => device.id === selectedId.value),
  )

  let disposed = false
  let requestVersion = 0
  let reading = false
  let pendingRead = false

  async function refreshDevices() {
    if (scanning.value || disposed) return
    scanning.value = true
    try {
      const result = await listDevices()
      if (disposed) return
      devices.value = result
      listError.value = null
      if (selectedId.value && !result.some((device) => device.id === selectedId.value)) {
        selectedId.value = ''
        notice.value = 'L’appareil sélectionné a été déconnecté.'
      }
    } catch (error) {
      if (disposed) return
      listError.value = toDeviceError(error)
      devices.value = []
      selectedId.value = ''
    } finally {
      if (!disposed) {
        scanning.value = false
        scanned.value = true
      }
    }
  }

  async function drainReads() {
    if (reading) return
    reading = true
    try {
      // Coalesce rapid selections; never open competing USB sessions or apply stale results.
      while (pendingRead && !disposed) {
        pendingRead = false
        const id = selectedId.value
        const version = requestVersion
        if (!id) continue
        try {
          const result = await getDeviceInfo(id)
          if (!disposed && version === requestVersion && result.deviceId === id) {
            info.value = result
          }
        } catch (error) {
          if (!disposed && version === requestVersion) infoError.value = toDeviceError(error)
        } finally {
          if (!disposed && version === requestVersion) loadingInfo.value = false
        }
      }
    } finally {
      reading = false
    }
  }

  function refreshInfo() {
    requestVersion++
    info.value = null
    infoError.value = null
    loadingInfo.value = Boolean(selectedId.value)
    pendingRead = Boolean(selectedId.value)
    void drainReads()
  }

  watch(
    selectedId,
    () => {
      notice.value = ''
      refreshInfo()
    },
    { flush: 'sync' },
  )

  onMounted(() => void refreshDevices())
  onScopeDispose(() => {
    disposed = true
    requestVersion++
  })

  return {
    devices,
    selectedId,
    selectedDevice,
    info,
    listError,
    infoError,
    notice,
    scanning,
    loadingInfo,
    scanned,
    refreshDevices,
    refreshInfo,
  }
}
