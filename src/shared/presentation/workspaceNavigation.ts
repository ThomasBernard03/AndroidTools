export const workspacePages = [
  {
    id: 'overview',
    label: 'Device overview',
    group: 'Device',
    icon: 'overview',
    description: '',
  },
  {
    id: 'files',
    label: 'File explorer',
    group: 'Device',
    icon: 'folder',
    description: 'Browse files and folders on your Android device.',
  },
  {
    id: 'logcat',
    label: 'Logcat',
    group: 'Device',
    icon: 'terminal',
    description: 'Read and filter Android device logs.',
  },
  {
    id: 'apk-analysis',
    label: 'APK analysis',
    group: 'APK & Keystore',
    icon: 'package',
    description: 'Inspect APK metadata, permissions and signatures.',
  },
  {
    id: 'generate-keystore',
    label: 'Generate keystore',
    group: 'APK & Keystore',
    icon: 'build',
    description:
      'Create a keystore and signing key for your Android applications.',
  },
  {
    id: 'apk-signing',
    label: 'APK signing',
    group: 'APK & Keystore',
    icon: 'shield',
    description: 'Sign APK packages with your signing key.',
  },
  {
    id: 'keystore-explorer',
    label: 'Keystore explorer',
    group: 'APK & Keystore',
    icon: 'search',
    description:
      'Explore keystore aliases, certificates and signing credentials.',
  },
  {
    id: 'settings',
    label: 'Settings',
    group: 'Application',
    icon: 'settings',
    description: 'Application preferences, support and updates.',
  },
] as const;

export type WorkspacePage = (typeof workspacePages)[number];
