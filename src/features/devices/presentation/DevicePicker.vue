<script setup lang="ts">
import { onMounted, watch } from 'vue';
import type { DeviceService, DeviceSummary } from '../domain/devices';
import { useDevices } from './useDevices';
import AppIcon from '../../../shared/presentation/widgets/AppIcon.vue';

const props = defineProps<{ service: DeviceService }>();
const emit = defineEmits<{
  'selection-change': [device: DeviceSummary | null];
}>();
const { devices, selectedId, selectedDevice, loading, error, refresh, select } =
  useDevices(props.service);
onMounted(refresh);
watch(
  [selectedDevice, loading],
  ([device, pending]) => emit('selection-change', pending ? null : device),
  { immediate: true },
);

function onSelect(event: Event) {
  select((event.target as HTMLSelectElement).value);
}
</script>

<template>
  <section
    aria-labelledby="devices-title"
    :aria-busy="loading"
    class="rounded-xl border border-stroke bg-surface p-4"
  >
    <div class="flex items-center justify-between gap-4">
      <h2 id="devices-title" class="text-xs font-medium text-muted">
        Connected devices
      </h2>
      <button
        type="button"
        :disabled="loading"
        class="inline-flex shrink-0 items-center gap-1.5 rounded-md bg-primary px-2 py-1.5 text-xs font-semibold text-on-primary transition-colors hover:bg-primary-hover disabled:cursor-wait disabled:opacity-50 motion-reduce:transition-none"
        @click="refresh"
      >
        <AppIcon
          name="refresh"
          class="size-3.5"
          :class="{ 'animate-spin motion-reduce:animate-none': loading }"
        />
        {{ loading ? 'Scanning…' : 'Refresh' }}
      </button>
    </div>
    <label for="device-select" class="sr-only">Device</label>
    <div class="relative mt-4">
      <select
        id="device-select"
        :value="selectedId"
        :disabled="loading || devices.length === 0"
        aria-describedby="device-status"
        class="w-full min-w-0 appearance-none truncate rounded-lg border border-stroke bg-sidebar py-3 pr-9 pl-3 text-sm text-foreground transition-colors hover:border-primary/50 disabled:cursor-not-allowed disabled:text-muted motion-reduce:transition-none"
        @change="onSelect"
      >
        <option value="">Choose a device</option>
        <option v-for="device in devices" :key="device.id" :value="device.id">
          {{ device.name }} — {{ device.serial ?? 'Serial unavailable' }} ({{
            device.id
          }}){{ device.warning ? ' — Limited metadata' : '' }}
        </option>
      </select>
      <AppIcon
        name="chevron"
        class="pointer-events-none absolute top-1/2 right-3 size-4 -translate-y-1/2 text-primary"
      />
    </div>

    <p
      id="device-status"
      role="status"
      class="mt-3 text-xs leading-5 text-muted"
    >
      <template v-if="loading">Looking for connected devices…</template>
      <template v-else-if="error"
        >Device discovery failed. Use Refresh to retry.</template
      >
      <template v-else-if="devices.length === 0"
        >No Android devices found. Connect a phone with a data cable and enable
        USB debugging.</template
      >
      <template v-else
        >{{ devices.length }} device{{
          devices.length === 1 ? '' : 's'
        }}
        found.</template
      >
    </p>
    <p
      v-if="error"
      role="alert"
      class="mt-3 rounded-lg border border-danger/20 bg-danger/5 p-3 text-xs leading-5 break-words text-danger"
    >
      {{ error }}
    </p>
    <div
      v-if="selectedDevice && !loading"
      class="mt-4 border-t border-stroke pt-4"
    >
      <h3 class="text-[11px] font-medium text-primary">Selected device</h3>
      <p class="mt-2 text-xs leading-5 break-words">
        {{ selectedDevice.name }} —
        {{ selectedDevice.serial ?? 'Serial unavailable' }}
      </p>
      <p class="mt-1 break-all font-mono text-[10px] text-muted">
        {{ selectedDevice.id }}
      </p>
      <p
        v-if="selectedDevice.warning"
        class="mt-2 text-xs leading-5 text-warning"
      >
        {{ selectedDevice.warning }}
      </p>
      <p class="mt-2 text-xs leading-5 text-muted">
        USB detected. ADB authorization has not been checked yet.
      </p>
    </div>
  </section>
</template>
