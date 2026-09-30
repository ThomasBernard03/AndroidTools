import { flushPromises, mount } from '@vue/test-utils'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { listFiles, previewFile } from '../api'
import FileExplorer from './FileExplorer.vue'

vi.mock('../api', () => ({ listFiles: vi.fn(), previewFile: vi.fn() }))
afterEach(() => vi.resetAllMocks())

describe('file explorer screen', () => {
  it('asks for a device without reading USB', () => {
    const wrapper = mount(FileExplorer, { props: { deviceId: '' } })
    try {
      expect(wrapper.text()).toContain('Sélectionnez un appareil')
      expect(listFiles).not.toHaveBeenCalled()
    } finally {
      wrapper.unmount()
    }
  })

  it('opens private packages, searches and previews a file using accessible controls', async () => {
    vi.mocked(listFiles).mockImplementation(async (_id, path) => ({
      path,
      entries:
        path === '/data/data'
          ? [
              {
                name: 'com.example',
                kind: 'directory',
                size: null,
                modifiedAt: null,
                permissions: null,
              },
            ]
          : [
              {
                name: 'prefs.xml',
                kind: 'file',
                size: 12,
                modifiedAt: 1700000000,
                permissions: '0600',
              },
            ],
    }))
    vi.mocked(previewFile).mockResolvedValue({ text: '<map>hello</map>', truncated: false })
    const wrapper = mount(FileExplorer, { props: { deviceId: 'a' } })
    const click = async (text: string) => {
      const button = wrapper.findAll('button').find((button) => button.text().includes(text))
      expect(button).toBeDefined()
      await button!.trigger('click')
      await flushPromises()
    }
    try {
      await flushPromises()
      await click('Données des applications')
      expect(wrapper.text()).toContain('Seules les applications debuggables')
      await click('com.example')
      expect(listFiles).toHaveBeenLastCalledWith('a', '/data/data/com.example')
      await wrapper.get('input[type="search"]').setValue('missing')
      expect(wrapper.text()).toContain('Aucun élément')
      await wrapper.get('input[type="search"]').setValue('prefs')
      await click('prefs.xml')
      expect(previewFile).toHaveBeenLastCalledWith('a', '/data/data/com.example/prefs.xml')
      expect(wrapper.get('pre').text()).toBe('<map>hello</map>')
      await wrapper.get('[aria-label="Fermer l’aperçu"]').trigger('click')
      expect(wrapper.find('pre').exists()).toBe(false)
      await wrapper.get('[aria-label="Dossier parent"]').trigger('click')
      await flushPromises()
      expect(listFiles).toHaveBeenLastCalledWith('a', '/data/data')
    } finally {
      wrapper.unmount()
    }
  })
})
