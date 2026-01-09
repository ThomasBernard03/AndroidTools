extension ByteFormatter on int {
  String toReadableBytes({int decimals = 2}) {
    if (this < 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    double size = toDouble();
    int i = 0;

    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
  }
}
