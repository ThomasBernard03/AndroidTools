<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { version } from '../../../src-tauri/tauri.conf.json'
import { configureTelemetry } from '../../shared/telemetry'
import {
  checkAppUpdates,
  getSettings,
  openAppLog,
  openProjectLink,
  setCrashReporting,
  type AppSettings,
  type UpdateStatus,
} from './api'

const settings = ref<AppSettings | null>(null)
const busy = ref(false)
const error = ref('')
const notice = ref('')
const update = ref<UpdateStatus | null>(null)

async function run(action: () => Promise<void>) {
  if (busy.value) return
  busy.value = true
  error.value = ''
  notice.value = ''
  try {
    await action()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : String(cause)
  } finally {
    busy.value = false
  }
}

function load() {
  return run(async () => {
    settings.value = await getSettings()
  })
}
onMounted(load)

function toggleReporting() {
  return run(async () => {
    if (!settings.value) return
    const enabled = !settings.value.crashReportingEnabled
    await setCrashReporting(enabled)
    settings.value = { ...settings.value, crashReportingEnabled: enabled }
    configureTelemetry(settings.value)
    notice.value = enabled ? 'Rapports de crash activés.' : 'Rapports de crash désactivés.'
  })
}

function checkUpdates() {
  return run(async () => {
    update.value = null
    update.value = await checkAppUpdates()
  })
}
</script>

<template>
  <div class="mx-auto w-full max-w-3xl space-y-6 px-6 py-8 lg:px-10 lg:py-10" :aria-busy="busy">
    <div>
      <p class="section-label mb-2">APPLICATION</p>
      <h2 class="text-[23px] font-semibold tracking-tight">Réglages</h2>
      <p class="mt-2 text-secondary">Android Tools · Version {{ version }}</p>
    </div>

    <section class="space-y-4 rounded-lg border border-line p-5" aria-labelledby="support-title">
      <h3 id="support-title" class="font-semibold">Assistance et projet open source</h3>
      <p class="text-secondary">
        Consultez le journal local de l’application ou signalez un problème sur GitHub.
      </p>
      <div class="flex flex-wrap gap-3">
        <button class="button" :disabled="busy" @click="run(openAppLog)">
          Ouvrir le fichier de log
        </button>
        <button class="button" :disabled="busy" @click="run(() => openProjectLink('issue'))">
          Créer une issue GitHub
        </button>
        <button class="button" :disabled="busy" @click="run(() => openProjectLink('repository'))">
          Voir le projet sur GitHub
        </button>
      </div>
    </section>

    <section class="space-y-4 rounded-lg border border-line p-5" aria-labelledby="updates-title">
      <h3 id="updates-title" class="font-semibold">Mises à jour</h3>
      <button class="button" :disabled="busy" @click="checkUpdates">
        Rechercher les mises à jour
      </button>
      <div v-if="update" role="status" class="space-y-3 text-secondary">
        <p v-if="update.status === 'current'">Aucune version plus récente n’est disponible.</p>
        <p v-else-if="update.status === 'native'">
          La recherche se poursuit dans la fenêtre de mise à jour.
        </p>
        <template v-else>
          <p>Une version plus récente est publiée : {{ update.version }}.</p>
          <button class="button" :disabled="busy" @click="run(() => openProjectLink('releases'))">
            Voir la release et les téléchargements
          </button>
        </template>
      </div>
    </section>

    <section class="space-y-4 rounded-lg border border-line p-5" aria-labelledby="privacy-title">
      <h3 id="privacy-title" class="font-semibold">Rapports de crash</h3>
      <p class="text-secondary">
        Envoyer les erreurs inattendues de l’application à Sentry pour aider à les corriger. Ce
        choix est enregistré et s’applique immédiatement aux nouveaux rapports.
      </p>
      <button
        type="button"
        role="switch"
        :aria-checked="settings?.crashReportingEnabled ?? false"
        :disabled="busy || !settings"
        class="button"
        @click="toggleReporting"
      >
        Rapports de crash Sentry :
        {{ settings ? (settings.crashReportingEnabled ? 'activés' : 'désactivés') : 'chargement…' }}
      </button>
      <p v-if="settings && !settings.sentryDsn" class="text-xs text-muted">
        Sentry n’est pas configuré dans ce build. Aucun rapport n’est envoyé.
      </p>
      <button v-if="!settings && !busy" class="button" @click="load">Recharger les réglages</button>
    </section>
    <p v-if="error" role="alert" class="text-red-300">{{ error }}</p>
    <p v-if="notice" role="status" class="text-positive">{{ notice }}</p>
  </div>
</template>
