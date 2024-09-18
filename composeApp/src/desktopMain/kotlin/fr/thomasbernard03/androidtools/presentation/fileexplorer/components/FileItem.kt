package fr.thomasbernard03.androidtools.presentation.fileexplorer.components

import androidtools.composeapp.generated.resources.Res
import androidtools.composeapp.generated.resources.file
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier

@Composable
fun FileItem(
    modifier: Modifier = Modifier,
    name: String,
    size : Long
) {
    FileExplorerItem(
        modifier = modifier,
        onClick = {},
        icon = Res.drawable.file,
        name = name,
        size = size
    )
}