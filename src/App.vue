<script setup lang="ts">
import { computed, ref } from 'vue'
import { version as appVersion } from '../src-tauri/tauri.conf.json'
import UiIcon from './components/UiIcon.vue'
import ApkView from './features/apk/components/ApkView.vue'
import ApkToolsView from './features/apk/components/ApkToolsView.vue'
import AndroidVersionIcon from './features/devices/components/AndroidVersionIcon.vue'
import DeviceDetails from './features/devices/components/DeviceDetails.vue'
import DeviceEmptyState from './features/devices/components/DeviceEmptyState.vue'
import DeviceSelector from './features/devices/components/DeviceSelector.vue'
import ErrorNotice from './components/ErrorNotice.vue'
import { useDevices } from './features/devices/useDevices'
import FileExplorer from './features/files/components/FileExplorer.vue'
import LogcatView from './features/logcat/components/LogcatView.vue'

const view = ref<'devices' | 'apk' | 'files' | 'logcat' | 'keystore' | 'sign'>('devices')
const apkSection = computed(() => ['apk', 'keystore', 'sign'].includes(view.value))
const toolsOpened = ref(false)
const apkTools = [
  { id: 'keystore', label: 'Génération de keystore' },
  { id: 'sign', label: 'Signature d’APK' },
] as const
function openTool(tool: 'keystore' | 'sign') {
  toolsOpened.value = true
  view.value = tool
}

const {
  devices,
  selectedId,
  selectedDevice,
  info,
  listError,
  infoError,
  notice,
  scanning,
  loadingInfo,
  scanned,
  stoppingAdb,
  adbError,
  adbNotice,
  refreshDevices,
} = useDevices()
</script>

