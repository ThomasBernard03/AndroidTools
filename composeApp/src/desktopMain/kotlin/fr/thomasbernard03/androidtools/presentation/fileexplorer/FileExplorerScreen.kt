package fr.thomasbernard03.androidtools.presentation.fileexplorer

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.VerticalScrollbar
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollbarAdapter
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import fr.thomasbernard03.androidtools.domain.models.Folder
import fr.thomasbernard03.androidtools.presentation.fileexplorer.components.FileItem
import fr.thomasbernard03.androidtools.presentation.fileexplorer.components.FolderItem

@Composable
fun FileExplorerScreen(
    uiState: FileExplorerUiState,
    onEvent: (FileExplorerEvent) -> Unit
) {
    val state = rememberLazyListState()

    LaunchedEffect(Unit){
        onEvent(FileExplorerEvent.OnAppearing)
    }

    Scaffold {
        Box(
            modifier = Modifier.fillMaxSize()
        ) {
            Row(
                modifier = Modifier
                    .align(Alignment.TopStart)
                    .padding(4.dp)
            ) {

            }

            LazyColumn(
                state = state
            ) {
                items(uiState.files) { file ->
                    if (file is Folder) {
                        FolderItem(
                            modifier = Modifier.fillMaxWidth(),
                            name = file.name,
                            size = file.size,
                            onExpand = {
                                onEvent(FileExplorerEvent.OnGetFiles("${file.path}/${file.name}"))
                            }
                        )
                    }
                    else {
                        FileItem(
                            modifier = Modifier.fillMaxWidth(),
                            name = file.name,
                            size = file.size
                        )
                    }
                }
            }

            VerticalScrollbar(
                modifier = Modifier.align(Alignment.CenterEnd).fillMaxHeight(),
                adapter = rememberScrollbarAdapter(
                    scrollState = state
                )
            )

            Column(
                modifier = Modifier
                    .background(color = MaterialTheme.colorScheme.surfaceContainer)
                    .align(Alignment.BottomStart)
                    .padding(horizontal = 8.dp)
                    .padding(bottom = 8.dp, top = 4.dp)
            ) {
                Text(
                    text = uiState.path,
                    style = MaterialTheme.typography.bodySmall,
                    modifier = Modifier.fillMaxWidth()
                )
            }


            if (uiState.loading) {
                LinearProgressIndicator(
                    modifier = Modifier.fillMaxWidth().align(Alignment.BottomStart)
                )
            }
        }
    }
}