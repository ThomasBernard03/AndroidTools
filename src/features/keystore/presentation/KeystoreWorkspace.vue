<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue';
import PasswordField from '../../../shared/presentation/widgets/PasswordField.vue';
import SelectField from '../../../shared/presentation/widgets/SelectField.vue';
import {
  expirationDate,
  extension,
  generatePassword,
  KeystoreError,
  validateRequest,
  type GeneratedKeystore,
  type GenerateRequest,
  type KeystoreService,
} from '../domain/keystore';

const props = defineProps<{
  service?: KeystoreService | undefined;
  demo?: boolean;
}>();
const form = reactive<GenerateRequest>({
  path: '',
  format: 'JKS',
  password: '',
  keyPassword: '',
  alias: 'upload',
  validityYears: 30,
  commonName: '',
  organizationalUnit: '',
  organization: '',
  locality: '',
  state: '',
  country: '',
});
const confirmation = ref('');
const keyConfirmation = ref('');
const samePassword = ref(true);
const busy = ref(false);
const browsing = ref(false);
const errors = ref<Record<string, string>>({});
const message = ref('');
const result = ref<GeneratedKeystore | null>(null);
const feedback = ref('');
const expiry = computed(() => expirationDate(form.validityYears));
const identityFields = [
  {
    key: 'commonName',
    label: 'Name / Common name (CN)',
    placeholder: 'Example App Signing',
  },
  {
    key: 'organizationalUnit',
    label: 'Organizational unit (OU)',
    placeholder: 'Mobile Development',
  },
  {
    key: 'organization',
    label: 'Organization (O)',
    placeholder: 'Example Studio',
  },
  { key: 'locality', label: 'City / Locality (L)', placeholder: 'Paris' },
  {
    key: 'state',
    label: 'State / Province (ST)',
    placeholder: 'Île-de-France',
  },
  { key: 'country', label: 'Country code (C)', placeholder: 'FR' },
] as const;

watch(
  () => form.format,
  (format) => {
    if (form.path)
      form.path = form.path.replace(/\.(jks|p12)$/i, `.${extension(format)}`);
    if (format === 'PKCS12') samePassword.value = true;
  },
);
watch(samePassword, () => {
  form.keyPassword = '';
  keyConfirmation.value = '';
});
watch(
  () => form.keyPassword,
  (password) => {
    if (!password) keyConfirmation.value = '';
  },
);
// Only the result of the last submission is shown, never attributed to edited fields.
watch(form, () => {
  result.value = null;
  feedback.value = '';
});

async function copy(text: string) {
  if (!props.service) throw new Error('Desktop application required.');
  await props.service.copy(text);
}
function generateSecret(key = false) {
  try {
    const value = generatePassword();
    if (key) {
      form.keyPassword = value;
      keyConfirmation.value = value;
    } else {
      form.password = value;
      confirmation.value = value;
    }
  } catch {
    message.value =
      'Secure password generation is unavailable. Please enter a password.';
  }
}
function showError(error: unknown) {
  message.value =
    error instanceof Error
      ? error.message
      : 'The operation failed. Please retry.';
  if (error instanceof KeystoreError && error.field)
    errors.value[error.field] = error.message;
}
async function browse() {
  if (!props.service || browsing.value || busy.value) return;
  browsing.value = true;
  message.value = '';
  try {
    const path = await props.service.choosePath(form.format);
    if (path)
      form.path = /\.[^/\\]+$/.test(path)
        ? path
        : `${path}.${extension(form.format)}`;
  } catch (error) {
    showError(error);
  } finally {
    browsing.value = false;
  }
}
async function submit() {
  if (!props.service || busy.value || browsing.value) return;
  message.value = '';
  result.value = null;
  const request = {
    ...form,
    country: form.country.trim().toUpperCase(),
    keyPassword:
      samePassword.value || !form.keyPassword
        ? form.password
        : form.keyPassword,
  };
  errors.value = validateRequest(request);
  if (confirmation.value !== form.password)
    errors.value.confirmation = 'Passwords do not match.';
  if (
    !samePassword.value &&
    form.keyPassword &&
    keyConfirmation.value !== form.keyPassword
  )
    errors.value.keyConfirmation = 'Passwords do not match.';
  if (Object.keys(errors.value).length) return;
  busy.value = true;
  try {
    result.value = await props.service.generate(request);
  } catch (error) {
    showError(error);
  } finally {
    busy.value = false;
  }
}
async function copyFingerprint(value: string, label: string) {
  feedback.value = '';
  try {
    await copy(value);
    feedback.value = `${label} copied`;
  } catch (error) {
    showError(error);
  }
}
async function reveal() {
  if (!result.value || !props.service) return;
  try {
    await props.service.reveal(result.value.path);
  } catch (error) {
    showError(error);
  }
}
</script>

