package fr.thomasbernard03.androidtools.presentation.main

import androidtools.composeapp.generated.resources.Res
import androidtools.composeapp.generated.resources.app_installer
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Row
import androidx.compose.material3.NavigationRail
import androidx.compose.material3.NavigationRailItem
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import fr.thomasbernard03.androidtools.presentation.applicationinstaller.ApplicationInstallerScreen
import fr.thomasbernard03.androidtools.presentation.applicationinstaller.ApplicationInstallerViewModel
import org.jetbrains.compose.resources.painterResource


@Composable
fun MainScreen() {
    Row {
        NavigationRail(
        ){
            NavigationRailItem(
                selected = true,
                onClick = {},
                icon = {
                    Image(
                        painter = painterResource(Res.drawable.app_installer),
                        contentDescription = "App Installer"
                    )
                },
                label = { Text("App Installer") }
            )
        }

        val viewModel = viewModel { ApplicationInstallerViewModel() }
        val uiState by viewModel.uiState.collectAsStateWithLifecycle()
        ApplicationInstallerScreen(uiState = uiState, onEvent = viewModel::onEvent)
    }

}