import { effectScope, ref } from 'vue'
import { flushPromises } from '@vue/test-utils'
import { afterEach, beforeEach, expect, it, vi } from 'vitest'
import { clearLogcat, readLogcat, type LogEntry } from './api'
import { useLogcat } from './useLogcat'

vi.mock('./api', () => ({ readLogcat: vi.fn(), clearLogcat: vi.fn() }))
let scope: ReturnType<typeof effectScope>
function setup() {
  const device = ref('a')
  scope = effectScope()
  const state = scope.run(() => useLogcat(device))!
  return { device, state }
}
function deferred<T>() {
  let resolve!: (value: T) => void
  const promise = new Promise<T>((res) => {
    resolve = res
  })
  return { promise, resolve }
}
const log = (text: string, level = 'I'): LogEntry => ({ text, level })

beforeEach(() => {
  vi.useFakeTimers()
  vi.mocked(readLogcat).mockReset().mockResolvedValue([])
  vi.mocked(clearLogcat).mockReset().mockResolvedValue(undefined)
})
afterEach(() => {
  scope?.stop()
  vi.useRealTimers()
})

it('polls without duplicate entries, preserves repeated messages and filters exact levels', async () => {
  vi.mocked(readLogcat).mockResolvedValueOnce([log('first'), log('same', 'E')])
  const { state } = setup()
  await flushPromises()
  vi.mocked(readLogcat).mockResolvedValue([log('same', 'E'), log('same', 'E'), log('new')])
  await vi.advanceTimersByTimeAsync(1000)
  expect(state.entries.value.map((entry) => entry.text)).toEqual(['first', 'same', 'same', 'new'])
  await vi.advanceTimersByTimeAsync(1000)
  expect(state.entries.value).toHaveLength(4)
  state.level.value = 'E'
  expect(state.filtered.value).toHaveLength(2)
})

it('ignores in-flight reads on pause and permits manual refresh while paused', async () => {
  const read = deferred<LogEntry[]>()
  vi.mocked(readLogcat).mockReturnValueOnce(read.promise)
  const { state } = setup()
  state.togglePause()
  read.resolve([log('stale')])
  await flushPromises()
  await vi.advanceTimersByTimeAsync(5000)
  expect(state.entries.value).toEqual([])
  expect(readLogcat).toHaveBeenCalledTimes(1)
  vi.mocked(readLogcat).mockResolvedValue([log('manual')])
  state.refresh()
  await flushPromises()
  expect(state.entries.value[0]?.text).toBe('manual')
  expect(state.paused.value).toBe(true)
  state.togglePause()
  await flushPromises()
  await vi.advanceTimersByTimeAsync(1000)
  expect(readLogcat).toHaveBeenCalledTimes(4)
})

it('coalesces device changes and stops on disconnection and disposal', async () => {
  const read = deferred<LogEntry[]>()
  vi.mocked(readLogcat).mockReturnValueOnce(read.promise)
  const { state, device } = setup()
  device.value = 'b'
  device.value = 'c'
  expect(readLogcat).toHaveBeenCalledTimes(1)
  read.resolve([log('old device')])
  await flushPromises()
  expect(readLogcat).toHaveBeenLastCalledWith('c')
  expect(readLogcat).toHaveBeenCalledTimes(2)
  expect(state.entries.value).toEqual([])
  device.value = ''
  await vi.advanceTimersByTimeAsync(5000)
  expect(readLogcat).toHaveBeenCalledTimes(2)
  device.value = 'a'
  await flushPromises()
  scope.stop()
  await vi.advanceTimersByTimeAsync(5000)
  expect(readLogcat).toHaveBeenCalledTimes(3)
})

it('serializes clear after an old read and never restores the erased snapshot', async () => {
  const read = deferred<LogEntry[]>()
  vi.mocked(readLogcat).mockReturnValueOnce(read.promise)
  const { state } = setup()
  state.clear()
  expect(clearLogcat).not.toHaveBeenCalled()
  read.resolve([log('before clear')])
  await flushPromises()
  expect(clearLogcat).toHaveBeenCalledWith('a')
  expect(state.entries.value).toEqual([])
  expect(state.notice.value).toContain('effacé')
})

it('keeps existing logs on clear failure and stops polling until retry', async () => {
  vi.mocked(readLogcat).mockResolvedValue([log('keep')])
  const { state } = setup()
  await flushPromises()
  vi.mocked(clearLogcat).mockRejectedValue({ code: 'usb', message: 'Déconnecté', details: '' })
  state.clear()
  await flushPromises()
  expect(state.entries.value[0]?.text).toBe('keep')
  expect(state.error.value?.message).toBe('Déconnecté')
  await vi.advanceTimersByTimeAsync(5000)
  expect(readLogcat).toHaveBeenCalledTimes(1)
  state.refresh()
  await flushPromises()
  expect(state.error.value).toBeNull()
})

it('bounds retained history and ignores results after unmount', async () => {
  vi.mocked(readLogcat).mockResolvedValueOnce(
    Array.from({ length: 5000 }, (_, i) => log(String(i))),
  )
  const { state } = setup()
  await flushPromises()
  vi.mocked(readLogcat).mockResolvedValueOnce([log('latest')])
  await vi.advanceTimersByTimeAsync(1000)
  expect(state.entries.value).toHaveLength(5000)
  expect(state.entries.value[0]?.text).toBe('1')
  const read = deferred<LogEntry[]>()
  vi.mocked(readLogcat).mockReturnValueOnce(read.promise)
  state.refresh()
  scope.stop()
  read.resolve([log('disposed')])
  await flushPromises()
  expect(state.entries.value.at(-1)?.text).toBe('latest')
})
