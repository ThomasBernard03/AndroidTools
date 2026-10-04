<script setup lang="ts">
import { computed, reactive, ref } from 'vue';
import {
  SigningError,
  signedFilename,
  type SigningService,
} from '../domain/signing';
import PasswordField from '../../../shared/presentation/widgets/PasswordField.vue';

const props = defineProps<{
  service?: SigningService | undefined;
  demo?: boolean | undefined;
}>();
const form = reactive({
  apkPath: '',
  keystorePath: '',
  alias: '',
  password: '',
  keyPassword: '',
});
const busy = ref(false);
const browsing = ref(false);
const error = ref('');
const saved = ref('');
const cancelled = ref(false);
const proposedName = computed(() =>
  form.apkPath ? signedFilename(form.apkPath) : 'name-signed.apk',
);

function showError(value: unknown) {
  error.value =
    value instanceof SigningError
      ? value.message
      : 'The operation could not finish. Please retry.';
}
async function browse(kind: 'apkPath' | 'keystorePath') {
  if (!props.service || busy.value || browsing.value) return;
  browsing.value = true;
  error.value = '';
  try {
    const path = await (kind === 'apkPath'
      ? props.service.chooseApk()
      : props.service.chooseKeystore());
    if (path) form[kind] = path;
  } catch (value) {
    showError(value);
  } finally {
    browsing.value = false;
  }
}
async function copy(text: string) {
  if (props.service) await props.service.copy(text);
}
async function submit() {
  if (!props.service || busy.value || browsing.value) return;
  error.value = '';
  saved.value = '';
  cancelled.value = false;
  if (
    !/\.apk$/i.test(form.apkPath) ||
    !form.keystorePath.trim() ||
    !form.alias.trim() ||
    !form.password
  ) {
    error.value =
      'Enter an APK path, a keystore path, a key alias and the keystore password.';
    return;
  }
  busy.value = true;
  try {
    const path = await props.service.signAndSave({ ...form });
    if (path) saved.value = path;
    else cancelled.value = true;
  } catch (value) {
    showError(value);
  } finally {
    busy.value = false;
  }
}
async function reveal() {
  if (!props.service || !saved.value) return;
  try {
    await props.service.reveal(saved.value);
  } catch (value) {
    showError(value);
  }
}
</script>

<template>
  <section
    class="mx-auto max-w-5xl px-6 py-8 lg:px-10"
    aria-labelledby="signing-title"
  >
    <h2 id="signing-title" class="text-2xl font-semibold tracking-tight">
      APK signing
    </h2>
    <p class="mt-2 text-sm text-muted">
      Sign an APK with your keystore, then choose where to save it. No connected
      device is required.
    </p>
    <p
      v-if="demo"
      role="note"
      class="mt-4 rounded-lg border border-warning/30 p-3 text-sm text-warning"
    >
      Demo mode — simulated APK signing and saving. No file is created.
    </p>
    <p v-if="!service" role="alert" class="mt-4 text-sm text-warning">
      APK signing requires the desktop application.
    </p>
    <form class="mt-6 space-y-5" :aria-busy="busy" @submit.prevent="submit">
      <fieldset
        :disabled="busy || browsing || !service"
        class="space-y-5 disabled:opacity-70"
      >
        <section class="keystore-card" aria-labelledby="signing-input-title">
          <h3 id="signing-input-title" class="font-semibold">APK to sign</h3>
          <label for="signing-apk" class="mt-4 mb-2 block text-sm"
            >APK path</label
          >
          <div class="flex gap-2">
            <input
              id="signing-apk"
              v-model="form.apkPath"
              class="keystore-input min-w-0 flex-1"
              placeholder="/path/to/application.apk"
              spellcheck="false"
            />
            <button
              type="button"
              class="keystore-button"
              @click="browse('apkPath')"
            >
              Choose APK
            </button>
          </div>
        </section>
        <section class="keystore-card" aria-labelledby="signing-key-title">
          <h3 id="signing-key-title" class="font-semibold">Signing keystore</h3>
          <p class="mt-2 text-xs text-muted">
            JKS or PKCS12 with an RSA signing key. PKCS12 supports a single key
            and uses the keystore password for both protections.
          </p>
          <label for="signing-keystore" class="mt-4 mb-2 block text-sm"
            >Keystore path</label
          >
          <div class="flex gap-2">
            <input
              id="signing-keystore"
              v-model="form.keystorePath"
              class="keystore-input min-w-0 flex-1"
              placeholder="/path/to/upload.jks"
              spellcheck="false"
            />
            <button
              type="button"
              class="keystore-button"
              @click="browse('keystorePath')"
            >
              Choose keystore
            </button>
          </div>
          <div class="mt-5 grid gap-5 sm:grid-cols-2">
            <div class="sm:col-span-2">
              <label for="signing-alias" class="mb-2 block text-sm"
                >Key alias</label
              >
              <input
                id="signing-alias"
                v-model="form.alias"
                class="keystore-input"
                placeholder="upload"
                spellcheck="false"
                autocomplete="off"
              />
            </div>
            <PasswordField
              id="signing-password"
              v-model="form.password"
              label="Keystore password"
              :copy="copy"
            />
            <PasswordField
              id="signing-key-password"
              v-model="form.keyPassword"
              label="Key password"
              description="Optional. Leave empty to use the keystore password."
              :copy="copy"
            />
          </div>
        </section>
        <div class="keystore-card text-sm text-muted">
          <p>
            APK Signature Scheme v2 · Android 7.0 and later · Local signing
            without Java or Android SDK.
          </p>
          <p class="mt-2">
            After signing, the save dialog proposes
            <strong class="break-all text-foreground">{{ proposedName }}</strong
            >. Choose a new filename; existing files are not replaced.
          </p>
        </div>
        <button
          type="submit"
          class="keystore-button border-primary/30 bg-primary text-on-primary"
        >
          {{ busy ? 'Signing / waiting for save…' : 'Sign APK' }}
        </button>
      </fieldset>
    </form>
    <p v-if="busy" role="status" class="mt-4 text-sm text-muted">
      Signing the APK, then waiting for your save location…
    </p>
    <p v-if="error" role="alert" class="mt-4 text-sm text-danger">
      {{ error }}
    </p>
    <p v-if="cancelled" role="status" class="mt-4 text-sm text-muted">
      Save cancelled. No signed APK was saved. You can sign again to choose a
      destination.
    </p>
    <div v-if="saved" role="status" class="keystore-card mt-5">
      <h3 class="font-semibold text-primary">
        {{ demo ? 'Simulated APK saved' : 'Signed APK saved' }}
      </h3>
      <p class="mt-2 break-all text-sm">{{ saved }}</p>
      <button type="button" class="keystore-button mt-4" @click="reveal">
        Show in folder
      </button>
    </div>
  </section>
</template>
