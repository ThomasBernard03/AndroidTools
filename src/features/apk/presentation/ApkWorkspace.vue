<script setup lang="ts">
import {
  computed,
  onActivated,
  onDeactivated,
  onMounted,
  onBeforeUnmount,
  ref,
  shallowRef,
} from 'vue';
import AppIcon from '../../../shared/presentation/widgets/AppIcon.vue';
import {
  ApkError,
  type ApkReport,
  type ApkService,
  type ApkDrop,
} from '../domain/apk';

const props = defineProps<{
  service?: ApkService | undefined;
  demo?: boolean | undefined;
}>();
const report = shallowRef<ApkReport | null>(null);
const busy = ref(false);
const choosing = ref(false);
const dragging = ref(false);
const error = ref('');
const dropError = ref('');
const iconFailed = ref(false);
let active = false;
let disposed = false;
let listening = false;
let stop: (() => void) | undefined;
let request = 0;
function value(section: string, label: string) {
  return (
    report.value?.sections
      .find((s) => s.title === section)
      ?.items.find((i) => i.label === label)?.value ?? null
  );
}
const appName = computed(
  () =>
    value('Application', 'Application label') ||
    value('Application', 'Package name') ||
    'Android application',
);
const version = computed(() => {
  const name = value('Application', 'Version name');
  const code = value('Application', 'Version code');
  return name
    ? `${name}${code ? ` (${code})` : ''}`
    : code
      ? `Build ${code}`
      : 'Unavailable';
});
const debuggable = computed(() => {
  const flag = value('Application flags (declared)', 'Debuggable');
  if (
    flag === null ||
    ['false', '0', '0x0', '0x00000000'].includes(flag.toLowerCase())
  )
    return 'No';
  if (['true', '1', '-1', '0xffffffff'].includes(flag.toLowerCase()))
    return 'Yes';
  return 'Unavailable';
});
const summary = computed(() => [
  { label: 'APK size', value: bytes(report.value?.size ?? 0) },
  { label: 'App version', value: version.value },
  { label: 'Debuggable', value: debuggable.value },
  {
    label: 'Minimum SDK',
    value:
      value('Android compatibility', 'Minimum SDK') || '1 (Android default)',
  },
  {
    label: 'Maximum SDK',
    value:
      value('Android compatibility', 'Maximum SDK') || 'No maximum declared',
  },
]);
// The same certificate often appears in several signing schemes. Show it once.
const certificates = computed(() => {
  const groups = new Map<
    string,
    { schemes: string[]; items: ApkReport['sections'][number]['items'] }
  >();
  for (const section of report.value?.sections ?? []) {
    if (!section.title.startsWith('Certificate · ')) continue;
    const scheme = section.title.split(' · ')[1] ?? 'Unknown scheme';
    const fingerprint = section.items.find((i) => i.label === 'SHA-256')?.value;
    const key = `${scheme.startsWith('Stamp') ? 'stamp' : 'signer'}:${fingerprint || section.title}`;
    const existing = groups.get(key);
    if (existing) {
      if (!existing.schemes.includes(scheme)) existing.schemes.push(scheme);
    } else groups.set(key, { schemes: [scheme], items: section.items });
  }
  return [...groups.values()];
});
function bytes(value: number) {
  if (value < 1024) return `${value} B`;
  if (value < 1024 ** 2) return `${(value / 1024).toFixed(1)} KiB`;
  return `${(value / 1024 ** 2).toFixed(2)} MiB`;
}
function message(e: unknown) {
  return e instanceof ApkError
    ? e.message
    : 'APK analysis could not finish. Please retry.';
}
async function analyze(paths: string[]) {
  if (!props.service) return;
  if (paths.length !== 1 || !/\.apk$/i.test(paths[0] ?? '')) {
    error.value = 'Choose a single .apk file.';
    return;
  }
  const id = ++request;
  error.value = '';
  report.value = null;
  busy.value = true;
  iconFailed.value = false;
  try {
    const result = await props.service.analyze(paths[0]!);
    if (id === request && !disposed) report.value = result;
  } catch (e) {
    if (id === request && !disposed) error.value = message(e);
  } finally {
    if (id === request && !disposed) busy.value = false;
  }
}
async function choose() {
  if (!props.service || choosing.value) return;
  choosing.value = true;
  const id = request;
  try {
    const path = await props.service.choosePath();
    if (path && active && !disposed && id === request) await analyze([path]);
  } catch (e) {
    if (!disposed && id === request) error.value = message(e);
  } finally {
    choosing.value = false;
  }
}
function drop(event: ApkDrop) {
  if (!active || disposed) return;
  dragging.value = event.type === 'enter';
  if (event.type === 'drop') void analyze(event.paths);
}
async function activate() {
  active = true;
  if (!props.service || listening || stop) return;
  listening = true;
  try {
    const unlisten = await props.service.listenDrop(drop);
    if (disposed || !active) unlisten();
    else stop = unlisten;
  } catch {
    dropError.value = 'Drag and drop is unavailable. Use Choose APK instead.';
  } finally {
    listening = false;
  }
}
function deactivate() {
  active = false;
  dragging.value = false;
  stop?.();
  stop = undefined;
}
onMounted(activate);
onActivated(activate);
onDeactivated(deactivate);
onBeforeUnmount(() => {
  disposed = true;
  request++;
  deactivate();
});
</script>

