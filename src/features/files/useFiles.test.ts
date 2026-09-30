import { effectScope, ref } from 'vue'
import { flushPromises } from '@vue/test-utils'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { listFiles, previewFile } from './api'
import { useFiles } from './useFiles'
import type { FileEntry, FileListing, FilePreview } from './types'

vi.mock('./api', () => ({ listFiles: vi.fn(), previewFile: vi.fn() }))

const file: FileEntry = {
  name: 'settings.xml',
  kind: 'file',
  size: 10,
  modifiedAt: 0,
  permissions: '0600',
}
const folder: FileEntry = { ...file, name: 'shared_prefs', kind: 'directory' }
const listing = (path: string): FileListing => ({ path, entries: [folder, file] })

function deferred<T>() {
  let resolve!: (value: T) => void
  let reject!: (reason: unknown) => void
  const promise = new Promise<T>((res, rej) => {
    resolve = res
    reject = rej
  })
  return { promise, resolve, reject }
}

let stop: () => void
function setup(id = 'a') {
  const deviceId = ref(id)
  const scope = effectScope()
  const state = scope.run(() => useFiles(deviceId))!
  stop = () => scope.stop()
  return { state, deviceId }
}

beforeEach(() => {
  vi.mocked(listFiles)
    .mockReset()
    .mockImplementation(async (_id, path) => listing(path))
  vi.mocked(previewFile).mockReset().mockResolvedValue({ text: 'hello', truncated: false })
})
afterEach(() => stop?.())

describe('file navigation', () => {
  it('waits for a device and resets navigation on selection', async () => {
    const { state, deviceId } = setup('')
    expect(listFiles).not.toHaveBeenCalled()
    deviceId.value = 'a'
    await flushPromises()
    state.navigate('/data/data/com.example')
    await flushPromises()
    expect(state.privatePackage.value).toBe('com.example')
    state.openEntry(folder)
    await flushPromises()
    expect(listFiles).toHaveBeenLastCalledWith('a', '/data/data/com.example/shared_prefs')
    expect(state.breadcrumbs.value.at(-2)?.path).toBe('/data/data/com.example')
    state.parent()
    await flushPromises()
    expect(state.path.value).toBe('/data/data/com.example')
    deviceId.value = 'b'
    expect(state.entries.value).toEqual([])
    expect(state.path.value).toBe('/sdcard')
    await flushPromises()
    expect(listFiles).toHaveBeenLastCalledWith('b', '/sdcard')
  })

  it('coalesces navigation and ignores old results and errors', async () => {
    const first = deferred<FileListing>()
    vi.mocked(listFiles).mockReturnValueOnce(first.promise)
    const { state } = setup()
    state.navigate('/data')
    state.navigate('/data/data')
    expect(listFiles).toHaveBeenCalledTimes(1)
    first.reject(new Error('Old device failed'))
    await flushPromises()
    expect(listFiles).toHaveBeenCalledTimes(2)
    expect(listFiles).toHaveBeenLastCalledWith('a', '/data/data')
    expect(state.error.value).toBeNull()
    expect(state.path.value).toBe('/data/data')
    expect(state.loading.value).toBe(false)
  })

  it('clears data after disconnection and ignores the in-flight read', async () => {
    const pending = deferred<FileListing>()
    vi.mocked(listFiles).mockReturnValueOnce(pending.promise)
    const { state, deviceId } = setup()
    deviceId.value = ''
    pending.resolve(listing('/old-device'))
    await flushPromises()
    expect(state.entries.value).toEqual([])
    expect(state.path.value).toBe('/sdcard')
    expect(state.loading.value).toBe(false)
    expect(listFiles).toHaveBeenCalledTimes(1)
  })

  it('retries a denied directory and filters without further USB calls', async () => {
    const { state } = setup()
    await flushPromises()
    vi.mocked(listFiles).mockRejectedValueOnce({
      code: 'private_access',
      message: 'Accès refusé',
      details: 'not debuggable',
    })
    state.navigate('/data/data/com.example')
    await flushPromises()
    expect(state.error.value?.code).toBe('private_access')
    expect(state.entries.value).toEqual([])
    state.refresh()
    await flushPromises()
    expect(state.error.value).toBeNull()
    state.search.value = 'XML'
    expect(state.filteredEntries.value).toEqual([file])
    expect(listFiles).toHaveBeenCalledTimes(3)
  })

  it('discards previews when navigating, closing or changing devices', async () => {
    const { state, deviceId } = setup()
    await flushPromises()
    for (const action of [
      () => state.navigate('/data/data'),
      () => state.closePreview(),
      () => {
        deviceId.value = 'b'
      },
    ]) {
      const pending = deferred<FilePreview>()
      vi.mocked(previewFile).mockReturnValueOnce(pending.promise)
      state.openEntry(file)
      expect(state.loadingPreview.value).toBe(true)
      action()
      pending.resolve({ text: 'stale private content', truncated: false })
      await flushPromises()
      expect(state.preview.value).toBeNull()
      expect(state.selectedEntry.value).toBeNull()
      expect(state.loadingPreview.value).toBe(false)
    }
  })

  it('previews private files with their full path and keeps directory on failure', async () => {
    const { state } = setup()
    await flushPromises()
    state.navigate('/data/data/com.example/shared_prefs')
    await flushPromises()
    state.openEntry(file)
    await flushPromises()
    expect(previewFile).toHaveBeenLastCalledWith(
      'a',
      '/data/data/com.example/shared_prefs/settings.xml',
    )
    expect(state.preview.value?.text).toBe('hello')
    vi.mocked(previewFile).mockRejectedValueOnce({
      code: 'binary_file',
      message: 'Texte uniquement',
      details: '',
    })
    state.openEntry(file)
    await flushPromises()
    expect(state.previewError.value?.code).toBe('binary_file')
    expect(state.entries.value).toHaveLength(2)
    expect(state.error.value).toBeNull()
  })

  it('ignores responses and queued operations after disposal', async () => {
    const pending = deferred<FileListing>()
    vi.mocked(listFiles).mockReturnValueOnce(pending.promise)
    const { state } = setup()
    state.navigate('/data/data')
    stop()
    pending.resolve(listing('/old'))
    await flushPromises()
    expect(state.entries.value).toEqual([])
    expect(listFiles).toHaveBeenCalledTimes(1)
  })
})
