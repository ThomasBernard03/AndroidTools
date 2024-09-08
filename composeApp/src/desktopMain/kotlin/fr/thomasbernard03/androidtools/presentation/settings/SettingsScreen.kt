package fr.thomasbernard03.androidtools.presentation.settings

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Modifier

@Composable
fun SettingsScreen(
    uiState: SettingsUiState,
    onEvent: (SettingsEvent) -> Unit
) {
    LaunchedEffect(Unit){
        onEvent(SettingsEvent.OnAppearing)
    }

    Scaffold {
        Column(
            modifier = Modifier.fillMaxSize()
        ) {
            Text(text = "Settings")

            Text(text = "ADB Path")
            Text(text = uiState.adbPath)
        }
    }
}