<template>
  <section
    class="mx-auto max-w-4xl space-y-6 p-6 lg:p-10"
    aria-labelledby="apk-title"
  >
    <div>
      <h2 id="apk-title" class="text-2xl font-semibold">APK analysis</h2>
      <p class="mt-2 text-sm text-muted">
        App details and signing information, at a glance.
      </p>
    </div>
    <p v-if="demo" role="note" class="text-sm text-warning">
      Demo mode — simulated APK analysis. No local file is read.
    </p>
    <div
      class="rounded-xl border border-dashed text-center"
      :class="[
        dragging ? 'border-primary bg-primary/10' : 'border-stroke bg-surface',
        report
          ? 'flex flex-wrap items-center justify-between gap-3 p-4'
          : 'p-8',
      ]"
    >
      <p class="font-medium">
        {{
          dragging ? 'Drop your APK to analyze it' : 'Drag and drop an APK here'
        }}
      </p>
      <p v-if="!report" class="mt-2 text-xs text-muted">
        One .apk file · Up to 1 GiB · Processed on your computer
      </p>
      <button
        type="button"
        class="rounded-lg bg-primary px-5 py-2.5 text-sm font-semibold text-on-primary disabled:opacity-50"
        :class="report ? '' : 'mt-5'"
        :disabled="!service || choosing"
        @click="choose"
      >
        {{ choosing ? 'Opening APK…' : 'Choose APK' }}
      </button>
    </div>
    <p v-if="!service" role="alert" class="text-sm text-warning">
      APK analysis requires the desktop application.
    </p>
    <p v-if="dropError" role="alert" class="text-sm text-warning">
      {{ dropError }}
    </p>
    <p
      v-if="error"
      role="alert"
      class="rounded-lg border border-danger/30 bg-danger/5 p-4 text-sm text-danger"
    >
      {{ error }}
    </p>
    <p v-if="busy" role="status" class="text-sm text-primary">
      Analyzing APK… Large packages may take a moment.
    </p>
    <div v-if="report" class="space-y-5" aria-label="APK report">
      <section class="rounded-xl border border-stroke bg-surface p-5">
        <div class="flex items-center gap-4">
          <div
            class="flex size-16 shrink-0 items-center justify-center overflow-hidden rounded-2xl border border-stroke bg-surface-raised"
          >
            <img
              v-if="report.iconDataUrl && !iconFailed"
              :src="report.iconDataUrl"
              alt="App icon"
              class="size-full object-contain"
              @error="iconFailed = true"
            />
            <span v-else role="img" aria-label="App icon unavailable"
              ><AppIcon name="package" class="size-8 text-muted"
            /></span>
          </div>
          <div class="min-w-0">
            <h3 class="break-words text-lg font-semibold">{{ appName }}</h3>
            <p class="mt-1 break-all text-sm text-muted">
              {{ value('Application', 'Package name') }}
            </p>
            <p class="mt-1 truncate text-xs text-muted" :title="report.path">
              {{ report.path.split(/[\\/]/).pop() }}
            </p>
          </div>
        </div>
        <dl
          class="mt-6 grid grid-cols-2 gap-x-6 gap-y-5 border-t border-stroke pt-5 text-sm sm:grid-cols-3"
        >
          <div v-for="item in summary" :key="item.label">
            <dt class="text-xs text-muted">{{ item.label }}</dt>
            <dd
              class="mt-1.5 break-words font-medium"
              :class="
                item.label === 'Debuggable' && debuggable === 'Yes'
                  ? 'text-warning'
                  : ''
              "
            >
              {{ item.value }}
            </dd>
          </div>
        </dl>
      </section>
      <section
        class="rounded-xl border border-stroke bg-surface p-5"
        aria-labelledby="apk-signature-title"
      >
        <div class="flex items-center gap-2">
          <AppIcon name="shield" class="size-5 text-muted" />
          <h3 id="apk-signature-title" class="font-semibold">Signature</h3>
          <span
            class="ml-auto rounded-full border px-2.5 py-1 text-xs font-medium"
            :class="{
              'border-primary/30 bg-primary/10 text-primary':
                report.signature.status === 'verified',
              'border-danger/30 bg-danger/10 text-danger':
                report.signature.status === 'invalid',
              'border-stroke text-muted': ['unverified', 'unsigned'].includes(
                report.signature.status,
              ),
            }"
            aria-label="Signature verification status"
            >{{
              {
                verified: 'Verified',
                invalid: 'Invalid',
                unverified: 'Not verified',
                unsigned: 'Unsigned',
              }[report.signature.status]
            }}{{
              report.signature.schemes.length
                ? ` · ${report.signature.schemes.join(', ')}`
                : ''
            }}</span
          >
        </div>
        <p class="mt-3 text-xs text-muted">{{ report.signature.message }}</p>
        <p v-if="!certificates.length" class="mt-4 text-sm text-muted">
          No signing certificate available.
        </p>
        <details
          v-for="(certificate, index) in certificates"
          :key="index"
          :open="index === 0"
          class="mt-4 border-t border-stroke pt-4"
        >
          <summary class="cursor-pointer text-sm font-medium">
            {{ certificate.schemes.join(' · ')
            }}<span class="ml-2 text-muted">Certificate {{ index + 1 }}</span>
          </summary>
          <dl class="mt-3 space-y-3 text-sm">
            <div
              v-for="item in certificate.items"
              :key="item.label"
              class="grid gap-1 sm:grid-cols-[140px_minmax(0,1fr)]"
            >
              <dt class="text-muted">{{ item.label }}</dt>
              <dd
                class="min-w-0 break-all select-text"
                :class="
                  item.label.startsWith('SHA-') ? 'font-mono text-xs' : ''
                "
              >
                {{ item.value || 'Unavailable' }}
              </dd>
            </div>
          </dl>
        </details>
        <p
          v-for="warning in report.warnings"
          :key="warning"
          class="mt-4 text-xs text-muted"
        >
          {{ warning }}
        </p>
      </section>
    </div>
  </section>
</template>
