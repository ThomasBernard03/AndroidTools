import { defineComponent } from 'vue'
import { flushPromises, mount } from '@vue/test-utils'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { getDeviceInfo, listDevices, stopAdbServer } from './api'
import { useDevices } from './useDevices'
import type { DeviceInfo, DeviceSummary } from './types'

vi.mock('./api', async (importOriginal) => ({
  ...(await importOriginal<typeof import('./api')>()),
  listDevices: vi.fn(),
  getDeviceInfo: vi.fn(),
  stopAdbServer: vi.fn(),
}))

const phone = (id: string): DeviceSummary => ({
  id,
  name: 'Pixel',
  serial: id,
  vendorId: '18d1',
  productId: '4ee7',
  usbLocation: id,
  accessError: null,
})

const info = (deviceId: string): DeviceInfo => ({
  deviceId,
  manufacturer: 'Google',
  model: 'Pixel',
  androidVersion: '16',
  brand: null,
  device: null,
  serial: null,
  apiLevel: null,
  securityPatch: null,
  buildId: null,
  buildFingerprint: null,
  hardware: null,
  soc: null,
  abis: null,
  bootloader: null,
})

function deferred<T>() {
  let resolve!: (value: T) => void
  let reject!: (reason: unknown) => void
  const promise = new Promise<T>((res, rej) => {
    resolve = res
    reject = rej
  })
  return { promise, resolve, reject }
}

let unmount: (() => void) | undefined
function setup() {
  let state!: ReturnType<typeof useDevices>
  const wrapper = mount(
    defineComponent({
      setup() {
        state = useDevices()
        return () => null
      },
    }),
  )
  unmount = () => wrapper.unmount()
  return state
}

beforeEach(() => {
  vi.mocked(stopAdbServer).mockReset().mockResolvedValue(true)
  vi.useFakeTimers()
  vi.mocked(listDevices)
    .mockReset()
    .mockResolvedValue([phone('a'), phone('b'), phone('c')])
  vi.mocked(getDeviceInfo)
    .mockReset()
    .mockImplementation(async (id) => info(id))
})

afterEach(() => {
  unmount?.()
  unmount = undefined
  vi.useRealTimers()
})

