<script setup lang="ts">
import { computed } from 'vue';
import { adbStatusLabels, type AdbState } from '../domain/adb';

const props = defineProps<{ state: AdbState; demo: boolean }>();
defineEmits<{ refresh: [] }>();
const fields = computed(() => {
  const info = props.state.info;
  if (!info) return [];
  return [
    ['Manufacturer', info.manufacturer],
    ['Model', info.model],
    ['Android version', info.androidVersion],
    ['API level', info.apiLevel],
    ['Security patch', info.securityPatch],
    ['Build', info.buildId],
    ['CPU architecture', info.architecture],
    [
      'Battery',
      info.batteryPercent === null ? null : `${info.batteryPercent}%`,
    ],
    ['Battery status', info.batteryStatus],
  ];
});
</script>

<template>
  <section
    aria-labelledby="android-info-title"
    :aria-busy="state.status === 'connecting'"
    class="mt-6 overflow-hidden rounded-2xl border border-stroke bg-surface"
  >
    <div
      class="flex flex-wrap items-center justify-between gap-4 border-b border-stroke p-6"
    >
      <div>
        <h3 id="android-info-title" class="font-medium">
          {{ demo ? 'Simulated Android information' : 'Android information' }}
        </h3>
        <p role="status" class="mt-1 text-sm text-muted">
          ADB: {{ adbStatusLabels[state.status] }}
        </p>
      </div>
      <button
        type="button"
        :disabled="state.status === 'connecting'"
        class="rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-on-primary hover:bg-primary-hover disabled:cursor-wait disabled:opacity-50"
        @click="$emit('refresh')"
      >
        {{
          state.status === 'connecting'
            ? 'Connecting…'
            : state.status === 'connected'
              ? 'Refresh Android info'
              : 'Retry ADB connection'
        }}
      </button>
    </div>
    <p
      v-if="state.status === 'connecting'"
      class="p-6 text-sm leading-6 text-muted"
    >
      Connecting over USB. Unlock your phone and accept “Allow USB debugging” if
      prompted. Authorization can take up to 30 seconds.
    </p>
    <p
      v-if="state.error"
      role="alert"
      class="p-6 text-sm leading-6 text-warning"
    >
      {{ state.error }}
    </p>
    <dl v-if="state.info" class="grid gap-6 p-6 sm:grid-cols-2">
      <div v-for="[label, value] in fields" :key="label!">
        <dt class="text-xs text-muted">{{ label }}</dt>
        <dd class="mt-2 break-words text-sm">{{ value ?? 'Unavailable' }}</dd>
      </div>
    </dl>
    <p
      v-if="state.info?.warning"
      class="border-t border-stroke px-6 py-4 text-sm text-warning"
    >
      {{ state.info.warning }}
    </p>
    <p class="border-t border-stroke px-6 py-4 text-xs leading-6 text-muted">
      ADB over USB. Information and connection status reflect the last request;
      use Refresh to check for changes.
    </p>
  </section>
</template>
