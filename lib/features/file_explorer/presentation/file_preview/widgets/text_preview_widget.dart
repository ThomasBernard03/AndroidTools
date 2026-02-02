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
      options: EditorOptions(wordWrap: false),
    );
  }
}
