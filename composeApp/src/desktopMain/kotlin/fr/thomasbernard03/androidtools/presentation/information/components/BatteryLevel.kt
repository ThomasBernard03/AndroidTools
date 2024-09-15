package fr.thomasbernard03.androidtools.presentation.information.components

import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp

@Composable
fun BatteryLevel(
    modifier: Modifier = Modifier,
    batteryLevel: Int
) {
    Card(
        modifier = modifier,
        colors = CardDefaults.cardColors(
            containerColor = Color(0xFF70D78D),
        )
    ) {
        Text(
            textAlign = TextAlign.Center,
            text = "$batteryLevel%",
            modifier = Modifier.padding(32.dp).fillMaxWidth(),
            style = MaterialTheme.typography.titleLarge.copy(color = MaterialTheme.colorScheme.background),
        )
    }
}