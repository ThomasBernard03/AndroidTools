<script setup lang="ts">
import { ref, toRef, watch, nextTick } from 'vue'
import ErrorNotice from '../../../components/ErrorNotice.vue'
import UiIcon from '../../../components/UiIcon.vue'
import { useLogcat } from '../useLogcat'

const props = defineProps<{ deviceId: string }>()
const {
  entries,
  filtered,
  level,
  paused,
  loading,
  clearing,
  error,
  notice,
  togglePause,
  refresh,
  clear,
} = useLogcat(toRef(props, 'deviceId'))
const viewport = ref<HTMLElement | null>(null)
const follow = ref(true)
const levels = [
  ['all', 'Tous les niveaux'],
  ['V', 'Verbose'],
  ['D', 'Debug'],
  ['I', 'Info'],
  ['W', 'Warning'],
  ['E', 'Error'],
  ['F', 'Fatal'],
  ['A', 'Assert'],
]
const colors: Record<string, string> = {
  V: 'text-muted',
  D: 'text-secondary',
  I: 'text-ink',
  W: 'text-amber-200',
  E: 'text-red-300',
  F: 'text-red-300',
  A: 'text-red-300',
}
watch([filtered, follow], async () => {
  if (!follow.value) return
  await nextTick()
  if (viewport.value) viewport.value.scrollTop = viewport.value.scrollHeight
})
</script>

<template>
  <section class="flex min-h-0 flex-1 flex-col gap-4 p-6 lg:p-8" aria-labelledby="logcat-heading">
    <div>
      <p class="section-label mb-2">APPAREILS / JOURNAL</p>
      <h2 id="logcat-heading" class="text-[23px] font-semibold tracking-tight">Logcat</h2>
      <p class="mt-1.5 text-secondary">Journal Android en direct · actualisation chaque seconde.</p>
    </div>
    <p v-if="!deviceId" class="rounded-lg border border-line p-10 text-center text-secondary">
      Sélectionnez un appareil USB pour consulter son logcat.
    </p>
    <template v-else>
      <div class="flex flex-wrap items-center gap-3">
        <label class="flex items-center gap-2 text-xs">
          Niveau
          <select v-model="level" class="rounded-md border border-line bg-surface px-3 py-2">
            <option v-for="[value, label] in levels" :key="value" :value="value">
              {{ label }}
            </option>
          </select>
        </label>
        <button
          type="button"
          class="button"
          :disabled="clearing"
          :aria-pressed="paused"
          @click="togglePause"
        >
          {{ paused ? 'Reprendre' : 'Mettre en pause' }}
        </button>
        <button type="button" class="button" :disabled="loading || clearing" @click="refresh">
          <UiIcon name="refresh" :size="13" :class="{ 'animate-spin': loading }" />Actualiser
        </button>
        <button
          type="button"
          class="button"
          :disabled="clearing"
          title="Effacer les buffers logcat de l’appareil et l’affichage"
          @click="clear"
        >
          {{ clearing ? 'Effacement…' : 'Effacer le logcat' }}
        </button>
        <label class="ml-auto flex items-center gap-2 text-xs text-secondary">
          <input v-model="follow" type="checkbox" />Défilement automatique
        </label>
      </div>
      <ErrorNotice v-if="error" :error="error" />
      <p v-if="notice" role="status" class="text-xs text-positive">{{ notice }}</p>
      <div class="flex flex-wrap justify-between gap-2 text-xs text-muted">
        <span role="status">{{
          error
            ? 'Lecture interrompue — actualisez pour réessayer'
            : paused
              ? 'En pause'
              : 'En direct'
        }}</span>
        <span
          >{{ filtered.length }} / {{ entries.length }} entrées · historique limité à 5 000
          entrées</span
        >
      </div>
      <div
        ref="viewport"
        tabindex="0"
        aria-label="Entrées du logcat"
        class="min-h-64 flex-1 overflow-auto rounded-lg border border-line bg-shell p-3 font-mono text-[11px] leading-5 max-md:max-h-[60vh]"
      >
        <p v-if="!filtered.length" class="p-6 text-center font-sans text-secondary">
          {{
            loading
              ? 'Lecture du journal…'
              : entries.length
                ? 'Aucune entrée pour ce niveau.'
                : 'Aucune entrée dans le journal.'
          }}
        </p>
        <div
          v-for="entry in filtered"
          :key="entry.id"
          class="whitespace-pre-wrap break-all"
          :class="colors[entry.level] ?? 'text-secondary'"
        >
          {{ entry.text }}
        </div>
      </div>
      <p class="text-[11px] text-muted">
        Chaque lecture récupère les 2 000 dernières entrées. Une pause ou un débit élevé peut
        entraîner des messages manquants. « Effacer » vide aussi le journal sur l’appareil.
      </p>
    </template>
  </section>
</template>
