import {
  computed,
  onScopeDispose,
  ref,
  shallowRef,
  watch,
  type Ref,
} from 'vue';
import {
  childPath,
  FileError,
  fileError,
  type FileEntry,
  type FilePreview,
  type FileService,
  type Mutation,
} from '../domain/files';

export function useFiles(deviceId: Ref<string | null>, service?: FileService) {
  const path = ref('/sdcard');
  const entries = shallowRef<FileEntry[]>([]);
  const loading = ref(false);
  const operating = ref(false);
  const error = shallowRef<FileError | null>(null);
  const operationError = shallowRef<FileError | null>(null);
  const message = ref('');
  const preview = shallowRef<FilePreview | null>(null);
  const previewName = ref('');
  const previewLoading = ref(false);
  const previewError = shallowRef<FileError | null>(null);
  let previewGeneration = 0;
  function closePreview() {
    ++previewGeneration;
    preview.value = null;
    previewName.value = '';
    previewLoading.value = false;
    previewError.value = null;
  }
  async function openPreview(entry: FileEntry) {
    if (
      !service ||
      !deviceId.value ||
      loading.value ||
      operating.value ||
      entry.kind !== 'file'
    )
      return;
    closePreview();
    const ticket = previewGeneration;
    previewName.value = entry.name;
    previewLoading.value = true;
    try {
      const result = await service.preview(
        deviceId.value,
        childPath(path.value, entry.name),
      );
      if (ticket === previewGeneration) preview.value = result;
    } catch (cause) {
      if (ticket === previewGeneration) previewError.value = fileError(cause);
    } finally {
      if (ticket === previewGeneration) previewLoading.value = false;
    }
  }
  let generation = 0;
  let disposed = false;
  onScopeDispose(() => {
    disposed = true;
    closePreview();
    ++generation;
  });
  const writable = computed(
    () =>
      !['/data', '/data/data', '/data/user', '/data/user/0'].includes(
        path.value,
      ),
  );
  async function navigate(next = path.value) {
    if (operating.value || disposed) return;
    closePreview();
    const ticket = ++generation;
    const id = deviceId.value;
    path.value = next;
    entries.value = [];
    error.value = null;
    operationError.value = null;
    message.value = '';
    if (!id) {
      loading.value = false;
      return;
    }
    loading.value = true;
    try {
      if (!service)
        throw new FileError(
          'native_required',
          'File browsing requires the desktop application.',
        );
      const listing = await service.list(id, next);
      if (ticket === generation) entries.value = listing.entries;
    } catch (cause) {
      if (ticket === generation) error.value = fileError(cause);
    } finally {
      if (ticket === generation) loading.value = false;
    }
  }
  async function operate(
    action: (id: string, current: string) => Promise<boolean>,
    success: string,
  ) {
    if (
      !deviceId.value ||
      !service ||
      operating.value ||
      loading.value ||
      error.value
    )
      return false;
    const id = deviceId.value;
    const current = path.value;
    closePreview();
    const ticket = generation;
    operating.value = true;
    operationError.value = null;
    message.value = '';
    let done = false;
    let failure: FileError | null = null;
    try {
      done = await action(id, current);
    } catch (cause) {
      failure = fileError(cause);
    } finally {
      operating.value = false;
    }
    if (disposed) return false;
    if (ticket !== generation) {
      await navigate();
      return false;
    }
    if (done || failure?.partial) {
      const refreshTicket = generation + 1;
      await navigate(current);
      if (refreshTicket !== generation) return false;
    }
    operationError.value = failure;
    if (done) message.value = success;
    return done;
  }
  function mutate(operation: Mutation, entry: FileEntry | null, name = '') {
    return operate(
      async (id, current) => {
        await service!.mutate(
          id,
          entry ? childPath(current, entry.name) : current,
          operation,
          name,
        );
        return true;
      },
      operation === 'delete'
        ? 'Entry deleted.'
        : operation === 'rename'
          ? 'Entry renamed.'
          : 'Folder created.',
    );
  }
  function transfer(upload: boolean, directory: boolean, entry?: FileEntry) {
    return operate(
      (id, current) =>
        service!.transfer(
          id,
          entry ? childPath(current, entry.name) : current,
          upload,
          directory,
        ),
      upload ? 'Upload completed.' : 'Download completed.',
    );
  }
  watch(
    deviceId,
    () => {
      closePreview();
      ++generation;
      path.value = '/sdcard';
      entries.value = [];
      error.value = null;
      operationError.value = null;
      message.value = '';
      loading.value = false;
      void navigate();
    },
    { immediate: true },
  );
  return {
    preview,
    previewName,
    previewLoading,
    previewError,
    openPreview,
    closePreview,
    path,
    entries,
    loading,
    operating,
    error,
    operationError,
    message,
    writable,
    navigate,
    mutate,
    transfer,
  };
}
