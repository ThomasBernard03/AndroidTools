package fr.thomasbernard03.androidtools.presentation.logcat

import androidtools.composeapp.generated.resources.Res
import androidtools.composeapp.generated.resources.arrow_up
import androidtools.composeapp.generated.resources.folder
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.unit.dp
import fr.thomasbernard03.androidtools.presentation.logcat.components.LogcatItem
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.painterResource

@Composable
fun LogcatScreen(uiState: LogcatUiState, onEvent: (LogcatEvent) -> Unit) {

    val listState = rememberLazyListState()
    val animatedScrollScope = rememberCoroutineScope()

    LaunchedEffect(Unit) {
        onEvent(LogcatEvent.OnStartListening)
    }

    LaunchedEffect(uiState.lines) {
        animatedScrollScope.launch {
            listState.animateScrollToItem(uiState.lines.size)
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