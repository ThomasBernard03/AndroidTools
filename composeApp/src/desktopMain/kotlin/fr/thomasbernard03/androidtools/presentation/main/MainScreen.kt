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
import fr.thomasbernard03.androidtools.presentation.applicationinstaller.ApplicationInstallerScreen
import fr.thomasbernard03.androidtools.presentation.applicationinstaller.ApplicationInstallerViewModel
import org.jetbrains.compose.resources.painterResource


@Composable
fun MainScreen() {
    Row {
        val navController: NavHostController = rememberNavController()
        val currentRoute = navController.currentBackStackEntryAsState().value?.destination?.route

        NavigationRail {
            NavigationRailItem(
                selected = currentRoute == "appInstaller",
                onClick = { navController.navigate("appInstaller") },
                icon = {
                    Image(
                        painter = painterResource(Res.drawable.app_installer),
                        contentDescription = "App Installer"
                    )
                },
                label = { Text("App Installer") }
            )

            NavigationRailItem(
                selected = currentRoute == "information",
                onClick = { navController.navigate("information") },
                icon = {
                    Image(
                        painter = painterResource(Res.drawable.information),
                        contentDescription = "Information"
                    )
                },
                label = { Text("App Installer") }
            )
        }

        NavHost(navController = navController, startDestination = "appInstaller") {
            composable("appInstaller") {
                val viewModel = viewModel { ApplicationInstallerViewModel() }
                val uiState by viewModel.uiState.collectAsStateWithLifecycle()
                ApplicationInstallerScreen(uiState = uiState, onEvent = viewModel::onEvent)
            }
            composable("information") {
                Text("Hello from information")
            }
        }
    }

}