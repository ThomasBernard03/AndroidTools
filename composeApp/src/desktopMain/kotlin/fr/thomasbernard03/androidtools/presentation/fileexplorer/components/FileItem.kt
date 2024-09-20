package fr.thomasbernard03.androidtools.presentation.fileexplorer.components

import androidtools.composeapp.generated.resources.Res
import androidtools.composeapp.generated.resources.file
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import java.time.LocalDateTime

@Composable
fun FileItem(
    modifier: Modifier = Modifier,
    name: String,
    size : Long,
    modifiedAt : LocalDateTime,
    selected : Boolean,
    onClick : () -> Unit
) {
    FileExplorerItem(
        modifier = modifier,
        onClick = onClick,
        icon = Res.drawable.file,
        name = name,
        size = size,
        modifiedAt = modifiedAt,
        colors = ButtonDefaults.buttonColors(
            containerColor = if (!selected) MaterialTheme.colorScheme.surface else MaterialTheme.colorScheme.primaryContainer,
            contentColor = MaterialTheme.colorScheme.onBackground,
        )
    )
}