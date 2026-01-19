import 'package:android_tools/main.dart';
import 'package:android_tools/shared/core/constants.dart';
import 'package:auto_updater/auto_updater.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';

part 'settings_event.dart';
part 'settings_state.dart';
part 'settings_bloc.mapper.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final Logger _logger = getIt.get();

  SettingsBloc() : super(SettingsState()) {
    on<OnOpenLogDirectory>((event, emit) async {
      _logger.i("Opening log directory");
      final logDirectory = await Constants.getApplicationLogsDirectory();
      final uri = Uri.file(logDirectory.path);
      await launchUrl(uri);
    });
    on<OnCheckForUpdates>((event, emit) async {
      _logger.i("Checking for updates");
      await autoUpdater.checkForUpdates();
    });
    on<OnOpenGithubProject>((event, emit) async {
      _logger.i("Opening github repository");
      const repositoryUrl = String.fromEnvironment(
        Constants.environmentGitRepositoryUrl,
        defaultValue: '',
      );

      if (repositoryUrl.isEmpty) {
        _logger.w(
          "${Constants.environmentGitRepositoryUrl} not found from environment, launch project with '--dart-define=${Constants.environmentGitRepositoryUrl}=your_git_repository'",
        );
        return;
      }

      final uri = Uri.parse(repositoryUrl);
      await launchUrl(uri);
    });

    on<OnCreateIssue>((event, emit) async {
      _logger.i("Creating issue");
      const issueUrl = String.fromEnvironment(
        Constants.environmentIssueUrl,
        defaultValue: '',
      );

      if (issueUrl.isEmpty) {
        _logger.w(
          "${Constants.environmentIssueUrl} not found from environment, launch project with '--dart-define=${Constants.environmentIssueUrl}=your_issue_url'",
        );
        return;
      }

      final uri = Uri.parse(issueUrl);
      await launchUrl(uri);
    });
  }
}
