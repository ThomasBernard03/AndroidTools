import 'package:android_tools/main.dart';
import 'package:android_tools/shared/core/constants.dart';
import 'package:android_tools/shared/domain/helpers/settings_helper.dart';
import 'package:auto_updater/auto_updater.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';

part 'settings_event.dart';
part 'settings_state.dart';
part 'settings_bloc.mapper.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final Logger _logger = getIt.get();
  final SettingsHelper _settingsHelper = getIt.get();

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

    on<OnLoadThemeMode>((event, emit) async {
      try {
        final themeString = await _settingsHelper.getThemeMode();
        final themeMode = _stringToThemeMode(themeString);
        emit(state.copyWith(themeMode: themeMode));
      } catch (e) {
        _logger.e("Error loading theme mode: $e");
        emit(state.copyWith(themeMode: ThemeMode.system));
      }
    });

    on<OnThemeModeChanged>((event, emit) async {
      try {
        await _settingsHelper.setThemeMode(event.themeMode.name);
        emit(state.copyWith(themeMode: event.themeMode));
        _logger.i("Theme mode updated to ${event.themeMode.name}");
      } catch (e) {
        _logger.e("Error updating theme mode: $e");
      }
    });

    on<OnLoadCrashReportingSetting>((event, emit) async {
      try {
        final disabled = await _settingsHelper.getCrashReportingDisabled();
        emit(state.copyWith(crashReportingDisabled: disabled));
      } catch (e) {
        _logger.e("Error loading crash reporting setting: $e");
        emit(state.copyWith(crashReportingDisabled: false));
      }
    });

    on<OnCrashReportingToggled>((event, emit) async {
      try {
        await _settingsHelper.setCrashReportingDisabled(event.disabled);
        emit(state.copyWith(crashReportingDisabled: event.disabled));
        _logger.i("Crash reporting ${event.disabled ? 'disabled' : 'enabled'}");
      } catch (e) {
        _logger.e("Error updating crash reporting setting: $e");
      }
    });
  }

  ThemeMode _stringToThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}
