<script setup lang="ts">
import { onScopeDispose, ref, watch } from 'vue';
import { AdbError } from '../domain/adb';
import type { ScreenshotService } from '../domain/screenshot';
import AppIcon from '../../../shared/presentation/widgets/AppIcon.vue';

const props = defineProps<{
  deviceId: string;
  deviceName: string;
  connected: boolean;
  demo: boolean;
  service?: ScreenshotService | undefined;
}>();
const image = ref<string | null>(null);
const error = ref<string | null>(null);
const loading = ref(false);
const saving = ref(false);
const saveError = ref<string | null>(null);
const saveMessage = ref<string | null>(null);
let revision = 0;

async function save() {
  if (!image.value || !props.service || saving.value) return;
  const request = revision;
  saving.value = true;
  saveError.value = null;
  saveMessage.value = null;
  try {
    const saved = await props.service.save(image.value, props.deviceId);
    if (request === revision && saved)
      saveMessage.value = props.demo
        ? 'Simulated save. No file was created.'
        : 'Preview saved.';
  } catch (reason) {
    if (request === revision)
      saveError.value =
        reason instanceof AdbError
          ? reason.message
          : 'Unable to save the preview. Please retry.';
  } finally {
    saving.value = false;
  }
}

async function capture() {
  const request = ++revision;
  image.value = null;
  error.value = null;
  saveError.value = null;
  saveMessage.value = null;
  loading.value = false;
  if (!props.connected || !props.service) return;
  loading.value = true;
  try {
    const result = await props.service.capture(props.deviceId);
    if (request === revision) image.value = result;
  } catch (reason) {
    if (request === revision)
      error.value =
        reason instanceof AdbError
          ? reason.message
          : 'Unable to capture the screen. Please retry.';
  } finally {
    if (request === revision) loading.value = false;
  }
}

watch(
  () => [props.deviceId, props.connected, props.service],
  () => void capture(),
  { immediate: true },
);
onScopeDispose(() => {
  revision++;
});
</script>

<template>
  <section
    aria-labelledby="device-preview-title"
    :aria-busy="loading"
    class="device-preview"
  >
    <div class="mb-5 text-center">
      <h3 id="device-preview-title" class="font-semibold">
        {{ demo ? 'Simulated screen preview' : 'Screen preview' }}
      </h3>
      <p class="mt-2 text-xs text-muted">A snapshot of your selected device</p>
    </div>
    <div class="preview-phone">
      <div class="preview-speaker" aria-hidden="true"></div>
      <div class="preview-screen">
        <img
          v-if="image"
          :src="image"
          :alt="`Screen capture of ${deviceName}`"
          class="block h-auto w-full"
          @error="
            image = null;
            error = 'The screen capture could not be displayed. Please retry.';
          "
        />
        <div
          v-else
          class="flex aspect-[9/19.5] flex-col items-center justify-center gap-4 px-6 text-center text-muted"
        >
          <AppIcon name="phone" class="size-10 text-primary" />
          <p role="status" class="text-sm leading-6">
            {{
              loading
                ? 'Capturing screen…'
                : error
                  ? 'Preview unavailable'
                  : connected
                    ? 'Screen preview is unavailable.'
                    : 'Connect through ADB to preview your screen.'
            }}
          </p>
        </div>
      </div>
      <div class="preview-chin" aria-hidden="true"></div>
    </div>
    <p
      v-if="error"
      role="alert"
      class="mt-5 text-center text-xs leading-6 text-warning"
    >
      {{ error }}
    </p>
    <div class="mt-5 text-center">
      <div class="flex flex-wrap justify-center gap-2">
        <button
          type="button"
          class="keystore-button inline-flex items-center gap-2"
          :disabled="loading || !connected || !service"
          @click="capture"
        >
          <AppIcon name="refresh" class="size-4" />{{
            loading ? 'Capturing…' : 'Refresh preview'
          }}
        </button>
        <button
          type="button"
          class="keystore-button inline-flex items-center gap-2"
          :disabled="!image || loading || saving || !service"
          @click="save"
        >
          <AppIcon name="download" class="size-4" />{{
            saving ? 'Saving…' : 'Save preview'
          }}
        </button>
      </div>
      <p
        v-if="saveError"
        role="alert"
        class="mt-3 text-xs leading-5 text-warning"
      >
        {{ saveError }}
      </p>
      <p
        v-if="saveMessage"
        role="status"
        class="mt-3 text-xs leading-5 text-muted"
      >
        {{ saveMessage }}
      </p>
      <p class="mt-3 text-xs leading-5 text-muted">
        {{
          demo
            ? 'Demo illustration. No screen is captured.'
            : 'Still image · Refresh to see screen changes'
        }}
      </p>
    </div>
  </section>
</template>

<style scoped>
.device-preview {
  width: 100%;
  max-width: 320px;
  margin-inline: auto;
}
.preview-phone {
  width: 100%;
  max-width: 264px;
  margin-inline: auto;
  padding: 0 9px;
  border: 1px solid var(--color-muted);
  border-radius: 34px;
  background: var(--color-foreground);
  box-shadow:
    inset 0 0 0 3px var(--color-muted),
    0 16px 28px -16px var(--color-muted);
}
.preview-speaker {
  width: 42px;
  height: 5px;
  margin: 13px auto 12px;
  border-radius: 8px;
  background: var(--color-muted);
}
.preview-screen {
  overflow: hidden;
  border-radius: 20px;
  background: var(--color-surface-raised);
}
.preview-chin {
  height: 19px;
}
@media (min-width: 1024px) {
  .preview-phone {
    max-width: clamp(160px, calc((100dvh - 310px) * 0.46), 264px);
  }
}
</style>
