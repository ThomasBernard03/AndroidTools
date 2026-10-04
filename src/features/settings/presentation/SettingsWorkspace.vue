<script setup lang="ts">
import { onMounted, ref } from 'vue';
import { version as appVersion } from '../../../../src-tauri/tauri.conf.json';
import {
  SettingsError,
  type AppSettings,
  type ProjectLink,
  type SettingsService,
} from '../domain/settings';

const props = defineProps<{
  service?: SettingsService | undefined;
  demo?: boolean | undefined;
}>();
const settings = ref<AppSettings | null>(null);
const loading = ref(false);
const saving = ref(false);
const opening = ref(false);
const error = ref('');
const notice = ref('');

function showError(value: unknown) {
  error.value =
    value instanceof SettingsError
      ? value.message
      : 'The settings operation failed. Please retry.';
}
async function load() {
  if (!props.service) return;
  loading.value = true;
  error.value = '';
  try {
    settings.value = await props.service.load();
  } catch (value) {
    showError(value);
  } finally {
    loading.value = false;
  }
}
async function toggle() {
  if (!props.service || !settings.value || saving.value) return;
  saving.value = true;
  error.value = '';
  notice.value = '';
  try {
    settings.value = await props.service.setCrashReporting(
      !settings.value.crashReportingEnabled,
    );
    notice.value = 'Crash reporting preference saved.';
  } catch (value) {
    showError(value);
  } finally {
    saving.value = false;
  }
}
async function open(link: ProjectLink) {
  if (!props.service || opening.value) return;
  opening.value = true;
  error.value = '';
  notice.value = '';
  try {
    await props.service.openProjectLink(link);
    notice.value = props.demo
      ? 'Demo: opening GitHub was simulated.'
      : 'Opened GitHub in your browser.';
  } catch (value) {
    showError(value);
  } finally {
    opening.value = false;
  }
}
async function openLogs() {
  if (!props.service || opening.value) return;
  opening.value = true;
  error.value = '';
  notice.value = '';
  try {
    await props.service.openLogsFolder();
    notice.value = props.demo
      ? 'Demo: opening the logs folder was simulated.'
      : 'Opened the logs folder.';
  } catch (value) {
    showError(value);
  } finally {
    opening.value = false;
  }
}
onMounted(load);
</script>

