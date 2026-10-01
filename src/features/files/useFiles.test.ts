import { effectScope, ref } from 'vue'
import { flushPromises } from '@vue/test-utils'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import {
  listFiles,
  previewFile,
  chooseUpload,
  chooseDownload,
  uploadEntry,
  downloadEntry,
  createDirectory,
  deleteEntry,
} from './api'
import { useFiles } from './useFiles'
import type { FileEntry, FileListing, FilePreview } from './types'

vi.mock('./api', () => ({
  listFiles: vi.fn(),
  previewFile: vi.fn(),
  chooseUpload: vi.fn(),
  chooseDownload: vi.fn(),
  uploadEntry: vi.fn(),
  downloadEntry: vi.fn(),
  createDirectory: vi.fn(),
  deleteEntry: vi.fn(),
}))

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
  vi.resetAllMocks()
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

  it('retries a denied directory and searches without hiding entries or further USB calls', async () => {
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
    expect(state.matches.value).toEqual([file])
    expect(state.entries.value).toEqual([folder, file])
    expect(state.activeMatch.value).toBe(file.name)
    expect(listFiles).toHaveBeenCalledTimes(3)
  })

  it('cycles matches in both directions and resets for a new query', async () => {
    const { state } = setup()
    await flushPromises()
    state.search.value = 's'
    expect(state.activeMatch.value).toBe(folder.name)
    state.moveMatch(-1)
    expect(state.activeMatch.value).toBe(file.name)
    state.moveMatch(1)
    expect(state.activeMatch.value).toBe(folder.name)
    state.search.value = 'missing'
    state.moveMatch(1)
    expect(state.activeMatch.value).toBeUndefined()
    expect(state.entries.value).toHaveLength(2)
  })

  it('transfers entries and refreshes after mutations', async () => {
    const { state } = setup()
    await flushPromises()
    vi.mocked(chooseUpload).mockResolvedValue('/local/folder')
    await state.upload(true)
    await flushPromises()
    expect(uploadEntry).toHaveBeenCalledWith('a', '/sdcard', '/local/folder')
    vi.mocked(chooseDownload).mockResolvedValue('/local/settings.xml')
    await state.download(file)
    expect(downloadEntry).toHaveBeenCalledWith('a', '/sdcard/settings.xml', '/local/settings.xml')
    await state.mkdir('new folder')
    await flushPromises()
    expect(createDirectory).toHaveBeenCalledWith('a', '/sdcard', 'new folder')
    await state.remove(folder)
    await flushPromises()
    expect(deleteEntry).toHaveBeenCalledWith('a', '/sdcard/shared_prefs')
    expect(listFiles).toHaveBeenCalledTimes(4)
  })

  it('cancels dialogs and discards selections after navigation or device changes', async () => {
    const { state, deviceId } = setup()
    await flushPromises()
    vi.mocked(chooseUpload).mockResolvedValue(null)
    await state.upload(false)
    expect(uploadEntry).not.toHaveBeenCalled()
    for (const change of [
      () => state.navigate('/other'),
      () => {
        deviceId.value = 'b'
      },
      () => stop(),
    ]) {
      const dialog = deferred<string | null>()
      vi.mocked(chooseUpload).mockReturnValueOnce(dialog.promise)
      const operation = state.upload(false)
      change()
      dialog.resolve('/local/file')
      await operation
      await flushPromises()
    }
    expect(uploadEntry).not.toHaveBeenCalled()
  })

  it('prevents duplicate mutations and ignores stale failures after disconnection', async () => {
    const { state, deviceId } = setup()
    await flushPromises()
    const pending = deferred<void>()
    vi.mocked(deleteEntry).mockReturnValueOnce(pending.promise)
    const operation = state.remove(file)
    await state.remove(file)
    expect(deleteEntry).toHaveBeenCalledTimes(1)
    deviceId.value = ''
    pending.reject(new Error('disconnected'))
    await operation
    expect(state.operationError.value).toBeNull()
    expect(state.operating.value).toBe(false)
    expect(state.entries.value).toEqual([])
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
