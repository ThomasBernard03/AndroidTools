package fr.thomasbernard03.androidtools.presentation.fileexplorer

import androidtools.composeapp.generated.resources.Res
import androidtools.composeapp.generated.resources.arrow_back
import androidx.compose.foundation.VerticalScrollbar
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollbarAdapter
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import fr.thomasbernard03.androidtools.domain.models.Folder
import fr.thomasbernard03.androidtools.presentation.fileexplorer.components.FileItem
import fr.thomasbernard03.androidtools.presentation.fileexplorer.components.FolderItem
import org.jetbrains.compose.resources.painterResource

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
            Column {
                Row(
                    modifier = Modifier
                        .background(MaterialTheme.colorScheme.secondaryContainer)
                        .fillMaxWidth()
                        .padding(8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Icon(
                        painter = painterResource(Res.drawable.arrow_back),
                        contentDescription = "Go back",
                    )

                    Row(
                        modifier = Modifier
                            .clip(RoundedCornerShape(4.dp))
                            .background(MaterialTheme.colorScheme.background)
                            .weight(1f),
                    ) {
                        Text(
                            text = uiState.path,
                            modifier = Modifier.padding(8.dp),
                        )
                    }

                    Row {

                    }
                }

                Box {
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
                            } else {
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
                }
            }

            if (uiState.loading) {
                LinearProgressIndicator(
                    modifier = Modifier.fillMaxWidth().align(Alignment.BottomStart)
                )
            }
        }
    }
}