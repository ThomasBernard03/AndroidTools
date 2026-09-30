import { flushPromises, mount } from '@vue/test-utils'
import { beforeEach, expect, it, vi } from 'vitest'
import ApkView from './ApkView.vue'
import { analyzeApk, chooseApk, listenForApkDrop } from '../api'
import { apkReport } from '../testFixtures'

vi.mock('../api', () => ({ analyzeApk: vi.fn(), chooseApk: vi.fn(), listenForApkDrop: vi.fn() }))

beforeEach(() => {
  vi.mocked(listenForApkDrop).mockResolvedValue(() => {})
  vi.mocked(chooseApk).mockResolvedValue('/tmp/demo.apk')
  vi.mocked(analyzeApk).mockResolvedValue(apkReport())
})

it('shows the signature, safely renders XML, and filters permissions', async () => {
  const wrapper = mount(ApkView)
  try {
    await wrapper.get('button').trigger('click')
    await flushPromises()
    expect(wrapper.text()).toContain('Empreinte SHA-256')
    expect(wrapper.text()).toContain('ne sont pas vérifiées')
    const buttons = wrapper.findAll('nav button')
    await buttons[1]!.trigger('click')
    expect(wrapper.get('pre').text()).toBe(apkReport().manifest)
    expect(wrapper.find('manifest').exists()).toBe(false)
    await buttons[2]!.trigger('click')
    expect(wrapper.text()).toContain('Définie par l’application')
    await wrapper.get('input').setValue('camera')
    expect(wrapper.findAll('tbody tr')).toHaveLength(1)
    expect(wrapper.get('tbody').text()).toContain('android.permission.CAMERA')
  } finally {
    wrapper.unmount()
  }
})

it('shows a partial signature error without hiding the manifest', async () => {
  vi.mocked(analyzeApk).mockResolvedValue({
    ...apkReport(),
    signatures: [],
    signatureWarnings: ['Certificat v1 illisible'],
  })
  const wrapper = mount(ApkView)
  try {
    await wrapper.get('button').trigger('click')
    await flushPromises()
    expect(wrapper.get('[role="alert"]').text()).toContain('Certificat v1 illisible')
    await wrapper.findAll('nav button')[1]!.trigger('click')
    expect(wrapper.get('pre').text()).toContain('com.example.demo')
  } finally {
    wrapper.unmount()
  }
})
