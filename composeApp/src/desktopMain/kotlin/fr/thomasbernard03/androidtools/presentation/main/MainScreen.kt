package fr.thomasbernard03.androidtools.presentation.main

import androidtools.composeapp.generated.resources.Res
import androidtools.composeapp.generated.resources.app_installer
import androidtools.composeapp.generated.resources.information
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Row
import androidx.compose.material3.NavigationRail
import androidx.compose.material3.NavigationRailItem
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import fr.thomasbernard03.androidtools.domain.models.Screen
import fr.thomasbernard03.androidtools.presentation.applicationinstaller.ApplicationInstallerScreen
import fr.thomasbernard03.androidtools.presentation.applicationinstaller.ApplicationInstallerViewModel
import org.jetbrains.compose.resources.painterResource
import org.jetbrains.compose.resources.stringResource


@Composable
fun MainScreen() {
    Row {
        val navController: NavHostController = rememberNavController()

        NavigationRail {
            val currentRoute = navController.currentBackStackEntryAsState().value?.destination?.route

            val items = listOf(
                Screen.ApplicationInstaller,
                Screen.Information
            )

            items.forEach { item ->
                NavigationRailItem(
                    selected = currentRoute == item.route,
                    onClick = { navController.navigate(item.route) },
                    icon = {
                        Image(
                            painter = painterResource(item.icon),
                            contentDescription = stringResource(item.title)
                        )
                    },
                    label = { Text(stringResource(item.title)) }
                )
            }
        }

        NavHost(navController = navController, startDestination = Screen.ApplicationInstaller.route) {
            composable(Screen.ApplicationInstaller.route) {
                val viewModel = viewModel { ApplicationInstallerViewModel() }
                val uiState by viewModel.uiState.collectAsStateWithLifecycle()
                ApplicationInstallerScreen(uiState = uiState, onEvent = viewModel::onEvent)
            }

            composable(Screen.Information.route) {
                Text("Hello from information")
            }
        }
    }
}