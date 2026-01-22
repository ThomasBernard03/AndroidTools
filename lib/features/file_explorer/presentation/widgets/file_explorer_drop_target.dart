import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

class FileExplorerDropTarget extends StatefulWidget {
  final Widget child;
  final OnDragDoneCallback? onFileDropped;

  const FileExplorerDropTarget({
    super.key,
    required this.child,
    this.onFileDropped,
  });

  @override
  State<FileExplorerDropTarget> createState() => _FileExplorerDropTargetState();
}

class _FileExplorerDropTargetState extends State<FileExplorerDropTarget> {
  bool isDropping = false;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (_) {
        setState(() => isDropping = true);
      },
      onDragExited: (_) {
        setState(() => isDropping = false);
      },
      onDragDone: widget.onFileDropped,
      child: Stack(
        children: [
          widget.child,

          if (isDropping)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black.withAlpha(60),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.file_download_outlined,
                          size: 64,
                          color: Colors.white,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Drop your files here',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
