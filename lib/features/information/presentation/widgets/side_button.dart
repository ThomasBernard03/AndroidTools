import 'package:flutter/material.dart';

class SideButton extends StatelessWidget {
  final double height;

  const SideButton({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
