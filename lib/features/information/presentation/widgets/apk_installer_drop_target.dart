import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

class ApkInstallerDropTarget extends StatefulWidget {
  final OnDragDoneCallback? onApkDropped;

  const ApkInstallerDropTarget({super.key, this.onApkDropped});

  @override
  State<ApkInstallerDropTarget> createState() => _ApkInstallerDropTargetState();
}

class _ApkInstallerDropTargetState extends State<ApkInstallerDropTarget> {
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
      onDragDone: widget.onApkDropped,
      child: Stack(
        children: [
          Card.filled(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.add_rounded, size: 200),
                  Text(
                    "Drag and drop your .apk file here to install app on connected device",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

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
                          'Drop your .apk files here',
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
