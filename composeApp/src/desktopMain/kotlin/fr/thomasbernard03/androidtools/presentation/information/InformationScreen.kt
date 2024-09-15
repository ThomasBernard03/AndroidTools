package fr.thomasbernard03.androidtools.presentation.information

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.VerticalScrollbar
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.lazy.staggeredgrid.LazyVerticalStaggeredGrid
import androidx.compose.foundation.lazy.staggeredgrid.StaggeredGridCells
import androidx.compose.foundation.lazy.staggeredgrid.rememberLazyStaggeredGridState
import androidx.compose.foundation.rememberScrollbarAdapter
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
import fr.thomasbernard03.androidtools.presentation.information.components.BatteryLevel
import fr.thomasbernard03.androidtools.presentation.information.components.DeviceNameCard
import fr.thomasbernard03.androidtools.presentation.information.components.SerialNumberCard

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun InformationScreen(uiState : InformationUiState, onEvent : (InformationEvent) -> Unit) {


    LaunchedEffect(Unit){
        onEvent(InformationEvent.OnLoadInformation)
    }

    Scaffold {
        Box(modifier = Modifier.fillMaxSize()) {
            LazyVerticalStaggeredGrid(
                columns = StaggeredGridCells.Adaptive(200.dp),
                verticalItemSpacing = 8.dp,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                contentPadding = PaddingValues(16.dp),
            ){
                item {
                    // Android version
                    AndroidVersionCard(
                        modifier = Modifier.height(200.dp),
                        version = uiState.androidVersion
                    )
                }

                item {
                    DeviceNameCard(name = uiState.model)
                }

                item {
                    BatteryLevel(
                        batteryLevel = uiState.battery,
                    )
                }

                item {
                    SerialNumberCard(
                        serialNumber = uiState.serialNumber
                    )
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