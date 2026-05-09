import 'package:flutter/material.dart';
import 'package:flutter_monaco/flutter_monaco.dart';

class TextPreviewWidget extends StatefulWidget {
  final String content;
  final String fileName;

  const TextPreviewWidget({
    super.key,
    required this.content,
    required this.fileName,
  });

  @override
  State<TextPreviewWidget> createState() => _TextPreviewWidgetState();
}

class _TextPreviewWidgetState extends State<TextPreviewWidget> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        _focusNode.requestFocus();
      },
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        child: MonacoEditor(
          initialValue: widget.content,
          interactionEnabled: true,
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
        ),
      ),
    );
  }
}
