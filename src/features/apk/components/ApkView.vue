<script setup lang="ts">
import { ref, watch } from 'vue'
import UiIcon from '../../../components/UiIcon.vue'
import ErrorNotice from '../../../components/ErrorNotice.vue'
import ApkSignatures from './ApkSignatures.vue'
import ApkPermissions from './ApkPermissions.vue'
import ApkManifest from './ApkManifest.vue'
import { useApk } from '../useApk'

const emit = defineEmits<{ open: [] }>()
const { report, error, dropError, loading, choosing, dragging, fileName, selectFile } = useApk(() =>
  emit('open'),
)
const section = ref<'signature' | 'manifest' | 'permissions'>('signature')
watch(report, () => {
  section.value = 'signature'
})
</script>

<template>
  <div class="relative mx-auto flex w-full max-w-5xl flex-1 flex-col px-6 py-8 lg:px-10 lg:py-10">
    <div
      v-if="dragging"
      class="pointer-events-none absolute inset-3 z-20 flex items-center justify-center rounded-xl border-2 border-dashed border-accent bg-surface/95 text-center"
    >
      <div>
        <UiIcon name="upload" :size="32" class="mx-auto mb-4 text-accent" />
        <p class="text-lg font-medium">Déposez votre APK ici</p>
        <p class="mt-2 text-xs text-secondary">Un seul fichier .apk à la fois</p>
      </div>
    </div>
    <header class="mb-7 flex flex-wrap items-start justify-between gap-4">
      <div>
        <p class="section-label mb-2">APPLICATIONS / INSPECTION</p>
        <h2 class="text-[23px] font-semibold leading-8 tracking-[-0.035em]">Analyse APK</h2>
        <p class="mt-1.5 text-[13px] text-secondary">
          Signature, manifeste et permissions. Sans connecter de téléphone.
        </p>
      </div>
      <button type="button" class="button mt-1" :disabled="choosing" @click="selectFile">
        <UiIcon name="upload" :size="14" />{{ choosing ? 'Sélection…' : 'Choisir un APK' }}
      </button>
    </header>
    <ErrorNotice v-if="dropError" :error="dropError" class="mb-5" />
    <ErrorNotice v-if="error" :error="error" class="mb-5" />
    <div v-if="loading" role="status" class="rounded-lg border border-line px-6 py-16 text-center">
      <UiIcon name="refresh" :size="24" class="mx-auto mb-4 animate-spin text-accent" />
      <p class="font-medium">Analyse de l’APK…</p>
      <p class="mt-2 break-all text-xs text-secondary">{{ fileName }}</p>
    </div>
    <template v-else-if="report">
      <section
        aria-label="Informations de l’APK"
        class="mb-6 rounded-lg border border-line bg-raised/30 p-5"
      >
        <div class="flex items-start gap-3">
          <UiIcon name="package" :size="24" class="mt-1 text-accent" />
          <div class="min-w-0">
            <h3 class="break-words text-base font-medium">
              {{ report.appLabel ?? report.fileName }}
            </h3>
            <p class="mt-1 break-all font-mono text-xs text-secondary">
              {{ report.packageName ?? 'Package non renseigné' }}
            </p>
            <p class="mt-1 break-all text-[11px] text-muted">
              {{ report.fileName }} ·
              {{
                (report.fileSize / 1024 / 1024).toLocaleString('fr-FR', {
                  maximumFractionDigits: 2,
                })
              }}
              Mio
            </p>
          </div>
        </div>
        <dl class="mt-5 grid gap-4 border-t border-line pt-4 sm:grid-cols-3">
          <div>
            <dt class="text-[11px] text-muted">Version</dt>
            <dd class="mt-1 break-all text-xs">
              {{ report.versionName ?? 'Non disponible'
              }}<span v-if="report.versionCode" class="text-secondary">
                ({{ report.versionCode }})</span
              >
            </dd>
          </div>
          <div>
            <dt class="text-[11px] text-muted">SDK minimum</dt>
            <dd class="mt-1 text-xs">{{ report.minSdk ?? 'Non renseigné' }}</dd>
          </div>
          <div>
            <dt class="text-[11px] text-muted">SDK cible</dt>
            <dd class="mt-1 text-xs">{{ report.targetSdk ?? 'Non renseigné' }}</dd>
          </div>
        </dl>
      </section>
      <nav
        aria-label="Sections de l’analyse APK"
        class="mb-6 flex flex-wrap gap-1 border-b border-line pb-2"
      >
        <button
          v-for="item in [
            { id: 'signature', label: 'Signature' },
            { id: 'manifest', label: 'Manifeste' },
            { id: 'permissions', label: `Permissions (${report.permissions.length})` },
          ] as const"
          :key="item.id"
          type="button"
          :aria-pressed="section === item.id"
          class="rounded-md px-3 py-2 text-xs font-medium transition-colors"
          :class="
            section === item.id
              ? 'bg-accent/10 text-accent'
              : 'text-secondary hover:bg-raised hover:text-ink'
          "
          @click="section = item.id"
        >
          {{ item.label }}
        </button>
      </nav>
      <ApkSignatures
        v-if="section === 'signature'"
        :signatures="report.signatures"
        :warnings="report.signatureWarnings"
      />
      <ApkManifest v-else-if="section === 'manifest'" :manifest="report.manifest" />
      <ApkPermissions v-else :permissions="report.permissions" />
    </template>
    <section
      v-else
      class="flex flex-1 flex-col items-center justify-center rounded-lg border border-dashed border-line px-6 py-16 text-center"
    >
      <div
        class="mb-5 flex size-16 items-center justify-center rounded-2xl border border-accent/15 bg-accent/8 text-accent"
      >
        <UiIcon name="package" :size="32" />
      </div>
      <h3 class="text-base font-medium">Glissez-déposez un APK</h3>
      <p class="mt-2 max-w-sm text-xs leading-6 text-secondary">
        Déposez un fichier depuis le Finder ou l’explorateur de fichiers, ou utilisez « Choisir un
        APK ».
      </p>
      <div class="mt-6 flex flex-wrap justify-center gap-2">
        <span class="status-badge">Certificats & empreintes</span
        ><span class="status-badge">AndroidManifest.xml</span
        ><span class="status-badge">Permissions</span>
      </div>
    </section>
    <footer class="mt-auto flex items-center gap-2 pt-8 text-[11px] text-muted">
      <UiIcon name="shield" :size="13" />Analyse locale · aucune installation de l’APK
    </footer>
  </div>
</template>
