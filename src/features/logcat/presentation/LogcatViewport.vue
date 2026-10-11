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
import {
  ROW_HEIGHT,
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
}>();
const emit = defineEmits<{
  'update:offset': [value: number];
  rows: [value: number];
  browse: [];
}>();
const viewport = ref<HTMLElement>();
const height = ref(500);
const geometry = computed(() => scrollGeometry(props.total, height.value));
const physicalTop = computed(() =>
  offsetToScroll(props.offset, props.total, height.value),
);
const rendered = computed(() =>
  props.page.entries
    .map((entry, index) => ({ entry, position: props.page.start + index }))
    .filter(
      ({ position }) =>
        position >= props.offset - 20 &&
        position < props.offset + geometry.value.rows + 20,
    ),
);
let observer: ResizeObserver | undefined;
let disposed = false;
let expectedScroll: number | undefined;
let wheelRemainder = 0;

watch(geometry, (value) => emit('rows', value.rows), { immediate: true });
watch([physicalTop, height], async () => {
  await nextTick();
  if (disposed || !viewport.value) return;
  expectedScroll = physicalTop.value;
  viewport.value.scrollTop = expectedScroll;
});
onMounted(() => {
  observer = new ResizeObserver(() => {
    height.value = viewport.value?.clientHeight || 500;
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
function onScroll() {
  const top = viewport.value?.scrollTop ?? 0;
  if (expectedScroll !== undefined && Math.abs(top - expectedScroll) < 2) {
    expectedScroll = undefined;
    return;
  }
  if (Math.abs(top - physicalTop.value) < 2) return;
  expectedScroll = undefined;
  goTo(scrollToOffset(top, props.total, height.value));
}
function onWheel(event: WheelEvent) {
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
    tabindex="0"
    aria-label="Logcat output"
    @scroll="onScroll"
    @wheel="onWheel"
    @keydown="onKeydown"
  >
    <div class="relative" :style="{ height: `${geometry.scrollHeight}px` }">
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
        v-for="{ entry, position } in rendered"
        :key="entry.id"
        class="logcat-line absolute whitespace-pre px-2 leading-5"
        :style="{ top: `${physicalTop + (position - offset) * ROW_HEIGHT}px` }"
        :data-entry-id="entry.id"
        :data-position="position"
        :class="{
          'text-danger': entry.level === 'E' || entry.level === 'F',
          'text-warning': entry.level === 'W',
          'text-muted': entry.level === 'V' || entry.level === 'D',
          'logcat-current': match === position,
        }"
      >
        <span
          v-if="entry.repeatCount > 1"
          class="mr-2 rounded border border-primary/30 bg-primary/10 px-1 text-primary"
          :aria-label="`${entry.repeatCount} identical consecutive entries`"
          >×{{ entry.repeatCount }}</span
        >
        <template v-for="(part, index) in parts(entry.text)" :key="index"
          ><mark v-if="part.match">{{ part.text }}</mark
          ><template v-else>{{ part.text }}</template></template
        >
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
  min-width: 100%;
  height: 20px;
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
