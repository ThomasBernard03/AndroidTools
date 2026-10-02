import { mount } from '@vue/test-utils';
import { describe, expect, it } from 'vitest';
import App from './App.vue';

describe('Application bootstrap', () => {
  it('renders the welcome screen without a native runtime or a phone', () => {
    const wrapper = mount(App);

    try {
      expect(wrapper.get('main h1').text()).toBe('Android Tools');
      expect(wrapper.text()).toContain('No phone is required');
    } finally {
      wrapper.unmount();
    }
  });
});
