<script setup lang="ts">
import { ref, watch } from 'vue';
import type { FileError, FilePreview } from '../domain/files';

const props = defineProps<{
  name: string;
  preview: FilePreview | null;
  loading: boolean;
  error: FileError | null;
}>();
defineEmits<{ close: [] }>();
const imageFailed = ref(false);
watch(
  () => props.preview,
  () => {
    imageFailed.value = false;
  },
);
</script>

<template>
  <section
    aria-labelledby="preview-heading"
    class="overflow-hidden rounded-xl border border-stroke bg-surface"
    @keydown.esc.stop="$emit('close')"
  >
    <div
      class="flex items-center justify-between gap-4 border-b border-stroke p-3"
    >
      <h3 id="preview-heading" class="min-w-0 break-all text-sm font-medium">
        Preview · {{ name }}
      </h3>
      <button
        class="rounded-lg border border-stroke px-3 py-2 text-xs hover:text-primary"
        @click="$emit('close')"
      >
        Close preview
      </button>
    </div>
    <p v-if="loading" role="status" class="p-5 text-sm text-muted">
      Loading preview…
    </p>
    <p v-else-if="error" role="alert" class="p-5 text-sm text-error">
      {{ error.message }}
    </p>
    <template v-else-if="preview">
      <template v-if="preview.kind === 'text'">
        <p v-if="!preview.content" class="p-5 text-sm text-muted">
          This file is empty.
        </p>
        <pre
          v-else
          class="select-text max-h-[32rem] overflow-auto p-4 font-mono text-xs leading-5"
          tabindex="0"
          aria-label="Text preview"
          >{{ preview.content }}</pre>
      </template>
      <p v-else-if="imageFailed" role="alert" class="p-5 text-sm text-error">
        This image could not be decoded. Download it to open it externally.
      </p>
      <div v-else class="flex justify-center overflow-auto bg-canvas p-4">
        <img
          :src="preview.content"
          :alt="name"
          class="max-h-[32rem] max-w-full object-contain"
          @error="imageFailed = true"
        />
      </div>
    </template>
  </section>
</template>
