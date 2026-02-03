import 'package:flutter/material.dart';
import 'package:flutter_monaco/flutter_monaco.dart';

class TextPreviewWidget extends StatelessWidget {
  final String content;
  final String fileName;

  const TextPreviewWidget({
    super.key,
    required this.content,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return MonacoEditor(
      initialValue: content,
      interactionEnabled: false,
      loadingBuilder: (context) => Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      options: EditorOptions(
        wordWrap: false,
        lineNumbers: false,
        readOnly: true,
        scrollBeyondLastLine: false,
        contextMenu: false,
      ),
    );
  }
}
