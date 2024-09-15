package fr.thomasbernard03.androidtools.presentation.information

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
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
import fr.thomasbernard03.androidtools.presentation.information.components.DeviceNameCard

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun InformationScreen(uiState : InformationUiState, onEvent : (InformationEvent) -> Unit) {

    LaunchedEffect(Unit){
        onEvent(InformationEvent.OnLoadInformation)
    }

    Scaffold {
        Box(modifier = Modifier.fillMaxSize()) {
            Column {
                FlowRow(
                    modifier = Modifier.padding(16.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    // Android version
                    AndroidVersionCard(
                        modifier = Modifier.height(200.dp),
                        version = uiState.androidVersion
                    )

                    DeviceNameCard(name = uiState.model)

//                    Card(
//                        colors = CardDefaults.cardColors(
//                            containerColor = MaterialTheme.colorScheme.secondary,
//                        )
//                    ){
//                        Column(
//                            modifier = Modifier.padding(32.dp)
//                        ) {
//                            Text(
//                                text = uiState.model,
//                                style = MaterialTheme.typography.titleLarge.copy(color = MaterialTheme.colorScheme.onSecondary),
//                            )
//
//                            Text(
//                                text = uiState.manufacturer,
//                                style = MaterialTheme.typography.titleMedium.copy(color = MaterialTheme.colorScheme.onSecondary),
//                            )
//                        }
//                    }

                    Card(
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.tertiary,
                        )
                    ){
                        Text(
                            text = "${uiState.battery}%",
                            modifier = Modifier.padding(32.dp),
                            style = MaterialTheme.typography.titleLarge.copy(color = MaterialTheme.colorScheme.onTertiary),
                        )
                    }
                }

                LazyColumn(
                    contentPadding = PaddingValues(16.dp),
                ) {
                    items(uiState.lines.toList()){ item ->
                        Row(
                            horizontalArrangement = Arrangement.SpaceBetween,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text(
                                text = item.first,
                                style = MaterialTheme.typography.bodyMedium,
                            )
                            Text(
                                text = item.second,
                                style = MaterialTheme.typography.bodyMedium,
                            )
                        }
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