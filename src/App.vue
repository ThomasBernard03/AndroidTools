<script setup lang="ts">
import DevicePicker from './features/devices/presentation/DevicePicker.vue';
import type { DeviceService } from './features/devices/domain/devices';
import type { DeviceSummary } from './features/devices/domain/devices';
import { shallowRef } from 'vue';
import AppIcon from './shared/presentation/widgets/AppIcon.vue';
import DeviceWorkspace from './features/devices/presentation/DeviceWorkspace.vue';
import DeviceStatusBar from './features/devices/presentation/DeviceStatusBar.vue';
import type { AdbService } from './features/adb/domain/adb';
import { useAdb } from './features/adb/presentation/useAdb';

const props = defineProps<{
  deviceService: DeviceService;
  adbService?: AdbService;
  demo?: boolean;
}>();
const selectedDevice = shallowRef<DeviceSummary | null>(null);
const { state: adbState, refresh: refreshAdb } = useAdb(
  selectedDevice,
  props.adbService,
);
</script>

<template>
  <div class="flex h-dvh flex-col overflow-hidden">
    <div
      class="min-h-0 flex-1 overflow-y-auto md:grid md:grid-cols-[296px_minmax(0,1fr)]"
    >
      <a
        href="#workspace"
        class="sr-only z-20 rounded-lg bg-primary px-4 py-2 text-on-primary focus:not-sr-only focus:fixed focus:left-4 focus:top-4"
        >Skip to workspace</a
      >
      <aside
        aria-label="Device sidebar"
        class="flex flex-col border-b border-stroke bg-sidebar md:overflow-y-auto md:border-r md:border-b-0"
      >
        <div class="px-4">
          <DevicePicker
            :service="deviceService"
            @selection-change="selectedDevice = $event"
          />
        </div>

        <nav aria-label="Workspace" class="px-4 pt-8 pb-6">
          <p
            class="px-3 text-[11px] font-semibold tracking-[0.16em] text-muted uppercase"
          >
            Workspace
          </p>
          <a
            href="#workspace"
            aria-current="page"
            class="mt-3 flex items-center gap-3 rounded-xl border border-primary/15 bg-primary/8 px-3 py-3 text-sm font-medium text-primary transition-colors hover:bg-primary/12 motion-reduce:transition-none"
          >
            <AppIcon name="overview" class="size-4" />
            Device overview
            <span class="ml-auto size-1.5 rounded-full bg-primary" />
          </a>
        </nav>

        <footer class="mt-auto border-t border-stroke px-6 py-5">
          <p
            v-if="demo"
            role="note"
            class="mb-4 rounded-lg border border-warning/20 bg-warning/5 p-3 text-xs leading-relaxed text-warning"
          >
            Demo mode — simulated devices. No USB connection is used.
          </p>
        </footer>
      </aside>

      <main
        id="workspace"
        tabindex="-1"
        class="workspace-background min-w-0 md:overflow-y-auto"
      >
        <header
          class="flex min-h-20 flex-wrap items-center justify-between gap-3 border-b border-stroke px-6 py-5 lg:px-10"
        >
          <p class="text-sm">
            <span class="text-muted">Workspace</span
            ><span class="mx-3 text-stroke" aria-hidden="true">/</span>Device
            overview
          </p>
          <span
            class="inline-flex items-center gap-2 rounded-full border border-stroke bg-surface px-3 py-1.5 text-xs text-muted"
          >
            <span
              :class="selectedDevice ? 'bg-primary' : 'bg-muted'"
              class="size-1.5 rounded-full"
            />
            {{ selectedDevice ? 'Device selected' : 'No device selected' }}
          </span>
        </header>
        <DeviceWorkspace
          :device="selectedDevice"
          :demo="demo ?? false"
          :adb-state="adbService ? adbState : undefined"
          @refresh-adb="refreshAdb"
        />
      </main>
    </div>
    <DeviceStatusBar
      :device="selectedDevice"
      :demo="demo ?? false"
      :adb-status="adbState.status"
    />
  </div>
</template>
