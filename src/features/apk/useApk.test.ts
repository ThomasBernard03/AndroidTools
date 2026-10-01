import { defineComponent } from 'vue'
import { flushPromises, mount } from '@vue/test-utils'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { PhysicalPosition } from '@tauri-apps/api/dpi'
import { analyzeApk, chooseApk, listenForApkDrop, listRecentApks, removeRecentApk } from './api'
import { useApk } from './useApk'
import { apkReport, deferred } from './testFixtures'
import type { ApkReport } from './types'

vi.mock('./api', () => ({
  analyzeApk: vi.fn(),
  chooseApk: vi.fn(),
  listenForApkDrop: vi.fn(),
  listRecentApks: vi.fn(),
  removeRecentApk: vi.fn(),
}))

let unmount: (() => void) | undefined
let receiveDrop: Parameters<typeof listenForApkDrop>[0]
const stop = vi.fn()
const openView = vi.fn()
const position = new PhysicalPosition(10, 10)

function setup() {
  let state!: ReturnType<typeof useApk>
  const wrapper = mount(
    defineComponent({
      setup() {
        state = useApk(openView)
        return () => null
      },
    }),
  )
  unmount = () => wrapper.unmount()
  return state
}

beforeEach(() => {
  vi.resetAllMocks()
  vi.mocked(listRecentApks).mockResolvedValue([])
  vi.mocked(removeRecentApk).mockResolvedValue(undefined)
  vi.mocked(analyzeApk).mockResolvedValue(apkReport())
  vi.mocked(chooseApk).mockResolvedValue(null)
  vi.mocked(listenForApkDrop).mockImplementation(async (callback) => {
    receiveDrop = callback
    return stop
  })
})
afterEach(() => {
  unmount?.()
  unmount = undefined
})

