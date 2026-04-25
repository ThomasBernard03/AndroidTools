import 'package:android_tools/features/information/presentation/widgets/side_button.dart';
import 'package:flutter/material.dart';

class DynamicDevicePreview extends StatelessWidget {
  final int screenWidth;
  final int screenHeight;
  final Color? screenColor;
  final Widget? child;

  const DynamicDevicePreview({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    this.screenColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    const double frameHeight = 380;
    const double frameThicknessH = 4.0;
    const double frameThicknessTop = 4.0;
    const double frameThicknessBottom = 4.0;
    const double outerRadius = 32.0;
    const double innerRadius = 26.0;
    const double shadowPadding = 72.0;

    final double aspectRatio = screenWidth / screenHeight;
    final double innerHeight =
        frameHeight - frameThicknessTop - frameThicknessBottom;
    final double innerWidth = innerHeight * aspectRatio;
    final double frameWidth = innerWidth + frameThicknessH * 2;

    return Padding(
      padding: const EdgeInsets.only(bottom: shadowPadding),
      child: SizedBox(
        height: frameHeight,
        width: frameWidth,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Phone body
            Container(
              width: frameWidth,
              height: frameHeight,
              decoration: BoxDecoration(
                color: const Color(0xFFCACFDA),
                borderRadius: BorderRadius.circular(outerRadius),
                border: Border.all(color: const Color(0xFF3A3A3C), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withAlpha(25),
                    blurRadius: 64,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withAlpha(120),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
            ),

            // Screen area
            Positioned(
              left: frameThicknessH,
              right: frameThicknessH,
              top: frameThicknessTop,
              bottom: frameThicknessBottom,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(innerRadius),
                  border: Border.all(color: Colors.black, width: 3.0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(innerRadius - 3.0),
                  child: Stack(
                    children: [
                      // Screen content background
                      Positioned.fill(
                        child: Container(
                          color: screenColor ?? const Color(0xFF0A0A0A),
                        ),
                      ),

                      // Child widget or resolution label
                      if (child != null)
                        Center(child: child)
                      else
                        Center(
                          child: Text(
                            '$screenWidth×$screenHeight',
                            style: const TextStyle(
                              color: Color(0xFF3A3A3C),
                              fontSize: 11,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),

                      // Camera punch hole
                      Positioned(
                        top: 10,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: const BoxDecoration(
                              color: Color(0xFF010102),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0E0E0E),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Volume buttons (left)
            Positioned(
              left: -2,
              top: 80,
              child: Column(
                spacing: 10,
                children: [SideButton(height: 28), SideButton(height: 28)],
              ),
            ),

            // Power button (right)
            Positioned(right: -2, top: 100, child: SideButton(height: 46)),
          ],
        ),
      ),
    );
  }
}
