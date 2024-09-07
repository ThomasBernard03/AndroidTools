package fr.thomasbernard03.androidtools.presentation.applicationinstaller

import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable

@Composable
fun ApplicationInstallerScreen(uiState : ApplicationInstallerUiState, onEvent: (ApplicationInstallerEvent) -> Unit) {
    Scaffold(
        floatingActionButton = {
            FloatingActionButton(
                onClick = {}
            ){
                Text("Load from files")
            }
        }
    ) {

    }
}