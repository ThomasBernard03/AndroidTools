import { describe, expect, it } from 'vitest';
import { logcatFields } from './logcatFields';

describe('logcatFields', () => {
  it('orders threadtime fields and joins process and thread IDs', () => {
    expect(
      logcatFields(
        '10-13 12:34:56.789  1234  5678 D DemoApp : Message: details',
      ),
    ).toEqual([
      { kind: 'timestamp', text: '10-13 12:34:56.789' },
      { kind: 'process', text: '1234-5678' },
      { kind: 'tag', text: 'DemoApp' },
      { kind: 'level', text: 'D' },
      { kind: 'message', text: 'Message: details' },
    ]);
  });

  it('preserves message indentation and empty messages', () => {
    expect(
      logcatFields('10-13 12:34:56.789 1 2 E App:   indented').at(-1)?.text,
    ).toBe('  indented');
    expect(logcatFields('10-13 12:34:56.789 1 2 E App: ').at(-1)?.text).toBe(
      '',
    );
  });

  it('keeps stack traces, buffer markers and unknown formats literal', () => {
    for (const text of [
      '    at example.Main.run(Main.java:12)',
      '--------- beginning of main',
      'unrecognized log',
    ]) {
      expect(logcatFields(text)).toEqual([{ kind: 'raw', text }]);
    }
  });
});