<template>
  <section
    class="mx-auto max-w-5xl px-6 py-8 lg:px-10"
    aria-labelledby="keystore-title"
  >
    <h2 id="keystore-title" class="text-2xl font-semibold tracking-tight">
      Generate keystore
    </h2>
    <p class="mt-2 text-sm text-muted">
      Create a keystore and signing key for your Android applications. No
      connected device is required.
    </p>
    <p
      v-if="demo"
      role="note"
      class="mt-4 rounded-lg border border-warning/30 p-3 text-sm text-warning"
    >
      Demo mode — simulated keystore generation. No key or file is created.
    </p>
    <p v-if="!service" role="alert" class="mt-4 text-sm text-warning">
      Keystore generation requires the desktop application.
    </p>
    <form
      class="mt-6 space-y-5"
      novalidate
      :aria-busy="busy"
      @submit.prevent="submit"
    >
      <fieldset
        :disabled="busy || browsing || !service"
        class="space-y-5 disabled:opacity-70"
      >
        <section class="keystore-card" aria-labelledby="store-title">
          <h3 id="store-title" class="font-semibold">Keystore</h3>
          <div class="mt-4 grid gap-5 sm:grid-cols-2">
            <div class="sm:col-span-2">
              <label for="keystore-path" class="mb-2 block text-sm"
                >Save location</label
              >
              <div class="flex gap-2">
                <input
                  id="keystore-path"
                  v-model="form.path"
                  class="keystore-input min-w-0 flex-1"
                  :placeholder="`/path/to/upload.${extension(form.format)}`"
                  :aria-invalid="!!errors.path"
                  :aria-describedby="errors.path ? 'path-error' : undefined"
                /><button type="button" class="keystore-button" @click="browse">
                  {{ browsing ? 'Choosing…' : 'Browse…' }}
                </button>
              </div>
              <p
                v-if="errors.path"
                id="path-error"
                class="mt-1 text-xs text-danger"
              >
                {{ errors.path }}
              </p>
            </div>
            <SelectField
              id="keystore-format"
              v-model="form.format"
              label="Keystore format"
              :disabled="busy || browsing || !service"
              :options="[
                {
                  value: 'JKS',
                  label: 'JKS',
                  description: 'Java KeyStore · .jks',
                },
                {
                  value: 'PKCS12',
                  label: 'PKCS12',
                  description: 'Standard format · .p12',
                },
              ]"
            />
            <p class="self-center text-xs leading-relaxed text-muted">
              Creates a new file with one RSA 2048-bit key and a SHA256withRSA
              self-signed certificate.
            </p>
            <PasswordField
              id="store-password"
              v-model="form.password"
              label="Keystore password"
              :error="errors.password"
              :copy="copy"
              can-generate
              @generate="generateSecret()"
            />
            <PasswordField
              id="store-confirmation"
              v-model="confirmation"
              label="Confirm password"
              :error="errors.confirmation"
              :copy="copy"
            />
          </div>
          <p class="mt-3 text-xs text-muted">
            Use 6–128 printable ASCII characters for Java/Android compatibility.
            Generate creates a secure 24-character password and fills its
            confirmation.
          </p>
        </section>
        <section class="keystore-card" aria-labelledby="key-title">
          <h3 id="key-title" class="font-semibold">Signing key</h3>
          <div class="mt-4 grid gap-5 sm:grid-cols-2">
            <div>
              <label for="key-alias" class="mb-2 block text-sm">Key alias</label
              ><input
                id="key-alias"
                v-model="form.alias"
                class="keystore-input"
                :aria-invalid="!!errors.alias"
                :aria-describedby="errors.alias ? 'alias-error' : undefined"
              />
              <p
                v-if="errors.alias"
                id="alias-error"
                class="mt-1 text-xs text-danger"
              >
                {{ errors.alias }}
              </p>
            </div>
            <div>
              <label for="key-validity" class="mb-2 block text-sm"
                >Validity (years)</label
              ><input
                id="key-validity"
                v-model.number="form.validityYears"
                type="number"
                min="1"
                max="100"
                step="1"
                class="keystore-input"
                :aria-invalid="!!errors.validityYears"
                aria-describedby="validity-description"
              />
              <p
                id="validity-description"
                class="mt-1 text-xs"
                :class="errors.validityYears ? 'text-danger' : 'text-muted'"
              >
                {{
                  errors.validityYears ||
                  (expiry
                    ? `Expires on ${expiry} (UTC)`
                    : 'Choose 1–100 years.')
                }}
              </p>
            </div>
            <div class="sm:col-span-2">
              <label class="flex items-center gap-2 text-sm"
                ><input
                  v-model="samePassword"
                  type="checkbox"
                  :disabled="form.format === 'PKCS12'"
                  class="accent-primary"
                />Use keystore password</label
              >
              <p
                v-if="form.format === 'PKCS12'"
                class="mt-2 text-xs text-muted"
              >
                PKCS12 uses the same password for the keystore and key.
              </p>
              <p v-else class="mt-2 text-xs text-muted">
                The key uses the keystore password unless you provide a separate
                one.
              </p>
            </div>
            <template v-if="!samePassword">
              <PasswordField
                id="key-password"
                v-model="form.keyPassword"
                label="Key password"
                description="Optional. Leave empty to use the keystore password."
                :error="errors.keyPassword"
                :copy="copy"
                can-generate
                @generate="generateSecret(true)"
              />
              <PasswordField
                id="key-confirmation"
                v-model="keyConfirmation"
                label="Confirm key password"
                :error="errors.keyConfirmation"
                :copy="copy"
              />
            </template>
          </div>
        </section>
        <section class="keystore-card" aria-labelledby="identity-title">
          <h3 id="identity-title" class="font-semibold">
            Certificate identity
          </h3>
          <p class="mt-2 text-xs text-muted">
            These details are visible in signed applications. Only the common
            name is required.
          </p>
          <div class="mt-4 grid gap-5 sm:grid-cols-2">
            <div v-for="field in identityFields" :key="field.key">
              <label :for="`identity-${field.key}`" class="mb-2 block text-sm"
                >{{ field.label
                }}<span v-if="field.key !== 'commonName'" class="text-muted">
                  · Optional</span
                ></label
              ><input
                :id="`identity-${field.key}`"
                v-model="form[field.key]"
                :placeholder="field.placeholder"
                class="keystore-input"
                :aria-invalid="!!errors[field.key]"
                :aria-describedby="
                  errors[field.key] ? `${field.key}-error` : undefined
                "
              />
              <p
                v-if="errors[field.key]"
                :id="`${field.key}-error`"
                class="mt-1 text-xs text-danger"
              >
                {{ errors[field.key] }}
              </p>
            </div>
          </div>
        </section>
        <button
          type="submit"
          class="rounded-lg bg-primary px-5 py-3 text-sm font-semibold text-on-primary disabled:opacity-50"
        >
          {{ busy ? 'Generating keystore…' : 'Generate keystore' }}
        </button>
      </fieldset>
      <p v-if="message" role="alert" class="text-sm text-danger">
        {{ message }}
      </p>
    </form>
    <section
      v-if="result"
      class="keystore-card mt-6 border-primary/40"
      aria-labelledby="result-title"
      aria-live="polite"
    >
      <h3 id="result-title" class="font-semibold text-primary">
        {{
          demo
            ? 'Simulated keystore generated'
            : 'Keystore generated successfully'
        }}
      </h3>
      <dl class="mt-4 space-y-3 text-sm">
        <div>
          <dt class="text-muted">File</dt>
          <dd class="break-all">{{ result.path }}</dd>
        </div>
        <div>
          <dt class="text-muted">Format / Alias / Expiration</dt>
          <dd>
            {{ result.format }} / {{ result.alias }} / {{ result.expiresAt }}
          </dd>
        </div>
        <div
          v-for="item in [
            { label: 'SHA-1', value: result.sha1 },
            { label: 'SHA-256', value: result.sha256 },
          ]"
          :key="item.label"
        >
          <dt class="text-muted">{{ item.label }}</dt>
          <dd class="mt-1 flex items-start gap-3">
            <code class="min-w-0 flex-1 break-all text-xs">{{
              item.value
            }}</code
            ><button
              type="button"
              class="keystore-button"
              :aria-label="`Copy ${item.label}`"
              @click="copyFingerprint(item.value, item.label)"
            >
              Copy
            </button>
          </dd>
        </div>
      </dl>
      <p v-if="feedback" role="status" class="mt-3 text-xs text-primary">
        {{ feedback }}
      </p>
      <p class="mt-4 text-sm text-warning">
        Back up your keystore and passwords. You will need them to sign future
        updates with this key.
      </p>
      <button
        type="button"
        class="keystore-button mt-4"
        :disabled="demo"
        @click="reveal"
      >
        Show in folder
      </button>
    </section>
  </section>
</template>
