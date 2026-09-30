<script setup lang="ts">
import UiIcon from '../../../components/UiIcon.vue'
import ErrorNotice from '../../../components/ErrorNotice.vue'
import type { AppError } from '../../../shared/errors'
import type { FileEntry, FilePreview } from '../types'
import { formatSize } from '../format'

defineProps<{
  entry: FileEntry
  preview: FilePreview | null
  loading: boolean
  error: AppError | null
}>()
defineEmits<{ close: []; retry: [] }>()
</script>

<template>
  <section
    aria-label="Aperçu du fichier"
    :aria-busy="loading"
    class="min-w-0 rounded-lg border border-line bg-raised/20"
  >
    <header class="flex items-center gap-3 border-b border-line px-4 py-3">
      <UiIcon name="file" class="text-accent" />
      <div class="min-w-0 flex-1">
        <h3 class="break-all text-xs font-medium">{{ entry.name }}</h3>
        <p class="mt-0.5 text-[11px] text-muted">{{ formatSize(entry.size) }} · Aperçu texte</p>
      </div>
      <button
        type="button"
        class="icon-button"
        aria-label="Fermer l’aperçu"
        @click="$emit('close')"
      >
        <UiIcon name="close" />
      </button>
    </header>
    <p v-if="loading" role="status" class="flex items-center gap-2 p-6 text-secondary">
      <UiIcon name="refresh" class="animate-spin" />Lecture du fichier…
    </p>
    <div v-else-if="error" class="space-y-3 p-4">
      <ErrorNotice :error="error" />
      <button
        v-if="error.code !== 'binary_file'"
        type="button"
        class="button"
        @click="$emit('retry')"
      >
        Réessayer
      </button>
    </div>
    <template v-else-if="preview">
      <p
        v-if="preview.truncated"
        role="status"
        class="border-b border-line px-4 py-2 text-xs text-amber-200"
      >
        Aperçu limité aux 256 premiers Kio.
      </p>
      <pre
        v-if="preview.text"
        tabindex="0"
        aria-label="Contenu texte du fichier"
        class="max-h-[32rem] overflow-auto p-4 font-mono text-xs leading-6 text-secondary"
        >{{ preview.text }}</pre>
      <p v-else class="p-6 text-xs text-muted">Ce fichier est vide.</p>
    </template>
  </section>
</template>
