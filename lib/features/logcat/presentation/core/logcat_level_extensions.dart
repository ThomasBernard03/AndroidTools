import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/features/logcat/presentation/core/logcat_colors.dart';
import 'package:flutter/material.dart';

extension LogcatLevelExtensions on LogcatLevel {
  Color backgroundColor() {
    return switch (this) {
      LogcatLevel.verbose => LogcatColors.verboseBackgroundColor,
      LogcatLevel.debug => LogcatColors.debugBackgroundColor,
      LogcatLevel.info => LogcatColors.infoBackgroundColor,
      LogcatLevel.warning => LogcatColors.warningBackgroundColor,
      LogcatLevel.error => LogcatColors.errorBackgroundColor,
      LogcatLevel.fatal => LogcatColors.errorBackgroundColor,
    };
  }

  IconData icon() {
    return switch (this) {
      LogcatLevel.verbose => Icons.filter_none,
      LogcatLevel.debug => Icons.bug_report,
      LogcatLevel.info => Icons.info,
      LogcatLevel.warning => Icons.warning,
      LogcatLevel.error => Icons.cancel,
      LogcatLevel.fatal => Icons.cancel,
    };
  }

  Color onBackgroundColor() {
    return switch (this) {
      LogcatLevel.verbose => LogcatColors.verboseOnBackgroundColor,
      LogcatLevel.debug => LogcatColors.debugOnBackgroundTextColor,
      LogcatLevel.info => LogcatColors.infoOnBackgroundColor,
      LogcatLevel.warning => LogcatColors.warningOnBackgroundColor,
      LogcatLevel.error => LogcatColors.errorOnBackgroundColor,
      LogcatLevel.fatal => LogcatColors.errorOnBackgroundColor,
    };
  }

  Color textColor() {
    return switch (this) {
      LogcatLevel.verbose => LogcatColors.verboseTextColor,
      LogcatLevel.debug => LogcatColors.debugTextColor,
      LogcatLevel.info => LogcatColors.infoTextColor,
      LogcatLevel.warning => LogcatColors.warningTextColor,
      LogcatLevel.error => LogcatColors.errorTextColor,
      LogcatLevel.fatal => LogcatColors.errorTextColor,
    };
  }
}
