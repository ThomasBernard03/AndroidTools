class FileExtensionHelper {
  static bool isTextExtension(String extension) {
    const textExtensions = [
      '.txt',
      '.json',
      '.xml',
      '.yaml',
      '.yml',
      '.md',
      '.log',
      '.csv',
      '.html',
      '.css',
      '.js',
      '.ts',
      '.dart',
      '.java',
      '.kt',
      '.py',
      '.rb',
      '.sh',
      '.gradle',
      '.properties',
      '.conf',
      '.config',
      '.ini',
    ];

    return textExtensions.contains(extension);
  }

  static bool isImageExtension(String extension) {
    const imageExtensions = [
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.bmp',
      '.webp',
      '.svg',
      '.ico',
    ];

    return imageExtensions.contains(extension);
  }

  static bool isVideoExtension(String extension) {
    const videoExtensions = [
      '.mp4',
      '.avi',
      '.mkv',
      '.mov',
      '.wmv',
      '.flv',
      '.webm',
      '.m4v',
    ];

    return videoExtensions.contains(extension);
  }

  static bool isAudioExtension(String extension) {
    const audioExtensions = [
      '.mp3',
      '.wav',
      '.ogg',
      '.m4a',
      '.flac',
      '.aac',
      '.wma',
    ];

    return audioExtensions.contains(extension);
  }
}
