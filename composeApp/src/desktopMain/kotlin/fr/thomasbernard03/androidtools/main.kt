package fr.thomasbernard03.androidtools

import androidtools.composeapp.generated.resources.Res
import androidtools.composeapp.generated.resources.app_name
import androidx.compose.runtime.getValue
import androidx.compose.ui.window.Window
import androidx.compose.ui.window.application
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import fr.thomasbernard03.androidtools.commons.di.androidToolsModule
import fr.thomasbernard03.androidtools.presentation.main.MainScreen
import fr.thomasbernard03.androidtools.presentation.main.MainViewModel
import fr.thomasbernard03.androidtools.presentation.theme.AndroidToolsTheme
import org.jetbrains.compose.resources.stringResource
import org.koin.core.context.GlobalContext.startKoin

fun main() = application {
    startKoin { modules(androidToolsModule) }

    Window(
        onCloseRequest = ::exitApplication,
        title = stringResource(Res.string.app_name)
    ){

        AndroidToolsTheme {
            val viewModel = viewModel { MainViewModel() }
            val uiState by viewModel.uiState.collectAsStateWithLifecycle()
            MainScreen(uiState = uiState, onEvent = viewModel::onEvent)
        }
    }
}