import 'package:flutter/material.dart';

class FileExplorerSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int matchCount;
  final int currentMatchIndex;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onClose;
  final VoidCallback onChanged;

  const FileExplorerSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.matchCount,
    required this.currentMatchIndex,
    required this.onNext,
    required this.onPrevious,
    required this.onClose,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                isDense: true,
                suffixText: matchCount == 0
                    ? '0/0'
                    : '${currentMatchIndex + 1}/$matchCount',
                suffixStyle: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.keyboard_arrow_up),
            onPressed: matchCount == 0 ? null : onPrevious,
            tooltip: 'Précédent (Shift+Enter)',
            padding: EdgeInsets.all(4),
            constraints: BoxConstraints(),
          ),
          IconButton(
            icon: Icon(Icons.keyboard_arrow_down),
            onPressed: matchCount == 0 ? null : onNext,
            tooltip: 'Suivant (Enter)',
            padding: EdgeInsets.all(4),
            constraints: BoxConstraints(),
          ),
          IconButton(
            icon: Icon(Icons.close),
            onPressed: onClose,
            tooltip: 'Fermer (Escape)',
            padding: EdgeInsets.all(4),
            constraints: BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
