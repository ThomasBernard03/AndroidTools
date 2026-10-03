export const workspacePages = [
  {
    id: 'overview',
    label: 'Device overview',
    group: 'Workspace',
    icon: 'overview',
    description: '',
  },
  {
    id: 'files',
    label: 'File explorer',
    group: 'Workspace',
    icon: 'folder',
    description: 'Browse files and folders on your Android device.',
  },
  {
    id: 'logcat',
    label: 'Logcat',
    group: 'Workspace',
    icon: 'terminal',
    description: 'Read and filter Android device logs.',
  },
  {
    id: 'apk-analysis',
    label: 'APK analysis',
    group: 'APK',
    icon: 'package',
    description: 'Inspect APK metadata, permissions and signatures.',
  },
  {
    id: 'apk-generation',
    label: 'APK generation',
    group: 'APK',
    icon: 'build',
    description: 'Generate APK packages from your Android projects.',
  },
  {
    id: 'apk-signing',
    label: 'APK signing',
    group: 'APK',
    icon: 'shield',
    description: 'Sign APK packages with your signing key.',
  },
] as const;

export type WorkspacePage = (typeof workspacePages)[number];
