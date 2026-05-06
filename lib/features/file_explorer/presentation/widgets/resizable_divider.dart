import 'package:flutter/material.dart';

class ResizableDivider extends StatefulWidget {
  final ValueChanged<double> onResize;
  final double width;

  const ResizableDivider({
    super.key,
    required this.onResize,
    this.width = 8.0,
  });

  @override
  State<ResizableDivider> createState() => _ResizableDividerState();
}

class _ResizableDividerState extends State<ResizableDivider> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          widget.onResize(details.delta.dx);
        },
        child: Container(
          width: widget.width,
          color: _isHovering
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          child: Center(
            child: Container(
              width: 1,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
      ),
    );
  }
}
