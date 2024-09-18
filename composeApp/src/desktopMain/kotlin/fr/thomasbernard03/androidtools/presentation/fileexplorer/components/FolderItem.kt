package fr.thomasbernard03.androidtools.presentation.fileexplorer.components

import androidtools.composeapp.generated.resources.Res
import androidtools.composeapp.generated.resources.folder
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier

@Composable
fun FolderItem(
    modifier: Modifier = Modifier,
    name: String,
    size : Long,
    onExpand : () -> Unit
) {
    FileExplorerItem(
        modifier = modifier,
        onClick = onExpand,
        icon = Res.drawable.folder,
        name = name,
        size = size
    )
}