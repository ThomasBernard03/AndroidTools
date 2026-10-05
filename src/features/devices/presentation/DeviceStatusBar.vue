<script setup lang="ts">
import type { DeviceSummary } from '../domain/devices';
import AppIcon from '../../../shared/presentation/widgets/AppIcon.vue';
import { adbStatusLabels, type AdbStatus } from '../../adb/domain/adb';

defineProps<{
  device: DeviceSummary | null;
  demo: boolean;
  adbStatus?: AdbStatus;
}>();
</script>

<template>
  <footer
    aria-label="Device connection status"
    role="status"
    class="flex shrink-0 flex-wrap items-center gap-x-5 gap-y-2 border-t border-stroke bg-sidebar px-4 py-3 text-xs text-muted"
  >
    <div class="flex min-w-0 flex-1 items-center gap-2">
      <AppIcon name="phone" class="size-4 shrink-0" />
      <span class="min-w-0 break-all text-foreground">
        {{ device ? device.name : 'No device selected' }}
        <span v-if="device" class="text-muted">
          — {{ device.serial ?? device.id }}</span
        >
      </span>
    </div>
    <span v-if="demo" class="text-warning">Demo — simulated connection</span>
    <template v-if="device">
      <span class="inline-flex items-center gap-2 text-primary">
        <AppIcon name="usb" class="size-4" />
        {{ demo ? 'USB (simulated)' : 'USB' }}
      </span>
      <span
        :class="
          adbStatus === 'connected'
            ? 'text-primary'
            : adbStatus === 'error' ||
                adbStatus === 'unauthorized' ||
                adbStatus === 'disconnected'
              ? 'text-warning'
              : ''
        "
        >ADB: {{ adbStatusLabels[adbStatus ?? 'idle'] }}</span
      >
    </template>
    <span v-else>Select a device to view its connection</span>
  </footer>
</template>