<template>
  <section class="mx-auto max-w-4xl space-y-6 px-6 py-8 lg:px-10">
    <div>
      <h2 class="text-2xl font-semibold tracking-tight">Settings</h2>
      <p class="mt-2 text-sm text-muted">
        Application preferences, support and updates.
      </p>
    </div>
    <p v-if="demo" class="text-sm text-warning">
      Demo settings are kept in memory. Folder and GitHub actions are simulated.
    </p>
    <p v-if="!service" role="alert" class="text-sm text-warning">
      Settings require the desktop application.
    </p>
    <div
      v-if="error"
      role="alert"
      class="rounded-lg border border-danger/30 bg-danger/5 p-4 text-sm text-danger"
    >
      {{ error }}
      <button
        v-if="!settings && !loading"
        type="button"
        class="ml-3 underline"
        @click="load"
      >
        Retry loading settings
      </button>
    </div>
    <p v-if="notice" role="status" class="text-sm text-primary">{{ notice }}</p>
    <section
      aria-labelledby="privacy-title"
      class="rounded-xl border border-stroke bg-surface"
    >
      <h3
        id="privacy-title"
        class="border-b border-stroke px-5 py-4 text-sm font-semibold"
      >
        Privacy
      </h3>
      <div class="flex items-center justify-between gap-6 p-5">
        <div>
          <p id="crash-label" class="text-sm font-medium">
            Sentry crash reporting
          </p>
          <p
            id="crash-description"
            class="mt-1 text-sm leading-relaxed text-muted"
          >
            Allow error reports to help improve Android Tools when Sentry is
            configured for this build. Changes apply immediately. Screenshots
            and session recordings are not collected.
          </p>
        </div>
        <button
          type="button"
          role="switch"
          aria-labelledby="crash-label"
          aria-describedby="crash-description"
          :aria-checked="settings?.crashReportingEnabled ?? false"
          :disabled="!settings || saving || loading"
          class="relative inline-flex h-6 w-11 shrink-0 items-center rounded-full border border-stroke transition-colors disabled:opacity-40 motion-reduce:transition-none"
          :class="settings?.crashReportingEnabled ? 'bg-primary' : 'bg-canvas'"
          @click="toggle"
        >
          <span
            class="size-4 rounded-full bg-foreground transition-transform motion-reduce:transition-none"
            :class="
              settings?.crashReportingEnabled
                ? 'translate-x-5'
                : 'translate-x-1'
            "
          />
        </button>
      </div>
      <p
        v-if="loading || saving"
        role="status"
        class="px-5 pb-4 text-xs text-muted"
      >
        {{ loading ? 'Loading settings…' : 'Saving preference…' }}
      </p>
    </section>
    <section
      aria-labelledby="support-title"
      class="rounded-xl border border-stroke bg-surface"
    >
      <h3
        id="support-title"
        class="border-b border-stroke px-5 py-4 text-sm font-semibold"
      >
        Support &amp; open source
      </h3>
      <div class="divide-y divide-stroke">
        <div class="flex flex-wrap items-center justify-between gap-4 p-5">
          <div>
            <p class="text-sm font-medium">Application logs</p>
            <p class="mt-1 text-sm text-muted">
              Local diagnostic logs rotate at 5 MiB, keeping up to 5 archives.
            </p>
          </div>
          <button
            type="button"
            :disabled="!service || opening"
            class="rounded-lg border border-stroke px-3 py-2 text-xs hover:border-primary disabled:opacity-40"
            @click="openLogs"
          >
            Open logs folder
          </button>
        </div>
        <div class="flex flex-wrap items-center justify-between gap-4 p-5">
          <div>
            <p class="text-sm font-medium">Report a problem</p>
            <p class="mt-1 text-sm text-muted">
              Share a bug or feature request on GitHub.
            </p>
          </div>
          <button
            type="button"
            :disabled="!service || opening"
            class="rounded-lg border border-stroke px-3 py-2 text-xs hover:border-primary disabled:opacity-40"
            @click="open('issue')"
          >
            Create GitHub issue
          </button>
        </div>
        <div class="flex flex-wrap items-center justify-between gap-4 p-5">
          <div>
            <p class="text-sm font-medium">Open source project</p>
            <p class="mt-1 text-sm text-muted">
              Explore the source code and contribute to Android Tools.
            </p>
          </div>
          <button
            type="button"
            :disabled="!service || opening"
            class="rounded-lg border border-stroke px-3 py-2 text-xs hover:border-primary disabled:opacity-40"
            @click="open('repository')"
          >
            View on GitHub
          </button>
        </div>
      </div>
    </section>
    <section
      aria-labelledby="updates-title"
      class="rounded-xl border border-stroke bg-surface"
    >
      <h3
        id="updates-title"
        class="border-b border-stroke px-5 py-4 text-sm font-semibold"
      >
        Updates
      </h3>
      <div
        class="flex items-center justify-between gap-4 border-b border-stroke p-5"
      >
        <p class="text-sm font-medium">Current version</p>
        <div class="flex items-center gap-4">
          <p class="text-sm text-muted">{{ appVersion }}</p>
          <button
            type="button"
            :disabled="!service || opening"
            class="rounded-lg border border-stroke px-3 py-2 text-xs hover:border-primary disabled:opacity-40"
            @click="open('changelog')"
          >
            View changelog
          </button>
        </div>
      </div>
      <div class="flex flex-wrap items-center justify-between gap-4 p-5">
        <div>
          <p class="text-sm font-medium">Sparkle updates</p>
          <p class="mt-1 text-sm text-muted">
            Automatic update checks are coming soon.
          </p>
        </div>
        <button
          type="button"
          disabled
          class="rounded-lg border border-stroke px-3 py-2 text-xs text-muted opacity-50"
        >
          Check for updates
        </button>
      </div>
    </section>
  </section>
</template>
