extension StringExtensions on String {
  String anonymize() {
    if (length <= 6) {
      return '***';
    }

    final start = substring(0, 3);
    final end = substring(length - 3);

    return '$start...$end';
  }
}
