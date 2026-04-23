import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// Drag-and-drop zone widget for importing APK files
///
/// Supports both drag-and-drop and file picker (browse) functionality
class ApkDropZone extends StatefulWidget {
  final Function(String apkPath) onApkSelected;

  const ApkDropZone({
    super.key,
    required this.onApkSelected,
  });

  @override
  State<ApkDropZone> createState() => _ApkDropZoneState();
}

class _ApkDropZoneState extends State<ApkDropZone> {
  bool _isDragging = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['apk', 'apks', 'aab'],
      dialogTitle: 'Select APK file',
    );

    if (result != null && result.files.isNotEmpty) {
      final filePath = result.files.first.path;
      if (filePath != null) {
        widget.onApkSelected(filePath);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DropTarget(
      onDragEntered: (_) {
        setState(() => _isDragging = true);
      },
      onDragExited: (_) {
        setState(() => _isDragging = false);
      },
      onDragDone: (details) {
        setState(() => _isDragging = false);

        final file = details.files.firstOrNull;
        if (file != null && file.path.endsWith('.apk')) {
          widget.onApkSelected(file.path);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: _isDragging
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          borderRadius: BorderRadius.circular(10),
          color: _isDragging
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.surfaceContainer,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: colorScheme.primary.withValues(alpha: 0.12),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Drop an APK here',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'or browse a file from your computer',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.surfaceContainerHighest,
                  ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.upload_outlined, size: 18),
              label: const Text('Browse files'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'accepts .apk · .apks · .aab',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    fontFamily: 'monospace',
                    fontSize: 10.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
