package fr.thomasbernard03.androidtools.presentation.logcat

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.unit.dp

@Composable
fun LogcatScreen(uiState: LogcatUiState, onEvent: (LogcatEvent) -> Unit) {

    LaunchedEffect(Unit) {
        onEvent(LogcatEvent.OnStartListening)
    }

    Scaffold {
        LazyColumn(
            reverseLayout = true,
            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp)
        ) {
            items(uiState.lines) {
                Text(it)
            }
        }
    }
}