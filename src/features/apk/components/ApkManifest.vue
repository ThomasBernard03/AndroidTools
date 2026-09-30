<script setup lang="ts">
defineProps<{ manifest: string }>()
</script>

<template>
  <section aria-label="Manifeste APK" class="space-y-3">
    <div class="flex flex-wrap items-center justify-between gap-2 text-xs">
      <h3 class="font-medium">AndroidManifest.xml</h3>
      <span class="text-muted">XML binaire décodé · lecture seule</span>
    </div>
    <pre
      tabindex="0"
      aria-label="Contenu du manifeste Android"
      class="max-h-[65vh] overflow-auto rounded-lg border border-line bg-shell/60 p-4 font-mono text-[11px] leading-6 text-secondary"
    ><code>{{ manifest }}</code></pre>
  </section>
</template>
