// Windows configuration shares the main window without native decorations,
// so caption controls render inside the blue application title bar.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';

test('Windows window configuration mirrors the shared window', () => {
  const base = JSON.parse(readFileSync('src-tauri/tauri.conf.json', 'utf8'));
  const windows = JSON.parse(
    readFileSync('src-tauri/tauri.windows.conf.json', 'utf8'),
  );
  assert.equal(windows.app.windows.length, base.app.windows.length);
  assert.equal(windows.app.windows.length, 1);
  const { decorations, ...rest } = windows.app.windows[0];
  assert.deepEqual(rest, base.app.windows[0]);
  assert.equal(decorations, false);
});
