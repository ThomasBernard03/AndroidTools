import 'package:flutter/material.dart' show PopupMenuItem;
import 'package:flutter/widgets.dart';

class LogcatLevelFilterPopupMenuItem<T> extends PopupMenuItem<T> {
  final String text;
  final IconData icon;
  final Color color;

  LogcatLevelFilterPopupMenuItem({
    super.key,
    super.value,
    required this.text,
    required this.icon,
    required this.color,
  }) : super(
         child: Row(
           spacing: 8,
           children: [
             Icon(icon, color: color),
             Text(text),
           ],
         ),
       );
}
