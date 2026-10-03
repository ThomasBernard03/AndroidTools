import { onScopeDispose, ref, watch, type Ref } from 'vue';
import type { DeviceSummary } from '../../devices/domain/devices';
import { AdbError, type AdbService, type AdbState } from '../domain/adb';

/** Serialize native session changes and discard responses for an obsolete selection. */
export function useAdb(
  device: Ref<DeviceSummary | null>,
  service?: AdbService,
) {
  const state = ref<AdbState>({ status: 'idle', info: null, error: null });
  let revision = 0;
  let queue = Promise.resolve();
  let disposed = false;

  function refresh() {
    const id = device.value?.id;
    const request = ++revision;
    state.value = {
      status: id && service ? 'connecting' : 'idle',
      info: null,
      error: null,
    };
    if (!service) return Promise.resolve();
    queue = queue.then(async () => {
      if (disposed || request !== revision) return;
      try {
        if (!id) {
          await service.disconnect();
          return;
        }
        const info = await service.read(id);
        if (disposed || request !== revision) return;
        state.value = { status: 'connected', info, error: null };
      } catch (error) {
        if (disposed || request !== revision) return;
        const code = error instanceof AdbError ? error.code : 'unavailable';
        state.value = {
          status:
            code === 'unauthorized'
              ? 'unauthorized'
              : code === 'disconnected'
                ? 'disconnected'
                : 'error',
          info: null,
          error:
            error instanceof AdbError
              ? error.message
              : 'Unable to read Android information. Please retry.',
        };
      }
    });
    return queue;
  }

  watch(
    device,
    () => {
      void refresh();
    },
    { immediate: true },
  );
  onScopeDispose(() => {
    disposed = true;
    revision++;
    // In-flight calls are bounded natively; release their session after completion.
    if (service) void queue.then(() => service.disconnect()).catch(() => {});
  });
  return { state, refresh };
}
