package fr.thomasbernard03.androidtools.presentation.information.components

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
fun SerialNumberCard(serialNumber : String){
    Card(
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.tertiaryContainer,
        )
    ) {
        Column(
            modifier = Modifier.padding(32.dp)
        ) {
            Text(
                text = "Serial number",
                style = MaterialTheme.typography.titleMedium.copy(color = MaterialTheme.colorScheme.onTertiaryContainer),
            )

            Text(
                text = serialNumber,
                style = MaterialTheme.typography.titleSmall.copy(color = MaterialTheme.colorScheme.onTertiaryContainer),
            )
        }
    }
}