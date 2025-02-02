package fr.thomasbernard03.androidtools.presentation.settings.appearance

import androidtools.composeapp.generated.resources.Res
import androidtools.composeapp.generated.resources.settings_appearance_title
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import fr.thomasbernard03.androidtools.presentation.settings.components.SettingsScaffold

@Composable
fun AppearanceScreen(
    uiState: AppearanceSettingsUiState,
    onEvent: (AppearanceSettingsEvent) -> Unit
) {
    SettingsScaffold(
        title = Res.string.settings_appearance_title
    ){
        Box(
            modifier = Modifier.fillMaxSize()
        ) {
            Text(text = "In progress...", modifier = Modifier.align(Alignment.Center))
        }

//        Row(
//            verticalAlignment = Alignment.CenterVertically,
//            horizontalArrangement = Arrangement.spacedBy(12.dp)
//        ) {
//            Switch(
//                checked = uiState.isAutoTheme,
//                onCheckedChange = { onEvent(AppearanceSettingsEvent.OnAutoThemeChange(it)) },
//                colors = SwitchDefaults.colors(
//                    uncheckedThumbColor = MaterialTheme.colorScheme.background,
//                    uncheckedBorderColor = Color.Transparent,
//                    checkedBorderColor = Color.Transparent,
//                    disabledUncheckedBorderColor = Color.Transparent,
//                    disabledCheckedBorderColor = Color.Transparent
//                )
//            )
//
//            Text("Auto theme")
//        }
    }
}