<script setup lang="ts">
import { reactive, ref, watch } from 'vue';
import {
  ExplorerError,
  type KeystoreExplorerService,
  type KeystoreReport,
} from '../domain/explorer';
import PasswordField from '../../../shared/presentation/widgets/PasswordField.vue';

const props = defineProps<{
  service?: KeystoreExplorerService | undefined;
  demo?: boolean | undefined;
}>();
const form = reactive({
  path: '',
  password: '',
  keyAlias: '',
  keyPassword: '',
});
const busy = ref(false);
const error = ref('');
const report = ref<KeystoreReport | null>(null);
let revision = 0;
watch(
  () => [form.path, form.password],
  () => {
    revision++;
    report.value = null;
    error.value = '';
    form.keyAlias = '';
    form.keyPassword = '';
  },
  { flush: 'sync' },
);
watch(
  () => [form.keyAlias, form.keyPassword],
  () => {
    revision++;
    report.value?.entries.forEach((entry) => {
      if (entry.kind === 'private_key' && report.value?.format === 'jks')
        entry.keyStatus = 'not_checked';
    });
  },
  { flush: 'sync' },
);
function showError(value: unknown) {
  error.value =
    value instanceof ExplorerError
      ? value.message
      : 'The keystore operation could not finish. Please retry.';
}
async function browse() {
  if (!props.service || busy.value) return;
  busy.value = true;
  error.value = '';
  try {
    const path = await props.service.choose();
    if (path) form.path = path;
  } catch (value) {
    showError(value);
  } finally {
    busy.value = false;
  }
}
async function inspect(verify = false) {
  if (!props.service || busy.value) return;
  error.value = '';
  if (!form.path.trim()) {
    error.value = 'Choose a keystore file.';
    return;
  }
  const input = {
    ...form,
    keyAlias: verify ? form.keyAlias : null,
    keyPassword: verify ? form.keyPassword : '',
  };
  const current = ++revision;
  report.value = null;
  busy.value = true;
  try {
    const value = await props.service.inspect(input);
    if (current === revision) report.value = value;
  } catch (value) {
    if (current === revision) showError(value);
  } finally {
    busy.value = false;
  }
}
async function copy(text: string) {
  await props.service?.copy(text);
}
const kinds = {
  private_key: 'Private key',
  trusted_certificate: 'Trusted certificate',
  certificate: 'Additional certificate',
};
const statuses = {
  not_checked: 'Key password not checked',
  not_applicable: 'No private key',
  verified: 'Key unlocked — certificate matches',
  failed:
    'Key verification failed — check the key password; the key may be damaged or may not match its certificate.',
};
</script>

