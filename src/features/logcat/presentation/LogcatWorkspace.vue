<script setup lang="ts">
import { computed, ref } from 'vue';
import { logLevels, type LogcatService } from '../domain/logcat';
import { useLogcat } from './useLogcat';
import SelectField from '../../../shared/presentation/widgets/SelectField.vue';
import LogcatViewport from './LogcatViewport.vue';

const props = defineProps<{
  deviceId: string | null;
  adbConnected: boolean;
  service?: LogcatService | undefined;
  demo?: boolean | undefined;
}>();
const {
  page,
  total,
  counts,
  grouped,
  offset,
  windowRows,
  follow,
  query,
  match,
  searchState,
  moveMatch,
  packages,
  packageName,
  minimum,
  status,
  error,
  packageError,
  refresh,
  refreshPackages,
} = useLogcat(props);
const ready = computed(() =>
  Boolean(props.deviceId && props.adbConnected && props.service),
);
const softWrap = ref(false);
const logViewport = ref<InstanceType<typeof LogcatViewport>>();
const packageOptions = computed(() => [
  { value: '', label: 'All packages' },
  ...packages.value.map((name) => ({ value: name, label: name })),
]);
async function reload() {
  void refreshPackages();
  await refresh();
}
</script>

<template>
  <section
    class="flex min-h-0 flex-col gap-4 p-5"
    aria-labelledby="logcat-title"
  >
    <header class="flex flex-wrap items-center justify-between gap-3">
      <div>
        <h2 id="logcat-title" class="text-xl font-semibold">Logcat</h2>
        <p class="text-sm text-muted">
          Live Android logs<span v-if="demo"> — simulated data</span>
        </p>
      </div>
      <div class="flex gap-2">
        <button
          class="logcat-button"
          :disabled="!ready || status === 'starting'"
          @click="reload"
        >
          Refresh
        </button>
        <button
          class="logcat-button"
          :disabled="!ready || status === 'starting'"
          title="Clear the device's default Logcat buffers for all packages"
          @click="refresh(true)"
        >
          Clear device logs
        </button>
      </div>
    </header>
    <p v-if="!deviceId" class="text-sm text-muted">
      Select a connected Android device to view Logcat.
    </p>
    <p v-else-if="!adbConnected" class="text-sm text-muted">
      Connect ADB from Device overview and allow USB debugging on the phone.
    </p>
    <p v-else-if="!service" class="text-sm text-muted">
      Logcat requires the desktop application.
    </p>
    <form class="flex flex-wrap items-end gap-3" @submit.prevent="refresh()">
      <div class="w-40">
        <SelectField
          id="logcat-level"
          v-model="minimum"
          label="Minimum level"
          :options="logLevels"
        />
      </div>
      <div class="min-w-48 flex-1">
        <SelectField
          id="logcat-package"
          v-model="packageName"
          label="Package name"
          :options="packageOptions"
          :disabled="!ready"
          searchable
        />
      </div>
      <button
        type="submit"
        class="logcat-button"
        :disabled="!ready || status === 'starting'"
      >
        Apply package
      </button>
    </form>
    <p v-if="packageError" role="alert" class="text-sm text-warning">
      Package list: {{ packageError }}
    </p>
    <p v-if="error" role="alert" class="text-sm text-danger">{{ error }}</p>
    <div class="flex flex-wrap items-center gap-2">
      <label for="logcat-search" class="text-sm">Search logs</label>
      <input
        id="logcat-search"
        v-model="query"
        type="search"
        class="min-w-36 flex-1 rounded border border-stroke bg-surface px-3 py-2 text-sm"
        placeholder="Find text…"
        @keydown.enter.prevent="moveMatch($event.shiftKey ? -1 : 1)"
      />
      <button
        class="logcat-button"
        :disabled="!query || !total"
        aria-label="Previous match"
        @click="moveMatch(-1)"
      >
        Previous
      </button>
      <button
        class="logcat-button"
        :disabled="!query || !total"
        aria-label="Next match"
        @click="moveMatch(1)"
      >
        Next
      </button>
      <span class="text-xs text-muted" role="status">{{
        searchState === 'searching'
          ? 'Searching history…'
          : searchState === 'missing'
            ? 'No matching lines'
            : match !== null
              ? `Match at line ${match + 1} of ${total}`
              : `${total} lines`
      }}</span>
      <label class="flex items-center gap-2 text-sm"
        ><input v-model="follow" type="checkbox" /> Follow live</label
      >
      <label
        class="flex items-center gap-2 text-sm"
        title="Group consecutive identical messages, ignoring their timestamps"
        ><input v-model="grouped" type="checkbox" /> Group repeats</label
      >
      <label class="flex items-center gap-2 text-sm"
        ><input v-model="softWrap" type="checkbox" /> Soft wrap</label
      >
    </div>
    <LogcatViewport
      ref="logViewport"
      v-model:offset="offset"
      :page="page"
      :total="total"
      :query="query"
      :match="match"
      :status="status"
      :soft-wrap="softWrap"
      :follow="follow"
      @rows="windowRows = $event"
      @browse="follow = false"
    />
    <div class="flex items-center gap-2 text-xs text-muted">
      <button
        class="logcat-button"
        :disabled="!total"
        @click="logViewport?.firstLine()"
      >
        First line
      </button>
      <button class="logcat-button" :disabled="!total" @click="follow = true">
        Latest
      </button>
      <span v-if="softWrap"
        >Line {{ total ? offset + 1 : 0 }} of {{ total }}</span
      >
      <span v-else
        >Viewing lines {{ total ? offset + 1 : 0 }}–{{
          Math.min(total, offset + windowRows)
        }}
        of {{ total }}</span
      >
    </div>
    <p class="text-xs text-muted">
      {{
        status === 'streaming'
          ? 'Streaming'
          : status === 'starting'
            ? 'Connecting…'
            : status === 'error'
              ? 'Stopped after an error — refresh to retry'
              : 'Not streaming'
      }}
      · {{ counts[0] }} lines captured · Full session history stored on disk.
      Clear removes device logs for all packages.
    </p>
  </section>
</template>

<style scoped>
@reference "../../../styles.css";
.logcat-button {
  @apply rounded border border-stroke bg-surface px-3 py-2 text-sm disabled:opacity-50;
}
</style>
