import { computed, onScopeDispose, ref } from 'vue';
import {
  DeviceDiscoveryError,
  type DeviceService,
  type DeviceSummary,
} from '../domain/devices';

/** Owns refresh and selection state; only the latest request may update the screen. */
export function useDevices(service: DeviceService) {
  const devices = ref<DeviceSummary[]>([]);
  const selectedId = ref('');
  const loading = ref(false);
  const error = ref<string | null>(null);
  const selectedDevice = computed(
    () =>
      devices.value.find((device) => device.id === selectedId.value) ?? null,
  );
  let revision = 0;
  onScopeDispose(() => {
    revision++;
  });

  async function refresh() {
    const request = ++revision;
    loading.value = true;
    error.value = null;
    try {
      const result = await service.list();
      if (request !== revision) return;
      devices.value = result;
      if (!result.some((device) => device.id === selectedId.value))
        selectedId.value = result[0]?.id ?? '';
    } catch (cause) {
      if (request !== revision) return;
      devices.value = [];
      selectedId.value = '';
      error.value =
        cause instanceof DeviceDiscoveryError
          ? cause.message
          : 'Unable to load devices. Please retry.';
    } finally {
      if (request === revision) loading.value = false;
    }
  }

  function select(id: string) {
    selectedId.value = devices.value.some((device) => device.id === id)
      ? id
      : '';
  }

  return {
    devices,
    selectedId,
    selectedDevice,
    loading,
    error,
    refresh,
    select,
  };
}
