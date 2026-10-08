<script setup lang="ts">
import FileWorkspace from './features/files/presentation/FileWorkspace.vue';
import type { FileService } from './features/files/domain/files';
import DevicePicker from './features/devices/presentation/DevicePicker.vue';
import SettingsWorkspace from './features/settings/presentation/SettingsWorkspace.vue';
import type { SettingsService } from './features/settings/domain/settings';
import ApkWorkspace from './features/apk/presentation/ApkWorkspace.vue';
import type { ApkService } from './features/apk/domain/apk';
import KeystoreWorkspace from './features/keystore/presentation/KeystoreWorkspace.vue';
import KeystoreExplorerWorkspace from './features/keystore/presentation/KeystoreExplorerWorkspace.vue';
import type { KeystoreExplorerService } from './features/keystore/domain/explorer';
import SigningWorkspace from './features/signing/presentation/SigningWorkspace.vue';
import type { SigningService } from './features/signing/domain/signing';
import type { KeystoreService } from './features/keystore/domain/keystore';
import type { DeviceService } from './features/devices/domain/devices';
import type { DeviceSummary } from './features/devices/domain/devices';
import { shallowRef } from 'vue';
import DeviceWorkspace from './features/devices/presentation/DeviceWorkspace.vue';
import DeviceStatusBar from './features/devices/presentation/DeviceStatusBar.vue';
import type { AdbService } from './features/adb/domain/adb';
import type { ScreenshotService } from './features/adb/domain/screenshot';
import { useAdb } from './features/adb/presentation/useAdb';
import WorkspaceNavigation from './shared/presentation/widgets/WorkspaceNavigation.vue';
import ComingSoonWorkspace from './shared/presentation/widgets/ComingSoonWorkspace.vue';
import AppIcon from './shared/presentation/widgets/AppIcon.vue';
import {
  workspacePages,
  type WorkspacePage,
} from './shared/presentation/workspaceNavigation';

const currentPage = shallowRef<WorkspacePage>(workspacePages[0]);

const props = defineProps<{
  deviceService: DeviceService;
  adbService?: AdbService;
  screenshotService?: ScreenshotService;
  keystoreService?: KeystoreService;
  keystoreExplorerService?: KeystoreExplorerService;
  apkService?: ApkService;
  signingService?: SigningService;
  settingsService?: SettingsService;
  fileService?: FileService;
  demo?: boolean;
  macosWindowControls?: boolean;
}>();
const selectedDevice = shallowRef<DeviceSummary | null>(null);
const { state: adbState, refresh: refreshAdb } = useAdb(
  selectedDevice,
  props.adbService,
);
</script>

<template>
  <div class="xp-shell flex h-dvh flex-col overflow-hidden">
    <header
      class="xp-titlebar"
      :class="{ 'xp-titlebar-macos': macosWindowControls }"
      data-tauri-drag-region
    >
      <h1>Android Tools</h1>
      <span class="xp-titlebar-label">{{ currentPage.label }}</span>
    </header>
    <div
      class="min-h-0 flex-1 overflow-y-auto md:grid md:grid-cols-[256px_minmax(0,1fr)]"
    >
      <a
        href="#workspace"
        class="sr-only z-20 rounded-lg bg-primary px-4 py-2 text-on-primary focus:not-sr-only focus:fixed focus:left-4 focus:top-4"
        >Skip to workspace</a
      >
      <aside
        aria-label="Device sidebar"
        class="xp-sidebar flex flex-col border-b border-stroke bg-sidebar py-4 md:overflow-y-auto md:border-r md:border-b-0"
      >
        <div class="px-3">
          <DevicePicker
            :service="deviceService"
            @selection-change="selectedDevice = $event"
          />
        </div>

        <footer v-if="demo" class="px-5 pt-4">
          <p
            v-if="demo"
            role="note"
            class="mb-4 rounded-lg border border-warning/20 bg-warning/5 p-3 text-xs leading-relaxed text-warning"
          >
            Demo mode — simulated devices. No USB connection is used.
          </p>
        </footer>
        <WorkspaceNavigation
          :current="currentPage.id"
          @navigate="currentPage = $event"
        />
      </aside>

      <main
        id="workspace"
        tabindex="-1"
        class="workspace-background min-w-0 md:overflow-y-auto"
      >
        <header class="xp-locationbar border-b border-stroke px-4 py-2.5">
          <AppIcon
            :name="currentPage.icon"
            class="size-5 shrink-0 text-primary"
          />
          <p class="text-sm">
            <span class="text-muted">{{ currentPage.group }}</span
            ><span class="mx-2 text-muted" aria-hidden="true">›</span
            >{{ currentPage.label }}
          </p>
        </header>
        <DeviceWorkspace
          v-if="currentPage.id === 'overview'"
          :device="selectedDevice"
          :demo="demo ?? false"
          :adb-state="adbService ? adbState : undefined"
          :screenshot-service="screenshotService"
          @refresh-adb="refreshAdb"
        />
        <KeepAlive>
          <ApkWorkspace
            v-if="currentPage.id === 'apk-analysis'"
            :service="apkService"
            :demo="demo"
            :device-id="selectedDevice?.id ?? null"
            :adb-connected="adbState.status === 'connected'"
          />
        </KeepAlive>
        <KeepAlive>
          <KeystoreWorkspace
            v-if="currentPage.id === 'generate-keystore'"
            :service="keystoreService"
            :demo="demo"
          />
        </KeepAlive>
        <KeepAlive>
          <SigningWorkspace
            v-if="currentPage.id === 'apk-signing'"
            :service="signingService"
            :demo="demo"
          />
        </KeepAlive>
        <KeepAlive>
          <KeystoreExplorerWorkspace
            v-if="currentPage.id === 'keystore-explorer'"
            :service="keystoreExplorerService"
            :demo="demo"
          />
        </KeepAlive>
        <KeepAlive>
          <FileWorkspace
            v-if="currentPage.id === 'files'"
            :device-id="selectedDevice?.id ?? null"
            :service="fileService"
            :demo="demo"
          />
        </KeepAlive>
        <ComingSoonWorkspace
          v-if="
            currentPage.id !== 'overview' &&
            currentPage.id !== 'files' &&
            currentPage.id !== 'apk-analysis' &&
            currentPage.id !== 'generate-keystore' &&
            currentPage.id !== 'keystore-explorer' &&
            currentPage.id !== 'apk-signing' &&
            currentPage.id !== 'settings'
          "
          :page="currentPage"
        />
        <SettingsWorkspace
          v-if="currentPage.id === 'settings'"
          :service="settingsService"
          :demo="demo"
        />
      </main>
    </div>
    <DeviceStatusBar
      :device="selectedDevice"
      :demo="demo ?? false"
      :adb-status="adbState.status"
    />
  </div>
</template>
