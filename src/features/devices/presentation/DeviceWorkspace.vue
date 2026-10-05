<script setup lang="ts">
import type { DeviceSummary } from '../domain/devices';
import AppIcon from '../../../shared/presentation/widgets/AppIcon.vue';
import type { AdbState } from '../../adb/domain/adb';
import AndroidInformation from '../../adb/presentation/AndroidInformation.vue';

defineProps<{
  device: DeviceSummary | null;
  demo: boolean;
  adbState?: AdbState | undefined;
}>();
defineEmits<{ 'refresh-adb': [] }>();

function usbId(value: number): string {
  return `0x${value.toString(16).padStart(4, '0').toUpperCase()}`;
}
</script>

<template>
  <div class="mx-auto max-w-5xl px-6 py-10 lg:px-10 lg:py-14">
    <p class="text-xs font-semibold tracking-[0.18em] text-primary uppercase">
      {{ device ? 'Device overview' : 'Let’s get connected' }}
    </p>
    <h2 class="mt-3 text-3xl font-semibold tracking-tight lg:text-4xl">
      {{ device ? device.name : 'Your Android workspace.' }}
    </h2>
    <p class="mt-4 max-w-xl text-sm leading-7 text-muted">
      {{
        device
          ? 'Your device is selected. Here is what we know about this USB connection.'
          : 'A focused space for your Android devices. Connect a phone and choose it from the sidebar to get started.'
      }}
    </p>

    <section
      v-if="device"
      aria-label="Device connection details"
      class="mt-10 overflow-hidden rounded-2xl border border-stroke bg-surface"
    >
      <div class="flex items-center gap-4 border-b border-stroke p-6">
        <div
          class="flex size-12 shrink-0 items-center justify-center rounded-xl bg-primary-muted text-primary"
        >
          <AppIcon name="phone" class="size-7" />
        </div>
        <div class="min-w-0">
          <h3 class="font-medium">
            {{ demo ? 'Simulated USB device' : 'USB device' }}
          </h3>
          <p class="mt-1 text-sm text-muted">Selected for this session</p>
        </div>
      </div>
      <dl class="grid gap-6 p-6 xl:grid-cols-2">
        <div>
          <dt class="text-xs text-muted">Manufacturer</dt>
          <dd class="mt-2 break-words text-sm">
            {{ device.manufacturer ?? 'Unavailable' }}
          </dd>
        </div>
        <div>
          <dt class="text-xs text-muted">USB product</dt>
          <dd class="mt-2 break-words text-sm">
            {{ device.product ?? 'Unavailable' }}
          </dd>
        </div>
        <div>
          <dt class="text-xs text-muted">Serial number</dt>
          <dd class="mt-2 break-all font-mono text-sm">
            {{ device.serial ?? 'Unavailable' }}
          </dd>
        </div>
        <div>
          <dt class="text-xs text-muted">Connection ID</dt>
          <dd class="mt-2 break-all font-mono text-sm">{{ device.id }}</dd>
        </div>
        <div>
          <dt class="text-xs text-muted">USB vendor ID</dt>
          <dd class="mt-2 font-mono text-sm">{{ usbId(device.vendorId) }}</dd>
        </div>
        <div>
          <dt class="text-xs text-muted">USB product ID</dt>
          <dd class="mt-2 font-mono text-sm">{{ usbId(device.productId) }}</dd>
        </div>
      </dl>
      <div
        class="border-t border-stroke px-6 py-4 text-sm leading-6 text-muted"
      >
        These details come from USB descriptors. Android system information is
        read separately through an authorized ADB connection.
      </div>
      <p
        v-if="device.warning"
        class="border-t border-warning/20 bg-warning/5 px-6 py-4 text-sm leading-6 text-warning"
      >
        {{ device.warning }}
      </p>
    </section>

    <section
      v-else
      aria-label="Getting started"
      class="mt-10 rounded-2xl border border-stroke bg-surface/70 p-6 sm:p-10"
    >
      <div
        class="flex size-16 items-center justify-center rounded-2xl border border-primary/20 bg-primary-muted text-primary"
      >
        <AppIcon name="phone" class="size-9" />
      </div>
      <h3 class="mt-6 text-xl font-medium">Start with a device</h3>
      <p class="mt-2 max-w-lg text-sm leading-7 text-muted">
        {{
          demo
            ? 'You’re exploring the demo. Choose a simulated device from the sidebar to see its connection details.'
            : 'Enable USB debugging on your phone, connect a data cable, then refresh the device list in the sidebar.'
        }}
      </p>
      <ol class="mt-8 grid gap-5 border-t border-stroke pt-6 xl:grid-cols-3">
        <li
          v-for="(step, index) in [
            'Enable USB debugging',
            'Connect your phone',
            'Choose your device',
          ]"
          :key="step"
          class="flex items-center gap-3 text-sm text-muted"
        >
          <span
            class="flex size-7 shrink-0 items-center justify-center rounded-full border border-stroke bg-surface-raised font-mono text-xs text-primary"
            >{{ index + 1 }}</span
          >{{ step }}
        </li>
      </ol>
    </section>
    <AndroidInformation
      v-if="device && adbState"
      :state="adbState"
      :demo="demo"
      @refresh="$emit('refresh-adb')"
    />
    <p class="mt-6 flex items-start gap-2 text-xs leading-6 text-muted">
      <AppIcon name="usb" class="mt-1 size-4 shrink-0" />{{
        demo
          ? 'Demo data only. No phone or USB connection is required.'
          : 'Direct USB discovery. No Android SDK required. Refresh the list after connecting or disconnecting a device.'
      }}
    </p>
  </div>
</template>
