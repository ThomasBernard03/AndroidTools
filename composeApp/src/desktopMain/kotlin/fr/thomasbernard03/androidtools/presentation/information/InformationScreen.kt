package fr.thomasbernard03.androidtools.presentation.information

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import fr.thomasbernard03.androidtools.presentation.information.components.AndroidVersionCard

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun InformationScreen(uiState : InformationUiState, onEvent : (InformationEvent) -> Unit) {

    LaunchedEffect(Unit){
        onEvent(InformationEvent.OnLoadInformation)
    }

    Scaffold {
        Box(modifier = Modifier.fillMaxSize()) {

            FlowRow(
                modifier = Modifier.padding(16.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                // Android version
                AndroidVersionCard(version = uiState.androidVersion)

                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.secondary,
                    )
                ){
                    Column(
                        modifier = Modifier.padding(32.dp)
                    ) {
                        Text(
                            text = uiState.model,
                            style = MaterialTheme.typography.titleLarge.copy(color = MaterialTheme.colorScheme.onSecondary),
                        )

                        Text(
                            text = uiState.manufacturer,
                            style = MaterialTheme.typography.titleMedium.copy(color = MaterialTheme.colorScheme.onSecondary),
                        )
                    }
                }
            }

            AnimatedVisibility(
                visible = uiState.loading,
                modifier = Modifier.align(Alignment.BottomStart)
            ) {
                LinearProgressIndicator(
                    modifier = Modifier.fillMaxWidth()
                )
            }
        }
    }
}