<template>
  <section
    class="mx-auto max-w-5xl px-6 py-8 lg:px-10"
    aria-labelledby="explorer-title"
  >
    <h2 id="explorer-title" class="text-2xl font-semibold tracking-tight">
      Keystore explorer
    </h2>
    <p class="mt-2 text-sm text-muted">
      Read aliases and certificates, verify store integrity and check signing
      credentials locally.
    </p>
    <p v-if="demo" role="note" class="mt-4 text-sm text-warning">
      Demo mode — simulated keystore. Use demo-password for both passwords. No
      file is read.
    </p>
    <p v-if="!service" role="alert" class="mt-4 text-warning">
      Keystore exploration requires the desktop application.
    </p>
    <form class="mt-6" :aria-busy="busy" @submit.prevent="inspect()">
      <fieldset
        class="keystore-card space-y-4 disabled:opacity-70"
        :disabled="busy || !service"
      >
        <div>
          <label for="explorer-path" class="mb-2 block text-sm"
            >Keystore path</label
          >
          <div class="flex gap-2">
            <input
              id="explorer-path"
              v-model="form.path"
              class="keystore-input min-w-0 flex-1"
              spellcheck="false"
              placeholder="/path/to/upload.jks"
            />
            <button type="button" class="keystore-button" @click="browse">
              Choose keystore
            </button>
          </div>
        </div>
        <PasswordField
          id="explorer-password"
          v-model="form.password"
          label="Keystore password"
          :copy="copy"
        />
        <p class="text-xs text-muted">
          JKS or PKCS12, up to 16 MiB. Leave the password empty only for a store
          with an empty password. A failed integrity check can mean an incorrect
          password or a damaged file.
        </p>
        <button type="submit" class="keystore-button">
          {{ busy ? 'Reading keystore…' : 'Explore keystore' }}
        </button>
      </fieldset>
    </form>
    <p v-if="error" role="alert" class="mt-4 text-sm text-danger">
      {{ error }}
    </p>
    <div v-if="report" class="mt-6 space-y-4">
      <p role="status" class="text-sm text-primary">
        {{ report.format.toUpperCase() }} —
        {{
          report.format === 'jks'
            ? 'store password and integrity verified.'
            : 'store opened successfully.'
        }}
        {{ report.entries.length }} entries shown.
      </p>
      <p class="text-xs text-muted">
        This verifies readable contents and password protection, not certificate
        trust, validity dates or suitability for an app update.
      </p>
      <p v-if="report.limitation" role="note" class="text-sm text-warning">
        {{ report.limitation }}
      </p>
      <p v-if="!report.entries.length" class="text-sm text-muted">
        No entries found.
      </p>
      <form
        v-if="
          report.format === 'jks' &&
          report.entries.some((e) => e.kind === 'private_key')
        "
        class="keystore-card"
        @submit.prevent="inspect(true)"
      >
        <fieldset :disabled="busy" class="space-y-4">
          <h3 class="font-semibold">Verify key credentials</h3>
          <div>
            <label for="explorer-alias" class="mb-2 block text-sm"
              >Key alias</label
            >
            <select
              id="explorer-alias"
              v-model="form.keyAlias"
              class="keystore-input"
              required
            >
              <option value="" disabled>Select an alias</option>
              <option
                v-for="entry in report.entries.filter(
                  (e) => e.kind === 'private_key',
                )"
                :key="entry.alias!"
                :value="entry.alias"
              >
                {{ entry.alias }}
              </option>
            </select>
          </div>
          <PasswordField
            id="explorer-key-password"
            v-model="form.keyPassword"
            label="Key password"
            description="Leave empty to use the keystore password."
            :copy="copy"
          />
          <button
            type="submit"
            class="keystore-button"
            :disabled="!form.keyAlias"
          >
            Verify key
          </button>
        </fieldset>
      </form>
      <article
        v-for="(entry, index) in report.entries"
        :key="index"
        class="keystore-card space-y-3"
      >
        <h3 class="font-semibold break-all">
          {{ entry.alias ?? 'No alias available' }}
        </h3>
        <p class="text-sm text-muted">{{ kinds[entry.kind] }}</p>
        <p
          :role="entry.keyStatus === 'failed' ? 'alert' : 'status'"
          class="text-sm"
          :class="entry.keyStatus === 'failed' ? 'text-warning' : 'text-muted'"
        >
          {{ statuses[entry.keyStatus] }}
        </p>
        <p v-if="!entry.certificates.length" class="text-sm text-warning">
          No certificate chain available.
        </p>
        <details
          v-for="(cert, certIndex) in entry.certificates"
          :key="certIndex"
          :open="certIndex === 0"
          class="rounded-lg border border-stroke p-3"
        >
          <summary class="cursor-pointer text-sm font-medium">
            Certificate {{ certIndex + 1 }}
          </summary>
          <dl
            class="mt-3 grid gap-2 text-xs sm:grid-cols-[100px_minmax(0,1fr)]"
          >
            <template
              v-for="(value, label) in {
                Subject: cert.subject,
                Issuer: cert.issuer,
                Serial: cert.serial,
                'Valid from': cert.validFrom,
                'Valid until': cert.validUntil,
                'SHA-1': cert.sha1,
                'SHA-256': cert.sha256,
              }"
              :key="label"
            >
              <dt class="text-muted">{{ label }}</dt>
              <dd class="break-all select-text">{{ value }}</dd>
            </template>
          </dl>
        </details>
      </article>
    </div>
  </section>
</template>
