import 'package:flutter/material.dart';

class DisplayInformationWidget extends StatelessWidget {
  final int width;
  final int height;
  final int density;

  const DisplayInformationWidget({
    super.key,
    required this.width,
    required this.height,
    required this.density,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Card(
        color: Color(0xFF1A1D1C),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Icon(
                    Icons.smartphone,
                    size: 64,
                    color: Colors.white.withAlpha(100),
                  ),
                ),
              ),
              Text(
                "${width}x$height",
                style: TextStyle(fontSize: 22),
              ),
              Row(
                spacing: 8,
                children: [
                  Text(
                    "Display",
                    style: TextStyle(color: Color(0xFF6C696E), fontSize: 18),
                  ),
                  Text(
                    "${density}dpi",
                    style: TextStyle(color: Color(0xFF6C696E), fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
