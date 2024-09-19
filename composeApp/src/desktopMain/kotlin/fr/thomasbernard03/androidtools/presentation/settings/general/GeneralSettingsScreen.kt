package fr.thomasbernard03.androidtools.presentation.settings.general

import androidtools.composeapp.generated.resources.Res
import androidtools.composeapp.generated.resources.settings_general_title
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import fr.thomasbernard03.androidtools.presentation.settings.components.SettingsScaffold

@Composable
fun GeneralSettingsScreen(
    uiState: GeneralSettingsUiState,
    onEvent: (GeneralSettingsEvent) -> Unit
) {
    LaunchedEffect(Unit){
        onEvent(GeneralSettingsEvent.OnLoadSettings)
    }

    SettingsScaffold(
        title = Res.string.settings_general_title
    ) {
        Text(text = "Adb version: ${uiState.adbVersion}")
    }
}