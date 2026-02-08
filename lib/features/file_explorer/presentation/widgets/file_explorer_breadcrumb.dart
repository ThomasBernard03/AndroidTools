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
    final parts = currentPath.split("/");

    return Container(
      color: Color(0xFF1A1D1C),
      child: SizedBox(
        height: 30,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
          ),
          scrollDirection: Axis.horizontal,
          separatorBuilder: (context, index) {
            return Icon(
              Icons.chevron_right_rounded,
              size: 12,
              color: Color.fromARGB(255, 98, 99, 99),
            );
          },
          itemBuilder: (context, index) {
            final part = parts[index];
            return TextButton(
              style: ButtonStyle(
                foregroundColor: WidgetStatePropertyAll(
                  Theme.of(context).colorScheme.onSurface,
                ),
              ),
              onPressed: () {
                final newPath = parts.take(index + 1).join("/");
                onNavigateToPath(newPath);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                ),
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
          itemCount: parts.length,
        ),
      ),
    );
  }
}
