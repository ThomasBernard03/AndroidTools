<script setup lang="ts">
import {
  computed,
  nextTick,
  onBeforeUnmount,
  onMounted,
  ref,
  watch,
} from 'vue';
import type { LogPage } from '../domain/logcat';
import { logcatFields } from './logcatFields';
import {
  ROW_HEIGHT,
  MAX_SCROLL_HEIGHT,
  offsetToScroll,
  scrollGeometry,
  scrollToOffset,
} from './virtualLogcat';

const props = defineProps<{
  page: LogPage;
  total: number;
  offset: number;
  query: string;
  match: number | null;
  status: string;
  softWrap?: boolean;
  follow?: boolean;
}>();
const emit = defineEmits<{
  'update:offset': [value: number];
  rows: [value: number];
  browse: [];
}>();
const viewport = ref<HTMLElement>();
const height = ref(500);
const width = ref(0);
const wrappedPage = ref<HTMLElement>();
const pageHeight = ref(0);
// Unloaded rows use an estimate; the bounded page uses real browser layout.
const estimatedHeight = computed(() =>
  Math.min(ROW_HEIGHT, MAX_SCROLL_HEIGHT / Math.max(1, props.total)),
);
const pageTop = computed(() => props.page.start * estimatedHeight.value);
const wrappedHeight = computed(() =>
  Math.max(
    height.value,
    pageTop.value +
      pageHeight.value +
      Math.max(0, props.total - props.page.start - props.page.entries.length) *
        estimatedHeight.value,
  ),
);
let anchor: { position: number; inset: number } | undefined;
const geometry = computed(() =>
  scrollGeometry(props.total, props.softWrap ? ROW_HEIGHT : height.value),
);
const physicalTop = computed(() =>
  offsetToScroll(props.offset, props.total, height.value),
);
const rendered = computed(() =>
  props.page.entries
    .map((entry, index) => ({
      entry,
      position: props.page.start + index,
      fields: logcatFields(entry.text),
    }))
    .filter(
      ({ position }) =>
        props.softWrap ||
        (position >= props.offset - 20 &&
          position < props.offset + geometry.value.rows + 20),
    ),
);
let observer: ResizeObserver | undefined;
let disposed = false;
let expectedScroll: number | undefined;
let wheelRemainder = 0;

watch(geometry, (value) => emit('rows', value.rows), { immediate: true });
watch([physicalTop, height, () => props.softWrap], async () => {
  await nextTick();
  if (disposed || !viewport.value || props.softWrap) return;
  expectedScroll = physicalTop.value;
  viewport.value.scrollTop = expectedScroll;
});
function wrappedLines() {
  return Array.from(
    wrappedPage.value?.querySelectorAll<HTMLElement>('.logcat-line') ?? [],
  );
}
watch(
  [
    () => props.page,
    () => props.offset,
    () => props.softWrap,
    () => props.follow,
    height,
    width,
  ],
  async () => {
    await nextTick();
    if (disposed || !props.softWrap || !viewport.value) return;
    const lines = wrappedLines();
    pageHeight.value = wrappedPage.value?.offsetHeight ?? 0;
    await nextTick();
    if (disposed || !viewport.value) return;
    const line = lines[props.offset - props.page.start];
    // Wait for the requested page instead of jumping through stale entries.
    if (!line) return;
    const inset = anchor?.position === props.offset ? anchor.inset : 0;
    const top = props.follow
      ? pageTop.value + pageHeight.value - height.value
      : pageTop.value +
        line.offsetTop +
        Math.min(inset, Math.max(0, line.offsetHeight - 1));
    expectedScroll = Math.max(
      0,
      Math.min(viewport.value.scrollHeight - viewport.value.clientHeight, top),
    );
    if (anchor?.inset === Infinity) {
      anchor = {
        position: props.offset,
        inset: expectedScroll - pageTop.value - line.offsetTop,
      };
    }
    viewport.value.scrollLeft = 0;
    viewport.value.scrollTop = expectedScroll;
  },
  { flush: 'post' },
);
onMounted(() => {
  observer = new ResizeObserver(() => {
    height.value = viewport.value?.clientHeight || 500;
    width.value = viewport.value?.clientWidth || 0;
  });
  if (viewport.value) {
    height.value = viewport.value.clientHeight || 500;
    observer.observe(viewport.value);
  }
});
onBeforeUnmount(() => {
  disposed = true;
  observer?.disconnect();
});

