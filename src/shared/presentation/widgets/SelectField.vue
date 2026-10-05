<script setup lang="ts" generic="T extends string">
import {
  computed,
  nextTick,
  onBeforeUnmount,
  onDeactivated,
  onMounted,
  ref,
  watch,
} from 'vue';
import AppIcon from './AppIcon.vue';

const props = defineProps<{
  id: string;
  label: string;
  modelValue: T;
  options: readonly { value: T; label: string; description?: string }[];
  disabled?: boolean;
}>();
const emit = defineEmits<{ 'update:modelValue': [value: T] }>();
const root = ref<HTMLElement>();
const trigger = ref<HTMLButtonElement>();
const open = ref(false);
const active = ref(0);
const selected = computed(() =>
  props.options.find((option) => option.value === props.modelValue),
);
let search = '';
let lastTypedAt = 0;

function close() {
  open.value = false;
  search = '';
}
function show() {
  if (props.disabled || !props.options.length) return;
  active.value = Math.max(
    0,
    props.options.findIndex((option) => option.value === props.modelValue),
  );
  open.value = true;
}
function choose(index: number) {
  const option = props.options[index];
  if (props.disabled || !option) return;
  emit('update:modelValue', option.value);
  close();
  trigger.value?.focus();
}
function onKeydown(event: KeyboardEvent) {
  if (props.disabled) return;
  if (event.key === 'Tab') {
    close();
    return;
  }
  if (event.key === 'Escape') {
    if (open.value) {
      event.preventDefault();
      event.stopPropagation();
      close();
    }
    return;
  }
  if (
    ['ArrowDown', 'ArrowUp', 'Home', 'End', 'Enter', ' '].includes(event.key)
  ) {
    event.preventDefault();
    if (!open.value) {
      show();
      if (event.key === 'Home') active.value = 0;
      if (event.key === 'End') active.value = props.options.length - 1;
    } else if (event.key === 'Enter' || event.key === ' ') choose(active.value);
    else if (event.key === 'Home') active.value = 0;
    else if (event.key === 'End') active.value = props.options.length - 1;
    else
      active.value = Math.max(
        0,
        Math.min(
          props.options.length - 1,
          active.value + (event.key === 'ArrowDown' ? 1 : -1),
        ),
      );
  } else if (
    event.key.length === 1 &&
    !event.ctrlKey &&
    !event.metaKey &&
    !event.altKey
  ) {
    event.preventDefault();
    if (!open.value) show();
    const now = Date.now();
    search = now - lastTypedAt > 700 ? event.key : search + event.key;
    lastTypedAt = now;
    const index = props.options.findIndex((option) =>
      option.label.toLowerCase().startsWith(search.toLowerCase()),
    );
    if (index >= 0) active.value = index;
  }
}
function onOutsidePointer(event: PointerEvent) {
  if (event.target instanceof Node && !root.value?.contains(event.target))
    close();
}
function onFocusout(event: FocusEvent) {
  if (
    !(event.relatedTarget instanceof Node) ||
    !root.value?.contains(event.relatedTarget)
  )
    close();
}
watch(
  () => props.disabled,
  (disabled) => {
    if (disabled) close();
  },
);
watch([active, open], async () => {
  if (!open.value) return;
  await nextTick();
  root.value
    ?.querySelector(`#${props.id}-option-${active.value}`)
    ?.scrollIntoView?.({ block: 'nearest' });
});
onMounted(() => document.addEventListener('pointerdown', onOutsidePointer));
onBeforeUnmount(() =>
  document.removeEventListener('pointerdown', onOutsidePointer),
);
onDeactivated(close);
</script>

<template>
  <div ref="root" class="relative" @focusout="onFocusout">
    <label :id="`${id}-label`" :for="id" class="mb-2 block text-sm">{{
      label
    }}</label>
    <button
      :id="id"
      ref="trigger"
      type="button"
      role="combobox"
      :aria-labelledby="`${id}-label`"
      aria-haspopup="listbox"
      :aria-expanded="open"
      :aria-controls="`${id}-listbox`"
      :aria-activedescendant="open ? `${id}-option-${active}` : undefined"
      :disabled="disabled"
      class="flex w-full items-center justify-between gap-3 rounded-lg border bg-canvas px-3 py-2.5 text-left text-sm transition-colors motion-reduce:transition-none disabled:opacity-50"
      :class="
        open ? 'border-primary/60' : 'border-stroke hover:border-primary/40'
      "
      @click="open ? close() : show()"
      @keydown="onKeydown"
    >
      <span>{{ selected?.label ?? 'Choose an option' }}</span>
      <AppIcon
        name="chevron"
        class="size-4 shrink-0 text-muted transition-transform motion-reduce:transition-none"
        :class="{ 'rotate-180': open }"
      />
    </button>
    <ul
      v-if="open"
      :id="`${id}-listbox`"
      role="listbox"
      :aria-labelledby="`${id}-label`"
      class="absolute top-full z-30 mt-2 max-h-60 w-full overflow-y-auto rounded-xl border border-stroke bg-surface-raised p-1.5 shadow-xl shadow-black/30"
    >
      <li
        v-for="(option, index) in options"
        :id="`${id}-option-${index}`"
        :key="option.value"
        role="option"
        :aria-selected="option.value === modelValue"
        class="flex cursor-pointer items-center gap-3 rounded-lg px-3 py-2.5 text-sm"
        :class="
          index === active ? 'bg-primary/10 text-primary' : 'text-foreground'
        "
        @pointermove="active = index"
        @mousedown.prevent
        @click="choose(index)"
      >
        <div class="min-w-0 flex-1">
          <span class="font-medium">{{ option.label }}</span>
          <p v-if="option.description" class="mt-0.5 text-xs text-muted">
            {{ option.description }}
          </p>
        </div>
        <AppIcon
          v-if="option.value === modelValue"
          name="check"
          class="size-4 shrink-0 text-primary"
        />
      </li>
    </ul>
  </div>
</template>
