<script setup lang="ts">
defineProps<{ paths: string[]; removing: boolean }>()
defineEmits<{ open: [path: string]; remove: [path: string] }>()
</script>

<template>
  <section aria-label="APK récents" class="mb-6 rounded-lg border border-line bg-raised/30 p-4">
    <h3 class="mb-3 text-xs font-medium">APK récents</h3>
    <p v-if="!paths.length" class="text-xs text-muted">Aucun APK analysé récemment.</p>
    <ul v-else class="max-h-60 space-y-1 overflow-y-auto">
      <li v-for="path in paths" :key="path" class="flex items-center gap-3">
        <button
          type="button"
          class="min-w-0 flex-1 rounded-md px-2 py-2 text-left hover:bg-raised"
          :title="path"
          @click="$emit('open', path)"
        >
          <span class="block truncate text-xs font-medium">{{ path.split(/[/\\]/).pop() }}</span>
          <span class="mt-1 block truncate text-[11px] text-muted">{{ path }}</span>
        </button>
        <button
          type="button"
          class="rounded-md px-2 py-2 text-xs text-secondary hover:bg-raised"
          :disabled="removing"
          :aria-label="`Retirer ${path} de l’historique`"
          @click="$emit('remove', path)"
        >
          Retirer
        </button>
      </li>
    </ul>
  </section>
</template>