describe('APK analysis lifecycle', () => {
  it('ignores an old history load after a successful analysis', async () => {
    const initial = deferred<string[]>()
    vi.mocked(listRecentApks)
      .mockReturnValueOnce(initial.promise)
      .mockResolvedValue(['/tmp/new.apk'])
    const state = setup()
    state.analyzePaths(['/tmp/new.apk'])
    await flushPromises()
    initial.resolve(['/tmp/old.apk'])
    await flushPromises()
    expect(state.recentPaths.value).toEqual(['/tmp/new.apk'])
  })

  it('keeps a successful report when history cannot be saved', async () => {
    vi.mocked(analyzeApk).mockResolvedValue({
      ...apkReport(),
      historyError: { code: 'history', message: 'Historique indisponible', details: '' },
    })
    const state = setup()
    state.analyzePaths(['/tmp/demo.apk'])
    await flushPromises()
    expect(state.report.value?.fileName).toBe('demo.apk')
    expect(state.error.value).toBeNull()
    expect(state.historyError.value?.code).toBe('history')
  })

  it('removes a path and keeps the list on a removal failure', async () => {
    vi.mocked(listRecentApks).mockResolvedValueOnce(['/tmp/missing.apk']).mockResolvedValue([])
    const state = setup()
    await flushPromises()
    vi.mocked(removeRecentApk).mockRejectedValueOnce({
      code: 'history',
      message: 'Lecture seule',
      details: '',
    })
    await state.removeRecent('/tmp/missing.apk')
    expect(state.recentPaths.value).toEqual(['/tmp/missing.apk'])
    expect(state.historyError.value?.code).toBe('history')
    await state.removeRecent('/tmp/missing.apk')
    expect(removeRecentApk).toHaveBeenCalledWith('/tmp/missing.apk')
    expect(state.recentPaths.value).toEqual([])
    expect(state.historyError.value).toBeNull()
  })

  it('ignores history loading after disposal', async () => {
    const initial = deferred<string[]>()
    vi.mocked(listRecentApks).mockReturnValueOnce(initial.promise)
    const state = setup()
    unmount?.()
    unmount = undefined
    initial.resolve(['/tmp/old.apk'])
    await flushPromises()
    expect(state.recentPaths.value).toEqual([])
  })

  it('handles native drag enter, leave and drop including unicode paths', async () => {
    const state = setup()
    await flushPromises()
    receiveDrop({ type: 'enter', paths: ['/tmp/démo app.APK'], position })
    expect(state.dragging.value).toBe(true)
    expect(openView).toHaveBeenCalled()
    receiveDrop({ type: 'leave' })
    expect(state.dragging.value).toBe(false)
    receiveDrop({ type: 'drop', paths: ['/tmp/démo app.APK'], position })
    expect(state.loading.value).toBe(true)
    await flushPromises()
    expect(analyzeApk).toHaveBeenCalledWith('/tmp/démo app.APK')
    expect(state.report.value?.packageName).toBe('com.example.demo')
    expect(state.loading.value).toBe(false)
  })

  it('uses the selected file and preserves the report when the dialog is cancelled', async () => {
    const state = setup()
    vi.mocked(chooseApk).mockResolvedValueOnce('/tmp/demo.apk')
    await state.selectFile()
    await flushPromises()
    expect(state.report.value).not.toBeNull()
    await state.selectFile()
    expect(state.report.value).not.toBeNull()
    expect(analyzeApk).toHaveBeenCalledTimes(1)
  })

  it('rejects multiple files and unsupported extensions without invoking Rust', () => {
    const state = setup()
    for (const paths of [[], ['/tmp/test.zip'], ['/tmp/a.apk', '/tmp/b.apk']]) {
      state.analyzePaths(paths)
      expect(state.error.value?.code).toBe('selection')
    }
    expect(analyzeApk).not.toHaveBeenCalled()
  })

  it('coalesces new drops and ignores an obsolete analysis result', async () => {
    const first = deferred<ApkReport>()
    const last = deferred<ApkReport>()
    vi.mocked(analyzeApk).mockReturnValueOnce(first.promise).mockReturnValueOnce(last.promise)
    const state = setup()
    state.analyzePaths(['/tmp/first.apk'])
    state.analyzePaths(['/tmp/skipped.apk'])
    state.analyzePaths(['/tmp/last.apk'])
    first.resolve(apkReport('first.apk'))
    await flushPromises()
    expect(state.report.value).toBeNull()
    expect(state.loading.value).toBe(true)
    expect(analyzeApk).toHaveBeenLastCalledWith('/tmp/last.apk')
    last.resolve(apkReport('last.apk'))
    await flushPromises()
    expect(state.report.value?.fileName).toBe('last.apk')
    expect(analyzeApk).toHaveBeenCalledTimes(2)
  })

  it('keeps a newer drop when an older file dialog resolves later', async () => {
    const selection = deferred<string | null>()
    vi.mocked(chooseApk).mockReturnValueOnce(selection.promise)
    const state = setup()
    const choosing = state.selectFile()
    state.analyzePaths(['/tmp/new.apk'])
    selection.resolve('/tmp/old.apk')
    await choosing
    await flushPromises()
    expect(analyzeApk).toHaveBeenCalledTimes(1)
    expect(analyzeApk).toHaveBeenCalledWith('/tmp/new.apk')
  })

  it('reports parsing failures and allows another analysis', async () => {
    vi.mocked(analyzeApk).mockRejectedValueOnce({
      code: 'manifest',
      message: 'Manifeste illisible',
      details: 'Invalid AXML',
    })
    const state = setup()
    state.analyzePaths(['/tmp/broken.apk'])
    await flushPromises()
    expect(state.error.value?.code).toBe('manifest')
    expect(state.loading.value).toBe(false)
    state.analyzePaths(['/tmp/valid.apk'])
    await flushPromises()
    expect(state.error.value).toBeNull()
    expect(state.report.value).not.toBeNull()
  })

  it('cleans up a listener registered after disposal', async () => {
    const listener = deferred<() => void>()
    vi.mocked(listenForApkDrop).mockReturnValueOnce(listener.promise)
    setup()
    unmount?.()
    unmount = undefined
    listener.resolve(stop)
    await flushPromises()
    expect(stop).toHaveBeenCalledOnce()
  })

  it('ignores completion after disposal and removes the event listener', async () => {
    const pending = deferred<ApkReport>()
    vi.mocked(analyzeApk).mockReturnValueOnce(pending.promise)
    const state = setup()
    await flushPromises()
    state.analyzePaths(['/tmp/a.apk'])
    unmount?.()
    unmount = undefined
    pending.resolve(apkReport())
    await flushPromises()
    expect(state.report.value).toBeNull()
    expect(stop).toHaveBeenCalledOnce()
  })
})
