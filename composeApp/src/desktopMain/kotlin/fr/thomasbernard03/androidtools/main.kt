package fr.thomasbernard03.androidtools

import androidtools.composeapp.generated.resources.Res
import androidtools.composeapp.generated.resources.app_name
import androidx.compose.runtime.getValue
import androidx.compose.ui.window.Window
import androidx.compose.ui.window.application
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import fr.thomasbernard03.androidtools.presentation.connectdevice.ConnectDeviceScreen
import fr.thomasbernard03.androidtools.presentation.main.MainScreen
import fr.thomasbernard03.androidtools.presentation.main.MainViewModel
import fr.thomasbernard03.androidtools.presentation.theme.AndroidToolsTheme
import io.kanro.compose.jetbrains.expui.window.JBWindow
import org.jetbrains.compose.resources.stringResource

fun main() = application {
    JBWindow(
        onCloseRequest = ::exitApplication,
        title = stringResource(Res.string.app_name)
    ){
        val navController: NavHostController = rememberNavController()

        AndroidToolsTheme {
            NavHost(navController, startDestination = "main") {
                composable("no_device_connected") {
                    ConnectDeviceScreen()
                }
                composable("main"){
                    val viewModel = viewModel { MainViewModel() }
                    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
                    MainScreen(uiState = uiState, onEvent = viewModel::onEvent)
                }
            }
        }
    }
}