<template>
  <div class="flex min-h-dvh flex-col md:h-dvh md:flex-row md:overflow-hidden">
    <a
      href="#main-content"
      class="sr-only z-50 rounded-md bg-accent p-3 text-shell focus:not-sr-only focus:absolute focus:left-4 focus:top-4"
      >Aller au contenu</a
    >

    <aside
      aria-label="Espace de travail"
      class="flex shrink-0 flex-col px-3 py-4 md:w-56 md:overflow-y-auto"
    >
      <header class="mb-7 flex items-center gap-2.5 px-2">
        <div
          class="flex size-7 items-center justify-center rounded-lg border border-white/10 bg-[#6561b8] text-white shadow-sm"
        >
          <UiIcon name="code" :size="17" />
        </div>
        <h1 class="text-[13px] font-semibold tracking-tight">Android Tools</h1>
        <span class="ml-auto rounded border border-line px-1.5 text-[10px] text-muted">USB</span>
      </header>

      <DeviceSelector
        v-model="selectedId"
        :devices="devices"
        :scanning="scanning || stoppingAdb"
        @refresh="refreshDevices"
      />

      <div v-if="adbError || adbNotice" class="mt-3 space-y-2 px-2">
        <ErrorNotice v-if="adbError" :error="adbError" />
        <p v-if="adbNotice" role="status" class="text-xs leading-5 text-secondary">
          {{ adbNotice }}
        </p>
      </div>

      <nav aria-label="Navigation principale" class="mt-7 space-y-1">
        <p class="section-label mb-2 px-2">Espace de travail</p>
        <button
          type="button"
          :aria-current="view === 'devices' ? 'page' : undefined"
          class="flex w-full items-center gap-2.5 rounded-md border border-transparent px-2.5 py-2 font-medium transition-colors hover:bg-white/9"
          :class="view === 'devices' ? 'bg-white/6 text-ink' : 'text-secondary'"
          @click="view = 'devices'"
        >
          <UiIcon name="grid" class="text-accent" />
          Vue d’ensemble
        </button>
        <button
          type="button"
          :aria-current="view === 'files' ? 'page' : undefined"
          class="flex w-full items-center gap-2.5 rounded-md border border-transparent px-2.5 py-2 font-medium transition-colors hover:bg-white/9"
          :class="view === 'files' ? 'bg-white/6 text-ink' : 'text-secondary'"
          @click="view = 'files'"
        >
          <UiIcon name="folder" :class="view === 'files' ? 'text-accent' : 'text-muted'" />
          Explorateur de fichiers
        </button>
        <button
          type="button"
          :aria-current="view === 'logcat' ? 'page' : undefined"
          class="flex w-full items-center gap-2.5 rounded-md border border-transparent px-2.5 py-2 font-medium transition-colors hover:bg-white/9"
          :class="view === 'logcat' ? 'bg-white/6 text-ink' : 'text-secondary'"
          @click="view = 'logcat'"
        >
          <UiIcon name="code" :class="view === 'logcat' ? 'text-accent' : 'text-muted'" />
          Logcat
        </button>
        <p class="section-label mb-2 px-2 pt-5">APK</p>
        <button
          type="button"
          :aria-current="view === 'apk' ? 'page' : undefined"
          class="flex w-full items-center gap-2.5 rounded-md border border-transparent px-2.5 py-2 font-medium transition-colors hover:bg-white/9"
          :class="view === 'apk' ? 'bg-white/6 text-ink' : 'text-secondary'"
          @click="view = 'apk'"
        >
          <UiIcon name="package" :class="view === 'apk' ? 'text-accent' : 'text-muted'" />Analyse
          APK
        </button>
        <button
          v-for="tool in apkTools"
          :key="tool.id"
          type="button"
          :aria-current="view === tool.id ? 'page' : undefined"
          class="flex w-full items-center gap-2.5 rounded-md border border-transparent px-2.5 py-2 text-left font-medium transition-colors hover:bg-white/9"
          :class="view === tool.id ? 'bg-white/6 text-ink' : 'text-secondary'"
          @click="openTool(tool.id)"
        >
          <UiIcon name="shield" :class="view === tool.id ? 'text-accent' : 'text-muted'" />{{
            tool.label
          }}
        </button>
      </nav>

      <footer class="mt-auto px-2 pt-6 text-xs text-muted">Version {{ appVersion }}</footer>
    </aside>

    <main
      id="main-content"
      tabindex="-1"
      class="flex min-w-0 flex-1 flex-col border-t border-line bg-surface outline-none md:my-2 md:mr-2 md:overflow-y-auto md:rounded-xl md:border"
    >
      <header
        class="sticky top-0 z-10 flex h-12 shrink-0 items-center justify-between gap-3 border-b border-line bg-surface/95 px-5 backdrop-blur-sm lg:px-7"
      >
        <div aria-label="Emplacement actuel" class="flex min-w-0 items-center gap-2.5 text-xs">
          <UiIcon
            :name="apkSection ? 'package' : view === 'files' ? 'folder' : 'phone'"
            class="text-muted"
          />
          <span class="text-secondary">{{ apkSection ? 'APK' : 'Appareils' }}</span>
          <UiIcon name="chevron" :size="12" class="text-muted" />
          <span class="truncate">{{
            view === 'keystore'
              ? 'Génération de keystore'
              : view === 'sign'
                ? 'Signature d’APK'
                : view === 'apk'
                  ? 'Analyse APK'
                  : view === 'files'
                    ? 'Explorateur de fichiers'
                    : view === 'logcat'
                      ? 'Logcat'
                      : (info?.model ?? selectedDevice?.name ?? 'Vue d’ensemble')
          }}</span>
        </div>
        <span class="status-badge shrink-0"
          ><UiIcon :name="apkSection ? 'shield' : 'cable'" :size="12" />{{
            apkSection ? 'Traitement local' : 'USB direct'
          }}</span
        >
      </header>

      <ApkView v-show="view === 'apk'" @open="view = 'apk'" />
      <ApkToolsView
        v-if="toolsOpened"
        v-show="view === 'keystore' || view === 'sign'"
        :mode="view === 'keystore' ? 'keystore' : 'sign'"
      />
      <FileExplorer v-if="view === 'files'" :device-id="selectedDevice?.id ?? ''" />
      <LogcatView v-if="view === 'logcat'" :device-id="selectedDevice?.id ?? ''" />
      <div
        v-show="view === 'devices'"
        class="mx-auto flex w-full max-w-5xl flex-1 flex-col px-6 py-8 lg:px-10 lg:py-10"
      >
        <div class="mb-7 flex flex-wrap items-start justify-between gap-4">
          <div>
            <p class="section-label mb-2">APPAREILS / INFORMATIONS</p>
            <h2 class="text-[23px] font-semibold leading-8 tracking-[-0.035em]">Vue d’ensemble</h2>
            <p class="mt-1.5 text-[13px] text-secondary">
              Les informations essentielles de votre appareil Android.
            </p>
          </div>
          <button
            v-if="selectedDevice"
            type="button"
            class="button mt-1"
            :disabled="loadingInfo || stoppingAdb || scanning"
            @click="refreshDevices"
          >
            <UiIcon name="refresh" :size="13" :class="{ 'animate-spin': loadingInfo }" />
            {{ infoError ? 'Réessayer' : 'Relire les informations' }}
          </button>
        </div>

        <div v-if="listError || notice" class="mb-6 space-y-3">
          <ErrorNotice v-if="listError" :error="listError" />
          <p v-if="notice" role="status" class="flex items-center gap-2 text-xs text-amber-200">
            <UiIcon name="info" :size="14" />{{ notice }}
          </p>
        </div>

        <DeviceEmptyState
          v-if="!selectedDevice"
          :has-devices="devices.length > 0"
          :scanned="scanned"
        />

        <section v-else aria-labelledby="device-heading" :aria-busy="loadingInfo" class="space-y-6">
          <div
            class="flex flex-wrap items-center gap-4 rounded-lg border border-line bg-raised/35 p-5"
          >
            <div
              class="flex size-12 shrink-0 items-center justify-center rounded-xl border border-accent/15 bg-accent/8 text-accent"
            >
              <AndroidVersionIcon :version="info?.androidVersion" />
            </div>
            <div class="min-w-0 flex-1">
              <h3 id="device-heading" class="break-words text-base font-semibold tracking-tight">
                {{ info?.model ?? selectedDevice.name }}
              </h3>
              <p class="mt-1 break-all font-mono text-[11px] text-muted">
                {{ info?.serial ?? selectedDevice.serial ?? `USB ${selectedDevice.usbLocation}` }}
              </p>
            </div>
            <span class="status-badge" :class="info ? 'text-positive' : 'text-secondary'">
              <span aria-hidden="true" class="size-1.5 rounded-full bg-current"></span>
              {{ info ? 'Connecté' : loadingInfo ? 'Connexion…' : 'Détecté en USB' }}
            </span>
          </div>

          <ErrorNotice v-if="selectedDevice.accessError" :error="selectedDevice.accessError" />
          <div
            v-if="loadingInfo"
            role="status"
            class="rounded-lg border border-line px-6 py-14 text-center"
          >
            <UiIcon name="refresh" :size="22" class="mx-auto mb-4 animate-spin text-accent" />
            <p class="font-medium">Connexion à l’appareil…</p>
            <p class="mx-auto mt-2 max-w-sm text-xs leading-5 text-secondary">
              Acceptez la demande de débogage USB sur votre téléphone. Si l’autorisation expire,
              vous pourrez réessayer.
            </p>
          </div>
          <ErrorNotice v-else-if="infoError" :error="infoError" />
          <DeviceDetails v-else-if="info" :info="info" :device="selectedDevice" />
        </section>

        <footer
          class="mt-auto flex flex-wrap items-center justify-between gap-2 pt-10 text-[11px] text-muted"
        >
          <span class="flex items-center gap-1.5"
            ><UiIcon name="shield" :size="13" /> Communication locale et directe</span
          >
          <span
            >{{ devices.length }} appareil{{ devices.length > 1 ? 's' : '' }} détecté{{
              devices.length > 1 ? 's' : ''
            }}</span
          >
        </footer>
      </div>
    </main>
  </div>
</template>
