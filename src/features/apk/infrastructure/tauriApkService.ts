import { invoke } from '@tauri-apps/api/core';
import { getCurrentWebview } from '@tauri-apps/api/webview';
import { ApkError, type ApkReport, type ApkService } from '../domain/apk';

type Invoke = (
  command: string,
  args?: Record<string, unknown>,
) => Promise<unknown>;
const record = (v: unknown): v is Record<string, unknown> =>
  typeof v === 'object' && v !== null;
const size = (v: unknown): v is number =>
  typeof v === 'number' && Number.isSafeInteger(v) && v >= 0;
const icon = (v: unknown): boolean =>
  v === null ||
  (typeof v === 'string' &&
    v.length <= 2_796_240 &&
    /^data:image\/(?:png|jpeg|webp);base64,[A-Za-z0-9+/]+={0,2}$/.test(v));
function invalid(): never {
  throw new ApkError(
    'invalid_response',
    'The APK service returned an invalid response.',
  );
}

export function parseReport(value: unknown): ApkReport {
  if (
    !record(value) ||
    typeof value.path !== 'string' ||
    !value.path ||
    !size(value.size) ||
    !icon(value.iconDataUrl) ||
    !record(value.signature) ||
    !['verified', 'invalid', 'unverified', 'unsigned'].includes(
      String(value.signature.status),
    ) ||
    typeof value.signature.message !== 'string' ||
    !Array.isArray(value.signature.schemes) ||
    !value.signature.schemes.every(
      (s: unknown) =>
        typeof s === 'string' && ['v1', 'v2', 'v3', 'v3.1'].includes(s),
    ) ||
    (value.signature.status === 'verified' &&
      (value.signature.schemes.length === 0 ||
        value.signature.schemes.includes('v1'))) ||
    typeof value.sha256 !== 'string' ||
    !/^[A-F0-9]{64}$/.test(value.sha256) ||
    typeof value.manifest !== 'string' ||
    !Array.isArray(value.warnings) ||
    !value.warnings.every((v) => typeof v === 'string') ||
    !Array.isArray(value.sections) ||
    !value.sections.every(
      (s) =>
        record(s) &&
        typeof s.title === 'string' &&
        Array.isArray(s.items) &&
        s.items.every(
          (i: unknown) =>
            record(i) &&
            typeof i.label === 'string' &&
            (i.value === null || typeof i.value === 'string'),
        ),
    ) ||
    !Array.isArray(value.files) ||
    !value.files.every(
      (f) =>
        record(f) &&
        typeof f.name === 'string' &&
        size(f.size) &&
        size(f.compressedSize),
    )
  )
    invalid();
  return value as unknown as ApkReport;
}

export function createTauriApkService(call: Invoke = invoke): ApkService {
  async function request(command: string, args?: Record<string, unknown>) {
    try {
      return await call(command, args);
    } catch (e) {
      if (
        record(e) &&
        typeof e.code === 'string' &&
        typeof e.message === 'string'
      )
        throw new ApkError(e.code, e.message);
      throw new ApkError(
        'unavailable',
        'The APK operation is unavailable. Please retry.',
      );
    }
  }
  return {
    async choosePath() {
      const path = await request('choose_apk_path');
      if (path !== null && (typeof path !== 'string' || !path)) invalid();
      return path as string | null;
    },
    async analyze(path) {
      const report = parseReport(await request('analyze_apk', { path }));
      if (report.path !== path) invalid();
      return report;
    },
    async listenDrop(handler) {
      return getCurrentWebview().onDragDropEvent(({ payload }) => {
        if (payload.type === 'drop')
          handler({ type: 'drop', paths: payload.paths });
        else if (payload.type === 'enter' || payload.type === 'leave')
          handler({ type: payload.type });
      });
    },
    async install(connectionId, path, sha256) {
      const result = await request('install_apk', {
        connectionId,
        path,
        sha256,
      });
      if (result !== null) invalid();
    },
  };
}
