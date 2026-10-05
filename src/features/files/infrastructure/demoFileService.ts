import {
  childPath,
  FileError,
  type FileEntry,
  type FileService,
} from '../domain/files';

export function createDemoFileService(fail = false): FileService {
  const folder = (name: string): FileEntry => ({
    name,
    kind: 'directory',
    size: null,
    modifiedAt: 1791158400,
    permissions: '0755',
  });
  const file = (name: string): FileEntry => ({
    ...folder(name),
    kind: 'file',
    size: 2048,
    permissions: '0644',
  });
  const trees = new Map<string, Map<string, FileEntry[]>>();
  function tree(id: string) {
    if (fail) throw new FileError('adb', 'Simulated device disconnection.');
    let value = trees.get(id);
    if (!value) {
      value = new Map([
        ['/', [folder('sdcard'), folder('data'), folder('system')]],
        [
          '/sdcard',
          [folder('Download'), folder('Pictures'), file('notes.txt')],
        ],
        ['/sdcard/Download', [file('example.apk')]],
        ['/sdcard/Pictures', []],
        ['/data', [folder('data')]],
        [
          '/data/data',
          [folder('com.example.debug'), folder('com.example.production')],
        ],
        ['/data/data/com.example.debug', [folder('files')]],
        ['/data/data/com.example.debug/files', [file('settings.json')]],
      ]);
      trees.set(id, value);
    }
    return value;
  }
  function entries(id: string, path: string) {
    const value = tree(id).get(path);
    if (!value)
      throw new FileError(
        'permission_denied',
        'Simulated access denied. Private apps must be debuggable and allow run-as.',
      );
    return value;
  }
  return {
    async list(id, path) {
      return { path, entries: structuredClone(entries(id, path)) };
    },
    async mutate(id, path, operation, name) {
      const data = tree(id);
      if (operation === 'create_directory') {
        if (entries(id, path).some((e) => e.name === name))
          throw new FileError(
            'already_exists',
            'The destination already exists.',
          );
        entries(id, path).push(folder(name));
        data.set(childPath(path, name), []);
        return;
      }
      const index = path.lastIndexOf('/');
      const parent = path.slice(0, index) || '/';
      const siblings = entries(id, parent);
      const selected = siblings.find((e) => e.name === path.slice(index + 1));
      if (!selected)
        throw new FileError('not_found', 'The entry no longer exists.');
      if (operation === 'rename' && siblings.some((e) => e.name === name))
        throw new FileError(
          'already_exists',
          'The destination already exists.',
        );
      for (const [key, children] of [...data]) {
        if (key === path || key.startsWith(`${path}/`)) {
          data.delete(key);
          if (operation === 'rename')
            data.set(
              `${childPath(parent, name)}${key.slice(path.length)}`,
              children,
            );
        }
      }
      if (operation === 'delete')
        siblings.splice(siblings.indexOf(selected), 1);
      else selected.name = name;
    },
    async transfer(id, path, upload, directory) {
      if (upload) {
        const name = directory ? 'Uploaded folder' : 'uploaded.txt';
        if (entries(id, path).some((e) => e.name === name))
          throw new FileError(
            'already_exists',
            'The destination already exists.',
          );
        entries(id, path).push(directory ? folder(name) : file(name));
        if (directory) tree(id).set(childPath(path, name), []);
      } else tree(id);
      return true;
    },
  };
}
