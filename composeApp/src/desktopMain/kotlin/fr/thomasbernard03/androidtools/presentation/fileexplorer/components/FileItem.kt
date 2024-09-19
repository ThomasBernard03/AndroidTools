package fr.thomasbernard03.androidtools.presentation.fileexplorer.components

import androidtools.composeapp.generated.resources.Res
import androidtools.composeapp.generated.resources.file
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import java.time.LocalDateTime

@Composable
fun FileItem(
    modifier: Modifier = Modifier,
    name: String,
    size : Long,
    modifiedAt : LocalDateTime
) {
    FileExplorerItem(
        modifier = modifier,
        onClick = {},
        icon = Res.drawable.file,
        name = name,
        size = size,
        modifiedAt = modifiedAt
    )
}