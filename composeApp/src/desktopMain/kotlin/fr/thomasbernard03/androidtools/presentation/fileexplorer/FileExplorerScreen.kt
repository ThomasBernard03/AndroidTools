package fr.thomasbernard03.androidtools.presentation.fileexplorer

import androidtools.composeapp.generated.resources.Res
import androidtools.composeapp.generated.resources.arrow_back
import androidtools.composeapp.generated.resources.folder
import androidtools.composeapp.generated.resources.open_file_explorer
import androidtools.composeapp.generated.resources.replay
import androidtools.composeapp.generated.resources.trash
import androidx.compose.foundation.VerticalScrollbar
import androidx.compose.foundation.background
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
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.rememberScrollbarAdapter
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
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
import androidx.compose.ui.DragData
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.onExternalDrag
import androidx.compose.ui.unit.dp
import fr.thomasbernard03.androidtools.commons.extensions.getParents
import fr.thomasbernard03.androidtools.domain.models.Folder
import fr.thomasbernard03.androidtools.presentation.fileexplorer.components.FileItem
import fr.thomasbernard03.androidtools.presentation.fileexplorer.components.FolderItem
import fr.thomasbernard03.androidtools.presentation.theme.FolderColor
import org.jetbrains.compose.resources.painterResource
import org.jetbrains.compose.resources.stringResource
import java.awt.FileDialog
import java.awt.Frame
import java.net.URLDecoder

@OptIn(ExperimentalComposeUiApi::class)
@Composable
fun FileExplorerScreen(
    uiState: FileExplorerUiState,
    onEvent: (FileExplorerEvent) -> Unit
) {
    val state = rememberLazyGridState()
    var hoverred by remember { mutableStateOf(false) }

    LaunchedEffect(Unit){
        onEvent(FileExplorerEvent.OnAppearing)
    }

    Scaffold(
        modifier = Modifier
            .onExternalDrag(
                enabled = !uiState.loading,
                onDragStart = { hoverred = true },
                onDragExit = { hoverred = false },
                onDrop = { externalDragValue ->
                    if (hoverred) {
                        hoverred = false
                        if (externalDragValue.dragData is DragData.FilesList) {
                            val draggedFiles = (externalDragValue.dragData as DragData.FilesList).readFiles().map { it.drop(5) } // Remove file: prefix
                            draggedFiles.firstOrNull()?.let {
                                onEvent(FileExplorerEvent.OnAddFile(URLDecoder.decode(it, "UTF-8")))
                            }
                        }
                    }
                },
            ),
        floatingActionButton = {
            FloatingActionButton(
                onClick = {
                    val fileDialog = FileDialog(Frame(), "", FileDialog.LOAD)
                    fileDialog.isVisible = true
                    val selectedFile = fileDialog.file
                    val directory = fileDialog.directory

                    selectedFile?.let {
                        val filePath = "$directory$selectedFile"
                        onEvent(FileExplorerEvent.OnAddFile(filePath))
                    }
                }
            ){
                Icon(
                    painter = painterResource(Res.drawable.folder),
                    contentDescription = stringResource(Res.string.open_file_explorer),
                    tint = MaterialTheme.colorScheme.onBackground
                )
            }
        }
    ) {
        Box(
            modifier = Modifier.fillMaxSize().then(
                if (hoverred)
                    Modifier.background(MaterialTheme.colorScheme.onBackground.copy(0.2f))
                else
                    Modifier
            )
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
                    IconButton(
                        onClick = { onEvent(FileExplorerEvent.OnGoBack) }
                    ) {
                        Icon(
                            painter = painterResource(Res.drawable.arrow_back),
                            contentDescription = "Go back",
                        )
                    }

                    Row(
                        modifier = Modifier
                            .clip(RoundedCornerShape(4.dp))
                            .background(MaterialTheme.colorScheme.background)
                            .weight(1f)
                            .horizontalScroll(rememberScrollState())
                            .padding(horizontal = 8.dp, vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        uiState.folder?.getParents()?.forEach { parent ->
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                Icon(
                                    painter = painterResource(Res.drawable.folder),
                                    contentDescription = parent.name,
                                    tint = FolderColor
                                )
                                Text(
                                    text = parent.name,
                                    modifier = Modifier.padding(8.dp),
                                )

                                Icon(
                                    painter = painterResource(Res.drawable.arrow_back),
                                    contentDescription = parent.name,
                                    tint = MaterialTheme.colorScheme.onBackground.copy(0.7f),
                                    modifier = Modifier.rotate(180f).size(12.dp)
                                )
                            }
                        }
                    }

                    Row {
                        IconButton(
                            onClick = { onEvent(FileExplorerEvent.OnRefresh) }
                        ) {
                            Icon(
                                painter = painterResource(Res.drawable.replay),
                                contentDescription = "Refresh",
                            )
                        }

                        IconButton(
                            enabled = uiState.selectedFile != null,
                            onClick = { uiState.selectedFile?.let { onEvent(FileExplorerEvent.OnDelete("${it.path}/${it.name}")) }}
                        ) {
                            Icon(
                                painter = painterResource(Res.drawable.trash),
                                contentDescription = "Delete",
                            )
                        }
                    }
                }

                Box {
                    LazyVerticalGrid(
                        state = state,
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                        contentPadding = PaddingValues(8.dp),
                        columns = GridCells.Adaptive(300.dp),
                    ){
                        items(uiState.folder?.childens ?: emptyList()) { file ->
                            if (file is Folder) {
                                FolderItem(
                                    modifier = Modifier.fillMaxWidth(),
                                    name = file.name,
                                    size = file.size,
                                    modifiedAt = file.modifiedAt,
                                    onExpand = {
                                        onEvent(FileExplorerEvent.OnGetFiles(file))
                                    }
                                )
                            } else {
                                FileItem(
                                    modifier = Modifier.fillMaxWidth(),
                                    name = file.name,
                                    size = file.size,
                                    modifiedAt = file.modifiedAt,
                                    selected = uiState.selectedFile?.name == file.name,
                                    onClick = { onEvent(FileExplorerEvent.OnFileSelected(file)) }
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