export type EntryKind = 'directory' | 'file' | 'symlink' | 'other';
export interface FileEntry {
  name: string;
  kind: EntryKind;
  size: number | null;
  modifiedAt: number | null;
  permissions: string | null;
}
export interface FileListing {
  path: string;
  entries: FileEntry[];
}
export type Mutation = 'rename' | 'delete' | 'create_directory';
export type FilePreview = { kind: 'text' | 'image'; content: string };
export type FileDrop =
  | { type: 'leave' }
  | { type: 'enter' | 'over'; x: number; y: number }
  | { type: 'drop'; x: number; y: number; paths: string[] };
export interface FileService {
  listenDrop(handler: (event: FileDrop) => void): Promise<() => void>;
  uploadPaths(deviceId: string, path: string, sources: string[]): Promise<void>;
  preview(deviceId: string, path: string): Promise<FilePreview>;
  list(deviceId: string, path: string): Promise<FileListing>;
  mutate(
    deviceId: string,
    path: string,
    operation: Mutation,
    name: string,
  ): Promise<void>;
  transfer(
    deviceId: string,
    path: string,
    upload: boolean,
    directory: boolean,
  ): Promise<boolean>;
}
export class FileError extends Error {
  constructor(
    public readonly code: string,
    message: string,
    public readonly partial = false,
  ) {
    super(message);
    this.name = 'FileError';
  }
}
export function fileError(error: unknown): FileError {
  return error instanceof FileError
    ? error
    : new FileError(
        'unknown',
        'The file operation could not finish. Refresh and retry.',
      );
}
export const childPath = (parent: string, name: string) =>
  `${parent === '/' ? '' : parent}/${name}`;
export const validName = (name: string) =>
  name.length > 0 && name !== '.' && name !== '..' && !/[\0/]/u.test(name);
