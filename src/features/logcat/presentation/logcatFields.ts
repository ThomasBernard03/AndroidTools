export interface LogcatField {
  kind: 'timestamp' | 'process' | 'tag' | 'level' | 'message' | 'raw';
  text: string;
}

/** Reorder standard threadtime fields; preserve continuation lines literally. */
export function logcatFields(text: string): LogcatField[] {
  const match =
    /^(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+)\s+(\d+)\s+(\d+)\s+([VDIWEF])\s+(.+?): ?(.*)$/.exec(
      text,
    );
  if (!match) return [{ kind: 'raw', text }];
  return [
    { kind: 'timestamp', text: match[1]! },
    { kind: 'process', text: `${match[2]}-${match[3]}` },
    { kind: 'tag', text: match[5]!.trim() },
    { kind: 'level', text: match[4]! },
    { kind: 'message', text: match[6]! },
  ];
}
