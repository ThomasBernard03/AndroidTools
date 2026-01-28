import 'package:android_tools/main.dart';
import 'package:android_tools/shared/core/constants.dart';
import 'package:android_tools/shared/domain/repositories/application_repository.dart';
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
  final ApplicationRepository _applicationRepository = getIt.get();

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

    on<OnClearInstalledApplicationHistory>((event, emit) async {
      _logger.i("Clearing installed application history");
      try {
        await _applicationRepository.clearInstalledApplicationHistory();
        _logger.i("Installed application history cleared successfully");
      } catch (e) {
        _logger.e("Error clearing installed application history: $e");
      }
    });

    on<OnLoadMaxHistorySize>((event, emit) async {
      try {
        final size = await _applicationRepository.getMaxHistorySize();
        emit(state.copyWith(maxHistorySize: size));
      } catch (e) {
        _logger.e("Error loading max history size: $e");
      }
    });

    on<OnMaxHistorySizeChanged>((event, emit) async {
      try {
        await _applicationRepository.setMaxHistorySize(event.size);
        emit(state.copyWith(maxHistorySize: event.size));
        _logger.i("Max history size updated to ${event.size}");
      } catch (e) {
        _logger.e("Error updating max history size: $e");
      }
    });
  }
}
