<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref } from 'vue';
import type { WindowControlsService } from '../../infrastructure/windowControls';
import AppIcon from './AppIcon.vue';

const props = defineProps<{ service: WindowControlsService }>();

const maximized = ref(false);
let unlisten: (() => void) | undefined;

async function refreshMaximized() {
  try {
    maximized.value = await props.service.isMaximized();
  } catch {
    maximized.value = false;
  }
}

onMounted(async () => {
  await refreshMaximized();
  try {
    unlisten = await props.service.onResized(refreshMaximized);
  } catch {
    unlisten = undefined;
  }
});

onBeforeUnmount(() => unlisten?.());

async function toggleMaximize() {
  await props.service.toggleMaximize();
  await refreshMaximized();
}
</script>

<template>
  <div class="xp-window-controls" role="group" aria-label="Window">
    <button
      type="button"
      class="xp-window-button"
      aria-label="Minimize"
      title="Minimize"
      @click="() => service.minimize()"
    >
      <AppIcon name="minimize" class="size-4" />
    </button>
    <button
      type="button"
      class="xp-window-button"
      :aria-label="maximized ? 'Restore' : 'Maximize'"
      :title="maximized ? 'Restore' : 'Maximize'"
      @click="toggleMaximize"
    >
      <AppIcon :name="maximized ? 'restore' : 'maximize'" class="size-4" />
    </button>
    <button
      type="button"
      class="xp-window-button xp-window-button-close"
      aria-label="Close"
      title="Close"
      @click="() => service.close()"
    >
      <AppIcon name="close" class="size-4" />
    </button>
  </div>
</template>
