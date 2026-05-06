import 'package:flutter/material.dart';

class FileExplorerAppBar extends StatelessWidget {
  final void Function()? onGoBack;
  final String path;
  final bool showSearch;
  final TextEditingController? searchController;
  final FocusNode? searchFocusNode;
  final int matchCount;
  final int currentMatchIndex;
  final VoidCallback? onSearchNext;
  final VoidCallback? onSearchPrevious;
  final VoidCallback? onSearchClose;
  final VoidCallback? onSearchChanged;

  const FileExplorerAppBar({
    super.key,
    required this.path,
    required this.onGoBack,
    this.showSearch = false,
    this.searchController,
    this.searchFocusNode,
    this.matchCount = 0,
    this.currentMatchIndex = 0,
    this.onSearchNext,
    this.onSearchPrevious,
    this.onSearchClose,
    this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
      title: Text(path, style: Theme.of(context).textTheme.titleLarge),
      leading: IconButton(
        onPressed: onGoBack,
        icon: Icon(Icons.chevron_left_rounded),
      ),
      actions: [
        _buildSearchField(context),
        if (showSearch) ..._buildSearchActions(context),
        SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return SizedBox(
      width: 250,
      child: TextField(
        controller: searchController,
        focusNode: searchFocusNode,
        autofocus: showSearch,
        style: Theme.of(context).textTheme.bodySmall,
        decoration: InputDecoration(
          hintText: 'Search...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          hintStyle: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: 14,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
          suffixText: showSearch
              ? (matchCount == 0
                    ? '0/0'
                    : '${currentMatchIndex + 1}/$matchCount')
              : null,
          suffixStyle: TextStyle(
            color: Theme.of(context).colorScheme.outline,
            fontSize: 11,
          ),
        ),
        onChanged: (_) => onSearchChanged?.call(),
      ),
    );
  }

  List<Widget> _buildSearchActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.keyboard_arrow_up, size: 20),
        onPressed: matchCount == 0 ? null : onSearchPrevious,
        tooltip: 'Previous (Shift+Enter)',
      ),
      IconButton(
        icon: Icon(Icons.keyboard_arrow_down, size: 20),
        onPressed: matchCount == 0 ? null : onSearchNext,
        tooltip: 'Next (Enter)',
      ),
      IconButton(
        icon: Icon(Icons.close, size: 20),
        onPressed: onSearchClose,
        tooltip: 'Close (Escape)',
      ),
    ];
  }
}
