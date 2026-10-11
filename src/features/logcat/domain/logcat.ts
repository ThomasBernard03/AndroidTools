export const logLevels = [
  { value: 'V', label: 'Verbose' },
  { value: 'D', label: 'Debug' },
  { value: 'I', label: 'Info' },
  { value: 'W', label: 'Warning' },
  { value: 'E', label: 'Error' },
  { value: 'F', label: 'Fatal' },
] as const;
export type LogLevel = (typeof logLevels)[number]['value'];
export interface LogEntry {
  id: number;
  repeatCount: number;
  text: string;
  level: LogLevel;
}
export interface LogSnapshot {
  counts: number[];
  groupedCounts: number[];
  error: { code: string; message: string } | null;
}
export interface LogPage {
  start: number;
  entries: LogEntry[];
}
export interface LogSearch {
  grouped: boolean;
  minimum: LogLevel;
  query: string;
  start: number;
  end: number;
  backward: boolean;
}
export interface LogSearchResult {
  position: number | null;
  next: number | null;
}
export interface LogcatService {
  packages(connectionId: string): Promise<string[]>;
  start(connectionId: string, packageName: string): Promise<number>;
  read(token: number): Promise<LogSnapshot>;
  page(
    token: number,
    minimum: LogLevel,
    start: number,
    grouped?: boolean,
  ): Promise<LogPage>;
  search(token: number, request: LogSearch): Promise<LogSearchResult>;
  stop(token: number): Promise<void>;
  pause(token: number): Promise<void>;
  clear(connectionId: string): Promise<void>;
}
export function meetsLevel(entry: LogEntry, minimum: LogLevel) {
  return 'VDIWEF'.indexOf(entry.level) >= 'VDIWEF'.indexOf(minimum);
}
