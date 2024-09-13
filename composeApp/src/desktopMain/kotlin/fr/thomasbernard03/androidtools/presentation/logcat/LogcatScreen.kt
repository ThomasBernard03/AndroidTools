package fr.thomasbernard03.androidtools.presentation.logcat

import androidtools.composeapp.generated.resources.Res
import androidtools.composeapp.generated.resources.arrow_down
import androidtools.composeapp.generated.resources.arrow_up
import androidtools.composeapp.generated.resources.pause
import androidtools.composeapp.generated.resources.play
import androidtools.composeapp.generated.resources.replay
import androidtools.composeapp.generated.resources.sticky_list
import androidtools.composeapp.generated.resources.trash
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.HorizontalScrollbar
import androidx.compose.foundation.Image
import androidx.compose.foundation.VerticalScrollbar
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.rememberScrollbarAdapter
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Color.Companion.DarkGray
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.NativeKeyEvent
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onKeyEvent
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.unit.dp
import fr.thomasbernard03.androidtools.commons.extensions.indexOf
import fr.thomasbernard03.androidtools.presentation.logcat.components.LogcatFloatingActionButton
import fr.thomasbernard03.androidtools.presentation.logcat.components.LogcatItem
import fr.thomasbernard03.androidtools.presentation.logcat.components.PackageDropDown
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.painterResource

@Composable
fun LogcatScreen(uiState: LogcatUiState, onEvent: (LogcatEvent) -> Unit) {

    val listState = rememberLazyListState()
    val animatedScrollScope = rememberCoroutineScope()
    var sticky by remember { mutableStateOf(true) }
    val horizontalScroll = rememberScrollState()

    var query : String by remember { mutableStateOf("") }
    var currentOccurence by remember { mutableStateOf(0) }
    var numberOfOccurences by remember { mutableStateOf(0) }

    LaunchedEffect(Unit) {
        onEvent(LogcatEvent.OnGetAllPackages)
        onEvent(LogcatEvent.OnStartListening())
    }

    fun scrollToItem(index : Int){
        animatedScrollScope.launch {
            listState.animateScrollToItem(index)
        }
    }

    LaunchedEffect(uiState.lines, sticky) {
        if (sticky){
            scrollToItem(uiState.lines.size)
        }
    }

    Scaffold(
        floatingActionButton = {
            val isAtBottom = (listState.layoutInfo.visibleItemsInfo.lastOrNull()?.index ?: 0) >= (uiState.lines.size - 20)
            if (!isAtBottom) {
                LogcatFloatingActionButton(
                    onClick = { scrollToItem(uiState.lines.size) }
                )
            }
        }
    ) {
        Box(
            modifier = Modifier.fillMaxSize()
        ) {
            Column {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(MaterialTheme.colorScheme.surfaceContainer),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        PackageDropDown(
                            modifier = Modifier.width(300.dp),
                            selection = uiState.selectedPackage,
                            onSelectionChange = { onEvent(LogcatEvent.OnPackageSelected(it)) },
                            items = uiState.packages
                        )

                        TextField(
                            singleLine = true,
                            modifier = Modifier
                                .onKeyEvent { event ->
                                    if (event.key == Key.Enter && query.isNotEmpty() && numberOfOccurences > 0){
                                        if (currentOccurence < numberOfOccurences){
                                            currentOccurence++
                                            scrollToItem(uiState.lines.indexOf( { line -> line.contains(query, ignoreCase = true) }, currentOccurence))
                                        }
                                        else {
                                            currentOccurence = 1
                                            scrollToItem(uiState.lines.indexOf( { line -> line.contains(query, ignoreCase = true) }, currentOccurence))
                                        }
                                    }
                                    false
                                },
                            colors = TextFieldDefaults.colors(
                                disabledTextColor = MaterialTheme.colorScheme.onPrimary,
                                focusedContainerColor = Color.Transparent,
                                unfocusedContainerColor = Color.Transparent,
                                disabledContainerColor = Color.Transparent,
                                focusedIndicatorColor = Color.Transparent,
                                unfocusedIndicatorColor = Color.Transparent,
                                disabledIndicatorColor = Color.Transparent,
                                focusedLabelColor = DarkGray,
                                disabledLabelColor = DarkGray,
                                unfocusedLabelColor = DarkGray
                            ),
                            value = query,
                            onValueChange = {
                                query = it
                                if (query.isNotEmpty()){
                                    sticky = false
                                    numberOfOccurences = uiState.lines.count { line -> line.contains(query, ignoreCase = true) }
                                    if (numberOfOccurences > 0){
                                        currentOccurence = 1
                                        scrollToItem(uiState.lines.indexOfFirst { line -> line.contains(query, ignoreCase = true) })
                                    }
                                }
                            },
                            suffix = {
                                if (query.isNotEmpty()) {
                                    Text(
                                        text = "$currentOccurence/$numberOfOccurences",
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = DarkGray
                                    )
                                }
                            }
                        )
                    }


                    Row(
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        IconButton(
                            onClick = { sticky = !sticky },
                            colors = IconButtonDefaults.iconButtonColors(
                                containerColor = if (sticky) MaterialTheme.colorScheme.onBackground.copy(0.2f) else Color.Transparent
                            )
                        ) {
                            Icon(
                                painter = painterResource(Res.drawable.sticky_list),
                                contentDescription = "sticky",
                                tint = MaterialTheme.colorScheme.onBackground
                            )
                        }

                        IconButton(
                            onClick = { onEvent(LogcatEvent.OnRestart) }
                        ) {
                            Icon(
                                painter = painterResource(Res.drawable.replay),
                                contentDescription = "restart",
                                tint = MaterialTheme.colorScheme.onBackground
                            )
                        }

                        IconButton(
                            onClick = {
                                if (uiState.onPause)
                                    onEvent(LogcatEvent.OnStartListening(uiState.selectedPackage))
                                else
                                    onEvent(LogcatEvent.OnStopListening)
                            }
                        ) {
                            Icon(
                                painter = painterResource(if(uiState.onPause) Res.drawable.play else Res.drawable.pause),
                                contentDescription = "play/pause",
                                tint = MaterialTheme.colorScheme.onBackground
                            )
                        }

                        IconButton(
                            onClick = {
                                onEvent(LogcatEvent.OnClear)
                            }
                        ) {
                            Icon(
                                painter = painterResource(Res.drawable.trash),
                                contentDescription = "clear",
                                tint = MaterialTheme.colorScheme.onBackground
                            )
                        }
                    }
                }

                Box {
                    SelectionContainer {
                        LazyColumn(
                            modifier = Modifier.fillMaxWidth().horizontalScroll(horizontalScroll),
                            state = listState,
                            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp)
                        ) {
                            items(uiState.lines) { line ->
                                LogcatItem(line)
                            }
                        }
                    }

                    VerticalScrollbar(
                        modifier = Modifier.align(Alignment.CenterEnd).fillMaxHeight(),
                        adapter = rememberScrollbarAdapter(
                            scrollState = listState
                        )
                    )

                    HorizontalScrollbar(
                        modifier = Modifier.align(Alignment.BottomStart).fillMaxWidth().padding(end = 12.dp),
                        adapter = rememberScrollbarAdapter(
                            scrollState = horizontalScroll
                        )
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