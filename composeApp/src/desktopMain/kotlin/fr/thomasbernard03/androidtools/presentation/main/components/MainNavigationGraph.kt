package fr.thomasbernard03.androidtools.presentation.main.components

import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavGraphBuilder
import androidx.navigation.compose.composable
import fr.thomasbernard03.androidtools.domain.models.Screen
import fr.thomasbernard03.androidtools.presentation.applicationinstaller.ApplicationInstallerScreen
import fr.thomasbernard03.androidtools.presentation.applicationinstaller.ApplicationInstallerViewModel
import fr.thomasbernard03.androidtools.presentation.information.InformationScreen
import fr.thomasbernard03.androidtools.presentation.information.InformationViewModel
import fr.thomasbernard03.androidtools.presentation.logcat.LogcatScreen
import fr.thomasbernard03.androidtools.presentation.logcat.LogcatViewModel

fun NavGraphBuilder.mainNavigationGraph(){
    composable(Screen.ApplicationInstaller.route) {
        val viewModel = viewModel { ApplicationInstallerViewModel() }
        val uiState by viewModel.uiState.collectAsStateWithLifecycle()
        ApplicationInstallerScreen(uiState = uiState, onEvent = viewModel::onEvent)
    }

    composable(Screen.Information.route) {
        val viewModel = viewModel { InformationViewModel() }
        val uiState by viewModel.uiState.collectAsStateWithLifecycle()
        InformationScreen(uiState = uiState, onEvent = viewModel::onEvent)
    }

    composable(Screen.Logcat.route) {
        val viewModel = viewModel { LogcatViewModel() }
        val uiState by viewModel.uiState.collectAsStateWithLifecycle()
        LogcatScreen(uiState = uiState, onEvent = viewModel::onEvent)
    }
}