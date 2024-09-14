package fr.thomasbernard03.androidtools.presentation.settings.appearance

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import fr.thomasbernard03.androidtools.presentation.commons.UiState

@Composable
fun AppearanceScreen(
    uiState: AppearanceUiState,
    onEvent: (AppearanceEvent) -> Unit
) {
    Scaffold {
        Column(
            modifier = Modifier.fillMaxSize()
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Switch(
                    checked = uiState.isAutoTheme,
                    onCheckedChange = { onEvent(AppearanceEvent.OnAutoThemeChange(it)) },
                    colors = SwitchDefaults.colors(
                        uncheckedThumbColor = MaterialTheme.colorScheme.background,
                        uncheckedBorderColor = Color.Transparent,
                        checkedBorderColor = Color.Transparent,
                        disabledUncheckedBorderColor = Color.Transparent,
                        disabledCheckedBorderColor = Color.Transparent
                    )
                )

                Text("Auto theme")
            }
        }
    }
}