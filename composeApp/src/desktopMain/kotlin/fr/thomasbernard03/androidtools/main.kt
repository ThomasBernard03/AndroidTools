package fr.thomasbernard03.androidtools

import androidx.compose.material.MaterialTheme
import androidx.compose.runtime.getValue
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Window
import androidx.compose.ui.window.WindowSize
import androidx.compose.ui.window.WindowState
import androidx.compose.ui.window.application
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import fr.thomasbernard03.androidtools.presentation.information.InformationViewModel
import fr.thomasbernard03.androidtools.presentation.main.MainScreen
import fr.thomasbernard03.androidtools.presentation.main.MainViewModel
import fr.thomasbernard03.androidtools.presentation.theme.AndroidToolsTheme

fun main() = application {
    Window(
        onCloseRequest = ::exitApplication,
        title = "Android Tools",
    ) {
        AndroidToolsTheme {
            val viewModel = viewModel { MainViewModel() }
            val uiState by viewModel.uiState.collectAsStateWithLifecycle()
            MainScreen(uiState = uiState, onEvent = viewModel::onEvent)
        }
    }
}