import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class FileExplorerBreadcrumb extends StatelessWidget {
  final String currentPath;
  final void Function(String path) onNavigateToPath;

  const FileExplorerBreadcrumb({
    super.key,
    required this.currentPath,
    required this.onNavigateToPath,
  });

  @override
  Widget build(BuildContext context) {
    final parts = currentPath
        .split("/")
        .where((part) => part.isNotEmpty)
        .toList();
    final breadcrumbItems = ["/", ...parts];

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: SizedBox(
        height: 30,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          scrollDirection: Axis.horizontal,
          separatorBuilder: (context, index) {
            return Icon(
              Icons.chevron_right_rounded,
              size: 12,
              color: Theme.of(context).colorScheme.outline,
            );
          },
          itemBuilder: (context, index) {
            final part = breadcrumbItems[index];
            return TextButton(
              style: ButtonStyle(
                foregroundColor: WidgetStatePropertyAll(
                  Theme.of(context).colorScheme.onSurface,
                ),
              ),
              onPressed: () {
                if (index == 0) {
                  onNavigateToPath("");
                } else {
                  final newPath = parts.take(index).join("/");
                  onNavigateToPath(newPath);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  spacing: 4,
                  children: [
                    SvgPicture.asset(
                      "assets/images/folder/red_folder.svg",
                      width: 12,
                    ),
                    Text(part),
                  ],
                ),
              ),
            );
          },
          itemCount: breadcrumbItems.length,
        ),
      ),
    );
  }
}