describe('device selection', () => {
  it('coalesces refresh clicks and reconnects the latest selection, ignoring old reads', async () => {
    const shutdown = deferred<boolean>()
    const oldRead = deferred<DeviceInfo>()
    vi.mocked(stopAdbServer).mockReturnValueOnce(shutdown.promise)
    vi.mocked(getDeviceInfo).mockReturnValueOnce(oldRead.promise)
    const state = setup()
    await flushPromises()
    state.selectedId.value = 'a'
    const refresh = state.refreshDevices()
    await state.refreshDevices()
    state.selectedId.value = 'b'
    oldRead.resolve(info('a'))
    await flushPromises()
    expect(state.info.value).toBeNull()
    expect(getDeviceInfo).toHaveBeenCalledTimes(1)
    expect(stopAdbServer).toHaveBeenCalledTimes(1)
    expect(listDevices).toHaveBeenCalledTimes(1)
    shutdown.resolve(true)
    await refresh
    await flushPromises()
    expect(state.info.value?.deviceId).toBe('b')
    expect(state.stoppingAdb.value).toBe(false)
  })

  it('handles shutdown failure and allows another attempt', async () => {
    vi.mocked(stopAdbServer).mockRejectedValueOnce(new Error('Timeout'))
    const state = setup()
    await flushPromises()
    await state.refreshDevices()
    expect(state.adbError.value).not.toBeNull()
    expect(state.stoppingAdb.value).toBe(false)
    vi.mocked(stopAdbServer).mockResolvedValueOnce(false)
    await state.refreshDevices()
    expect(state.adbError.value).toBeNull()
    expect(state.adbNotice.value).toBe('')
  })

  it('does not reconnect a disconnected device or act after disposal during shutdown', async () => {
    const state = setup()
    await flushPromises()
    state.selectedId.value = 'a'
    await flushPromises()
    vi.mocked(listDevices).mockResolvedValue([])
    await state.refreshDevices()
    expect(state.selectedId.value).toBe('')
    expect(getDeviceInfo).toHaveBeenCalledTimes(1)
    const shutdown = deferred<boolean>()
    vi.mocked(stopAdbServer).mockReturnValueOnce(shutdown.promise)
    const refresh = state.refreshDevices()
    unmount?.()
    unmount = undefined
    shutdown.resolve(true)
    await refresh
    expect(listDevices).toHaveBeenCalledTimes(2)
    expect(state.adbNotice.value).toBe('')
  })

  it('reads only the selected device, even for identical models', async () => {
    const state = setup()
    await flushPromises()
    expect(state.selectedId.value).toBe('a')
    expect(getDeviceInfo).toHaveBeenCalledExactlyOnceWith('a')
    expect(state.info.value?.deviceId).toBe('a')
    state.selectedId.value = 'b'
    await flushPromises()
    expect(getDeviceInfo).toHaveBeenCalledWith('b')
    expect(state.info.value?.deviceId).toBe('b')
    expect(state.loadingInfo.value).toBe(false)
  })

  it('selects a device detected on refresh when none was selected', async () => {
    vi.mocked(listDevices).mockResolvedValueOnce([])
    const state = setup()
    await flushPromises()
    expect(state.selectedId.value).toBe('')
    expect(getDeviceInfo).not.toHaveBeenCalled()

    await state.refreshDevices()
    await flushPromises()
    expect(state.selectedId.value).toBe('a')
    expect(getDeviceInfo).toHaveBeenCalledExactlyOnceWith('a')
    expect(state.info.value?.deviceId).toBe('a')
  })

  it('coalesces rapid selections and ignores stale results', async () => {
    const first = deferred<DeviceInfo>()
    const last = deferred<DeviceInfo>()
    vi.mocked(getDeviceInfo).mockReturnValueOnce(first.promise).mockReturnValueOnce(last.promise)
    const state = setup()
    await flushPromises()
    state.selectedId.value = 'a'
    state.selectedId.value = 'b'
    state.selectedId.value = 'c'
    expect(getDeviceInfo).toHaveBeenCalledTimes(1)
    first.resolve(info('a'))
    await flushPromises()
    expect(state.info.value).toBeNull()
    expect(getDeviceInfo).toHaveBeenLastCalledWith('c')
    expect(state.loadingInfo.value).toBe(true)
    last.resolve(info('c'))
    await flushPromises()
    expect(state.info.value?.deviceId).toBe('c')
    expect(getDeviceInfo).toHaveBeenCalledTimes(2)
  })

  it('does not show a previous device error after selection changes', async () => {
    const first = deferred<DeviceInfo>()
    vi.mocked(getDeviceInfo).mockReturnValueOnce(first.promise)
    const state = setup()
    await flushPromises()
    state.selectedId.value = 'a'
    state.selectedId.value = 'b'
    first.reject(new Error('Old connection failed'))
    await flushPromises()
    expect(state.infoError.value).toBeNull()
    expect(state.info.value?.deviceId).toBe('b')
  })

  it('clears selection and pending information when unplugged', async () => {
    const pending = deferred<DeviceInfo>()
    vi.mocked(getDeviceInfo).mockReturnValueOnce(pending.promise)
    const state = setup()
    await flushPromises()
    state.selectedId.value = 'a'
    vi.mocked(listDevices).mockResolvedValue([phone('b')])
    await state.refreshDevices()
    expect(state.selectedId.value).toBe('')
    expect(state.notice.value).toContain('déconnecté')
    pending.resolve(info('a'))
    await flushPromises()
    expect(state.info.value).toBeNull()
    expect(state.loadingInfo.value).toBe(false)
  })

  it('allows retry after authorization or USB failure', async () => {
    vi.mocked(getDeviceInfo).mockRejectedValueOnce({
      code: 'timeout',
      message: 'Autorisez le téléphone',
      details: 'Timeout',
    })
    const state = setup()
    await flushPromises()
    state.selectedId.value = 'a'
    await flushPromises()
    expect(state.infoError.value?.code).toBe('timeout')
    await state.refreshDevices()
    await flushPromises()
    expect(state.infoError.value).toBeNull()
    expect(state.info.value?.deviceId).toBe('a')
  })

  it('refreshes only on demand after startup and preserves the selection', async () => {
    const state = setup()
    await flushPromises()
    state.selectedId.value = 'b'
    await flushPromises()
    await vi.advanceTimersByTimeAsync(15000)
    expect(listDevices).toHaveBeenCalledTimes(1)
    expect(stopAdbServer).not.toHaveBeenCalled()
    await state.refreshDevices()
    await flushPromises()
    expect(stopAdbServer).toHaveBeenCalledTimes(1)
    expect(listDevices).toHaveBeenCalledTimes(2)
    expect(state.selectedId.value).toBe('b')
    expect(getDeviceInfo).toHaveBeenCalledTimes(3)
    unmount?.()
    unmount = undefined
    await vi.advanceTimersByTimeAsync(10000)
    expect(listDevices).toHaveBeenCalledTimes(2)
  })

  it('recovers from an enumeration failure without keeping stale information', async () => {
    const state = setup()
    await flushPromises()
    state.selectedId.value = 'a'
    await flushPromises()
    vi.mocked(listDevices).mockRejectedValueOnce(new Error('USB unavailable'))
    await state.refreshDevices()
    expect(state.listError.value).not.toBeNull()
    expect(state.devices.value).toEqual([])
    expect(state.info.value).toBeNull()
    await state.refreshDevices()
    expect(state.listError.value).toBeNull()
    expect(state.devices.value).toHaveLength(3)
  })

  it('ignores late responses after unmount', async () => {
    const pending = deferred<DeviceInfo>()
    vi.mocked(getDeviceInfo).mockReturnValueOnce(pending.promise)
    const state = setup()
    await flushPromises()
    state.selectedId.value = 'a'
    unmount?.()
    unmount = undefined
    pending.resolve(info('a'))
    await flushPromises()
    expect(state.info.value).toBeNull()
  })
})
