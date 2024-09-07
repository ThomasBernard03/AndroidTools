package fr.thomasbernard03.androidtools.presentation.logcat

import androidtools.composeapp.generated.resources.Res
import androidtools.composeapp.generated.resources.arrow_up
import androidtools.composeapp.generated.resources.sticky_list
import androidtools.composeapp.generated.resources.trash
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import fr.thomasbernard03.androidtools.presentation.logcat.components.LogcatItem
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.painterResource

@Composable
fun LogcatScreen(uiState: LogcatUiState, onEvent: (LogcatEvent) -> Unit) {

    val listState = rememberLazyListState()
    val animatedScrollScope = rememberCoroutineScope()
    var sticky by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        onEvent(LogcatEvent.OnStartListening)
    }

    LaunchedEffect(uiState.lines, sticky) {
        if (sticky){
            animatedScrollScope.launch {
                listState.animateScrollToItem(uiState.lines.size)
            }
        }
    }

    Scaffold(
        floatingActionButton = {
            FloatingActionButton(
                onClick = {
                    animatedScrollScope.launch {
                        listState.animateScrollToItem(uiState.lines.size)
                    }
                }
            ){
                Image(
                    painter = painterResource(Res.drawable.arrow_up),
                    contentDescription = "load from files"
                )
            }
        }
    ) {
        Column(
            modifier = Modifier.fillMaxSize()
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(MaterialTheme.colorScheme.surfaceContainer),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                IconButton(
                    onClick = {
                        sticky = !sticky
                    },
                    colors = IconButtonDefaults.iconButtonColors(
                        containerColor = if (sticky) MaterialTheme.colorScheme.onBackground.copy(0.2f) else Color.Transparent
                    )
                ) {
                    Image(
                        painter = painterResource(Res.drawable.sticky_list),
                        contentDescription = "clear"
                    )
                }

                IconButton(
                    onClick = {
                        onEvent(LogcatEvent.OnClear)
                    }
                ) {
                    Image(
                        painter = painterResource(Res.drawable.trash),
                        contentDescription = "clear"
                    )
                }
            }

            LazyColumn(
                state = listState,
                reverseLayout = true,
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp)
            ) {
                items(uiState.lines) {
                    LogcatItem(it)
                }
            }
        }
    }
}