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
      color: Color(0xFF1E1E1E),
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              style: TextStyle(
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                hintStyle: TextStyle(
                  color: Colors.white54,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.white24,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.white24,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.blue,
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
                  color: Colors.white70,
                ),
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.keyboard_arrow_up,
              color: Colors.white,
            ),
            onPressed: matchCount == 0 ? null : onPrevious,
            tooltip: 'Précédent (Shift+Enter)',
            padding: EdgeInsets.all(4),
            constraints: BoxConstraints(),
          ),
          IconButton(
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
            ),
            onPressed: matchCount == 0 ? null : onNext,
            tooltip: 'Suivant (Enter)',
            padding: EdgeInsets.all(4),
            constraints: BoxConstraints(),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: Colors.white,
            ),
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
