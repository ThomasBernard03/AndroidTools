import { computed, onScopeDispose, ref, shallowRef, watch } from 'vue';
import type { LogLevel, LogPage, LogcatService } from '../domain/logcat';

/** Only one bounded viewport crosses IPC. The complete capture remains on disk. */
export function useLogcat(props: {
  deviceId: string | null;
  adbConnected: boolean;
  service?: LogcatService | undefined;
}) {
  const page = shallowRef<LogPage>({ start: 0, entries: [] });
  const counts = ref([0, 0, 0, 0, 0, 0]);
  const groupedCounts = ref([0, 0, 0, 0, 0, 0]);
  const grouped = ref(true);
  const packages = ref<string[]>([]);
  const packageName = ref('');
  const minimum = ref<LogLevel>('V');
  const status = ref<'idle' | 'starting' | 'streaming' | 'error'>('idle');
  const error = ref('');
  const packageError = ref('');
  const total = computed(
    () =>
      (grouped.value ? groupedCounts.value : counts.value)[
        'VDIWEF'.indexOf(minimum.value)
      ] ?? 0,
  );
  const offset = ref(0);
  const windowRows = ref(25);
  const follow = ref(true);
  const query = ref('');
  const match = ref<number | null>(null);
  const searchState = ref<'idle' | 'searching' | 'found' | 'missing'>('idle');
  const token = ref<number>();
  let revision = 0;
  let pageRevision = 0;
  let searchRevision = 0;
  let queue = Promise.resolve();
  let disposed = false;
  let pollTimer: ReturnType<typeof setTimeout> | undefined;
  let pageTimer: ReturnType<typeof setTimeout> | undefined;
  let searchTimer: ReturnType<typeof setTimeout> | undefined;
  const message = (value: unknown) =>
    value instanceof Error
      ? value.message
      : 'Logcat failed. Check the device and refresh.';
  const current = (request: number) => !disposed && request === revision;

  async function loadPage() {
    const request = ++pageRevision;
    const capture = token.value;
    if (capture === undefined || !props.service) return;
    try {
      const result = await props.service.page(
        capture,
        minimum.value,
        Math.max(0, offset.value - 20),
        grouped.value,
      );
      if (!disposed && request === pageRevision && capture === token.value)
        page.value = result;
    } catch (cause) {
      if (!disposed && request === pageRevision && capture === token.value)
        error.value = message(cause);
    }
  }
  function schedulePage() {
    pageRevision++;
    clearTimeout(pageTimer);
    pageTimer = setTimeout(() => {
      void loadPage();
    }, 16);
  }
  watch([offset, minimum, grouped, total, token], schedulePage);
  watch([minimum, grouped], () => {
    page.value = { start: 0, entries: [] };
    offset.value = follow.value
      ? Math.max(0, total.value - windowRows.value)
      : 0;
  });
  watch([total, windowRows, follow], () => {
    offset.value = follow.value
      ? Math.max(0, total.value - windowRows.value)
      : Math.min(offset.value, Math.max(0, total.value - windowRows.value));
  });

  async function poll(
    service: LogcatService,
    capture: number,
    request: number,
  ) {
    try {
      const snapshot = await service.read(capture);
      if (!current(request)) return;
      const changed = counts.value[0] !== snapshot.counts[0];
      counts.value = snapshot.counts;
      groupedCounts.value = snapshot.groupedCounts;
      if (changed) schedulePage();
      if (snapshot.error) {
        error.value = snapshot.error.message;
        status.value = 'error';
        return;
      }
      pollTimer = setTimeout(() => {
        void poll(service, capture, request);
      }, 150);
    } catch (cause) {
      if (!current(request)) return;
      error.value = message(cause);
      status.value = 'error';
    }
  }

  async function moveMatch(direction: number, restart = false) {
    clearTimeout(searchTimer);
    const request = ++searchRevision;
    const capture = token.value;
    const service = props.service;
    if (!query.value || capture === undefined || !service) {
      searchState.value = 'idle';
      return;
    }
    follow.value = false;
    searchState.value = 'searching';
    const level = minimum.value;
    const text = query.value;
    const end = total.value;
    const pivot =
      restart || match.value === null
        ? direction < 0
          ? end
          : 0
        : direction < 0
          ? match.value
          : match.value + 1;
    const ranges =
      direction < 0
        ? [
            [0, pivot],
            [pivot, end],
          ]
        : [
            [pivot, end],
            [0, pivot],
          ];
    try {
      for (const range of ranges) {
        let start = range[0]!;
        let until = range[1]!;
        while (start < until) {
          const result = await service.search(capture, {
            minimum: level,
            query: text,
            start,
            end: until,
            backward: direction < 0,
            grouped: grouped.value,
          });
          if (disposed || request !== searchRevision || capture !== token.value)
            return;
          if (result.position !== null) {
            match.value = result.position;
            offset.value = Math.max(
              0,
              Math.min(
                Math.max(0, end - windowRows.value),
                result.position - Math.floor(windowRows.value / 2),
              ),
            );
            searchState.value = 'found';
            schedulePage();
            return;
          }
          if (result.next === null) break;
          if (direction < 0) until = result.next;
          else start = result.next;
        }
      }
      if (!disposed && request === searchRevision) {
        match.value = null;
        searchState.value = 'missing';
      }
    } catch (cause) {
      if (!disposed && request === searchRevision) {
        error.value = message(cause);
        searchState.value = 'idle';
      }
    }
  }
  watch([query, minimum, grouped], () => {
    searchRevision++;
    match.value = null;
    searchState.value = 'idle';
    clearTimeout(searchTimer);
    if (query.value)
      searchTimer = setTimeout(() => {
        void moveMatch(1, true);
      }, 180);
  });

  function refresh(clearDevice = false, release = false) {
    const request = ++revision;
    searchRevision++;
    pageRevision++;
    clearTimeout(pollTimer);
    clearTimeout(searchTimer);
    const id = props.deviceId;
    const service = props.service;
    const selectedPackage = packageName.value.trim();
    error.value = '';
    status.value = id && service && props.adbConnected ? 'starting' : 'idle';
    queue = queue
      .then(async () => {
        if (token.value !== undefined && service) {
          if (release || !id || !props.adbConnected || disposed) {
            await service.stop(token.value);
            token.value = undefined;
          } else await service.pause(token.value);
        }
        if (!current(request) || !id || !service || !props.adbConnected) return;
        if (clearDevice) await service.clear(id);
        if (!current(request)) return;
        const capture = await service.start(id, selectedPackage);
        if (!current(request)) {
          await service.stop(capture);
          return;
        }
        token.value = capture;
        page.value = { start: 0, entries: [] };
        counts.value = [0, 0, 0, 0, 0, 0];
        groupedCounts.value = [0, 0, 0, 0, 0, 0];
        offset.value = 0;
        match.value = null;
        searchState.value = 'idle';
        status.value = 'streaming';
        void poll(service, capture, request);
      })
      .catch((cause: unknown) => {
        if (!current(request)) return;
        error.value = message(cause);
        status.value = 'error';
      });
    return queue;
  }

  let packageRevision = 0;
  async function refreshPackages() {
    const request = ++packageRevision;
    packageError.value = '';
    if (!props.deviceId || !props.service || !props.adbConnected) return;
    try {
      const result = await props.service.packages(props.deviceId);
      if (!disposed && request === packageRevision) packages.value = result;
    } catch (cause) {
      if (!disposed && request === packageRevision)
        packageError.value = message(cause);
    }
  }
  watch(
    () => [props.deviceId, props.adbConnected] as const,
    ([id], previous) => {
      page.value = { start: 0, entries: [] };
      counts.value = [0, 0, 0, 0, 0, 0];
      groupedCounts.value = [0, 0, 0, 0, 0, 0];
      packages.value = [];
      match.value = null;
      searchState.value = 'idle';
      if (id !== previous?.[0]) packageName.value = '';
      void refreshPackages();
      void refresh(false, true);
    },
    { immediate: true },
  );
  onScopeDispose(() => {
    disposed = true;
    revision++;
    pageRevision++;
    searchRevision++;
    packageRevision++;
    clearTimeout(pollTimer);
    clearTimeout(pageTimer);
    clearTimeout(searchTimer);
    void queue
      .then(async () => {
        if (token.value !== undefined) await props.service?.stop(token.value);
      })
      .catch(() => {});
  });
  return {
    page,
    counts,
    grouped,
    total,
    offset,
    windowRows,
    follow,
    query,
    match,
    searchState,
    moveMatch,
    packages,
    packageName,
    minimum,
    status,
    error,
    packageError,
    refresh,
    refreshPackages,
  };
}