function goTo(offset: number) {
  emit('browse');
  emit(
    'update:offset',
    Math.min(geometry.value.maxOffset, Math.max(0, offset)),
  );
}
function firstLine() {
  anchor = undefined;
  goTo(0);
  expectedScroll = 0;
  if (viewport.value) viewport.value.scrollTop = 0;
}
defineExpose({ firstLine });
function onScroll() {
  const top = viewport.value?.scrollTop ?? 0;
  if (expectedScroll !== undefined && Math.abs(top - expectedScroll) < 2) {
    expectedScroll = undefined;
    return;
  }
  if (props.softWrap) {
    expectedScroll = undefined;
    const localTop = top - pageTop.value;
    const lines = wrappedLines();
    const index = lines.findIndex(
      (line) => line.offsetTop + line.offsetHeight > localTop,
    );
    let position: number;
    let inset = 0;
    if (localTop >= 0 && index !== -1) {
      position = props.page.start + index;
      inset = localTop - lines[index]!.offsetTop;
    } else if (localTop < 0) {
      position = Math.floor(top / estimatedHeight.value);
    } else {
      position =
        props.page.start +
        lines.length +
        Math.floor((localTop - pageHeight.value) / estimatedHeight.value);
    }
    anchor = { position, inset };
    goTo(position);
    return;
  }
  if (Math.abs(top - physicalTop.value) < 2) return;
  expectedScroll = undefined;
  goTo(scrollToOffset(top, props.total, height.value));
}
function onWheel(event: WheelEvent) {
  if (props.softWrap) return;
  if (
    event.ctrlKey ||
    event.shiftKey ||
    Math.abs(event.deltaX) > Math.abs(event.deltaY)
  )
    return;
  event.preventDefault();
  wheelRemainder +=
    event.deltaY *
    (event.deltaMode === 1
      ? ROW_HEIGHT
      : event.deltaMode === 2
        ? height.value
        : 1);
  const lines = Math.trunc(wheelRemainder / ROW_HEIGHT);
  wheelRemainder -= lines * ROW_HEIGHT;
  if (lines) goTo(props.offset + lines);
}
function onKeydown(event: KeyboardEvent) {
  if (props.softWrap && event.key !== 'Home' && event.key !== 'End') return;
  anchor =
    props.softWrap && event.key === 'End'
      ? { position: geometry.value.maxOffset, inset: Infinity }
      : undefined;
  const actions: Record<string, number> = {
    ArrowUp: props.offset - 1,
    ArrowDown: props.offset + 1,
    PageUp: props.offset - geometry.value.rows,
    PageDown: props.offset + geometry.value.rows,
    Home: 0,
    End: geometry.value.maxOffset,
  };
  const offset = actions[event.key];
  if (offset !== undefined) {
    event.preventDefault();
    goTo(offset);
    if (props.softWrap && viewport.value) {
      // Home/End must also move within a single message taller than the viewport.
      expectedScroll =
        event.key === 'Home'
          ? 0
          : viewport.value.scrollHeight - viewport.value.clientHeight;
      viewport.value.scrollTop = expectedScroll;
    }
  }
}
function parts(text: string) {
  if (!props.query) return [{ text, match: false }];
  const needle = props.query.toLowerCase();
  const lower = text.toLowerCase();
  const result: { text: string; match: boolean }[] = [];
  let cursor = 0;
  let index = lower.indexOf(needle);
  while (index !== -1) {
    result.push(
      { text: text.slice(cursor, index), match: false },
      { text: text.slice(index, index + needle.length), match: true },
    );
    cursor = index + needle.length;
    index = lower.indexOf(needle, cursor);
  }
  result.push({ text: text.slice(cursor), match: false });
  return result;
}
</script>

