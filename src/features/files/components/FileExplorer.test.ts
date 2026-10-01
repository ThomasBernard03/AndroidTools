import { flushPromises, mount } from '@vue/test-utils'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { listFiles, previewFile, createDirectory, deleteEntry } from '../api'
import FileExplorer from './FileExplorer.vue'

vi.mock('../api', () => ({
  listFiles: vi.fn(),
  previewFile: vi.fn(),
  createDirectory: vi.fn(),
  deleteEntry: vi.fn(),
}))
afterEach(() => vi.resetAllMocks())

describe('file explorer screen', () => {
  it('scrolls through matches while keeping all rows visible', async () => {
    vi.mocked(listFiles).mockResolvedValue({
      path: '/sdcard',
      entries: ['alpha', 'beta', 'alphabet'].map((name) => ({
        name,
        kind: 'file',
        size: 0,
        modifiedAt: null,
        permissions: null,
      })),
    })
    const wrapper = mount(FileExplorer, { props: { deviceId: 'a' } })
    try {
      await flushPromises()
      const rows = wrapper.findAll('tbody tr')
      const scrolls = rows.map((row) => {
        const scroll = vi.fn()
        Object.defineProperty(row.element, 'scrollIntoView', { value: scroll, configurable: true })
        return scroll
      })
      await wrapper.get('input[type="search"]').setValue('alph')
      expect(wrapper.findAll('tbody tr')).toHaveLength(3)
      expect(scrolls[0]).toHaveBeenCalledOnce()
      await wrapper.get('[aria-label="Correspondance suivante"]').trigger('click')
      expect(scrolls[2]).toHaveBeenCalledOnce()
      await wrapper.get('[aria-label="Correspondance précédente"]').trigger('click')
      expect(scrolls[0]).toHaveBeenCalledTimes(2)
      await wrapper.get('input[type="search"]').setValue('absent')
      expect(wrapper.findAll('tbody tr')).toHaveLength(3)
      expect(
        wrapper.get('[aria-label="Correspondance suivante"]').attributes('disabled'),
      ).toBeDefined()
    } finally {
      wrapper.unmount()
    }
  })

  it('creates a folder and deletes an entry through the visible controls', async () => {
    vi.mocked(listFiles).mockResolvedValue({
      path: '/sdcard',
      entries: [
        { name: 'folder', kind: 'directory', size: null, modifiedAt: null, permissions: null },
      ],
    })
    const wrapper = mount(FileExplorer, { props: { deviceId: 'a' } })
    try {
      await flushPromises()
      await wrapper
        .findAll('button')
        .find((button) => button.text() === 'Nouveau dossier')!
        .trigger('click')
      await wrapper.get('[aria-label="Nom du nouveau dossier"]').setValue('new folder')
      await wrapper.get('form').trigger('submit')
      await flushPromises()
      expect(createDirectory).toHaveBeenCalledWith('a', '/sdcard', 'new folder')
      await wrapper.get('[aria-label="Supprimer folder"]').trigger('click')
      expect(deleteEntry).not.toHaveBeenCalled()
      await wrapper
        .findAll('button')
        .find((button) => button.text() === 'Confirmer la suppression')!
        .trigger('click')
      await flushPromises()
      expect(deleteEntry).toHaveBeenCalledWith('a', '/sdcard/folder')
    } finally {
      wrapper.unmount()
    }
  })
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
      expect(wrapper.findAll('tbody tr')).toHaveLength(1)
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
