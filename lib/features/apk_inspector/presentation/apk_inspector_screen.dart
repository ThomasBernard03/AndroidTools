import 'package:android_tools/features/apk_inspector/presentation/apk_inspector_bloc.dart';
import 'package:android_tools/features/apk_inspector/presentation/widgets/apk_import_view.dart';
import 'package:android_tools/features/apk_inspector/presentation/widgets/apk_parsing_view.dart';
import 'package:android_tools/features/apk_inspector/presentation/widgets/apk_report_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Main screen for the APK Inspector feature
///
/// Routes between different views based on the current state:
/// - idle: Shows import view
/// - parsing: Shows parsing progress
/// - ready/installing/installed: Shows APK report
class ApkInspectorScreen extends StatelessWidget {
  const ApkInspectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ApkInspectorBloc(),
      child: Scaffold(
        body: BlocBuilder<ApkInspectorBloc, ApkInspectorState>(
          builder: (context, state) {
            return switch (state.status) {
              ApkInspectorStatus.idle => const ApkImportView(),
              ApkInspectorStatus.parsing => const ApkParsingView(),
              ApkInspectorStatus.ready ||
              ApkInspectorStatus.installing ||
              ApkInspectorStatus.installed ||
              ApkInspectorStatus.error =>
                const ApkReportView(),
            };
          },
        ),
      ),
    );
  }
}