<template>
  <div
    ref="viewport"
    class="logcat-output select-text overflow-auto rounded border border-stroke bg-surface font-mono text-xs"
    :class="{ 'logcat-wrapped': softWrap }"
    tabindex="0"
    aria-label="Logcat output"
    @scroll="onScroll"
    @wheel="onWheel"
    @keydown="onKeydown"
  >
    <div
      class="relative"
      :style="{
        height: `${softWrap ? wrappedHeight : geometry.scrollHeight}px`,
      }"
    >
      <p v-if="!total" class="p-4 font-sans text-sm text-muted">
        {{
          status === 'starting'
            ? 'Starting Logcat…'
            : status === 'streaming'
              ? 'Waiting for logs matching the selected filters…'
              : 'No logs to display.'
        }}
      </p>
      <div
        ref="wrappedPage"
        :class="{ 'absolute w-full': softWrap }"
        :style="softWrap ? { top: `${pageTop}px` } : undefined"
      >
        <div
          v-for="{ entry, position, fields } in rendered"
          :key="entry.id"
          class="logcat-line px-2 leading-5"
          :style="
            softWrap
              ? undefined
              : { top: `${physicalTop + (position - offset) * ROW_HEIGHT}px` }
          "
          :data-entry-id="entry.id"
          :data-position="position"
          :data-level="entry.level"
          :class="{
            'logcat-current': match === position,
          }"
        >
          <template v-for="(field, fieldIndex) in fields" :key="field.kind">
            <template v-if="fieldIndex">{{ ' ' }}</template>
            <span
              :class="`logcat-${field.kind}`"
              :title="field.kind === 'tag' ? field.text : undefined"
              ><template v-for="(part, index) in parts(field.text)" :key="index"
                ><mark v-if="part.match">{{ part.text }}</mark
                ><template v-else>{{ part.text }}</template></template
              ></span
            >
          </template>
          <span
            v-if="entry.repeatCount > 1"
            class="ml-2 rounded border border-primary/30 bg-primary/10 px-1 text-primary"
            :aria-label="`${entry.repeatCount} identical consecutive entries`"
            >×{{ entry.repeatCount }}</span
          >
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
@reference "../../../styles.css";
.logcat-output {
  height: max(240px, calc(100dvh - 365px));
  max-height: 2000px;
  overflow-anchor: none;
}
.logcat-line {
  --logcat-text: var(--color-logcat-verbose);
  --logcat-badge: var(--color-logcat-verbose-badge);
  --logcat-on-badge: var(--color-logcat-verbose);
  color: var(--logcat-text);
  position: absolute;
  white-space: pre;
  min-width: 100%;
  height: 20px;
}
.logcat-line[data-level='D'] {
  --logcat-text: var(--color-logcat-debug);
  --logcat-badge: var(--color-logcat-debug-badge);
}
.logcat-line[data-level='I'] {
  --logcat-text: var(--color-logcat-info);
  --logcat-badge: var(--color-logcat-info-badge);
  --logcat-on-badge: var(--color-logcat-info-on-badge);
}
.logcat-line[data-level='W'] {
  --logcat-text: var(--color-logcat-warning);
  --logcat-badge: var(--color-logcat-warning-badge);
}
.logcat-line[data-level='E'],
.logcat-line[data-level='F'] {
  --logcat-text: var(--color-logcat-error);
  --logcat-badge: var(--color-logcat-error-badge);
  --logcat-on-badge: var(--color-on-primary);
}
.logcat-timestamp,
.logcat-process,
.logcat-tag {
  display: inline-block;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  vertical-align: top;
}
.logcat-timestamp {
  width: 140px;
}
.logcat-process {
  width: 80px;
}
.logcat-tag {
  width: 150px;
}
.logcat-level {
  display: inline-block;
  padding: 2px 8px;
  line-height: 16px;
  vertical-align: top;
  text-align: center;
  color: var(--logcat-on-badge);
  background: var(--logcat-badge);
}
.logcat-wrapped {
  overflow-x: hidden;
}
.logcat-wrapped .logcat-line {
  position: relative;
  width: 100%;
  height: auto;
  min-height: 20px;
  white-space: pre-wrap;
  overflow-wrap: anywhere;
}
.logcat-current {
  @apply bg-primary/15;
  outline: 1px solid var(--color-primary);
  outline-offset: -1px;
}
mark {
  @apply bg-warning/25 text-foreground;
}
</style>
