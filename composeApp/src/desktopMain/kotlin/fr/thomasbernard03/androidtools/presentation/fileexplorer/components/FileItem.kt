package fr.thomasbernard03.androidtools.presentation.fileexplorer.components

import androidtools.composeapp.generated.resources.Res
import androidtools.composeapp.generated.resources.file
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import fr.thomasbernard03.androidtools.commons.extensions.byteCountToDisplaySize
import fr.thomasbernard03.androidtools.presentation.commons.extensions.fileIcon
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
        name = name,
        size = size,
        modifiedAt = modifiedAt,
        colors = ButtonDefaults.buttonColors(
            containerColor = if (!selected) MaterialTheme.colorScheme.surface else MaterialTheme.colorScheme.primaryContainer,
            contentColor = MaterialTheme.colorScheme.onBackground,
        ),
        leadingIcon = { name.fileIcon() },
        subTitle = {
            Text(
                textAlign = TextAlign.Start,
                text = name.substringAfterLast(".") + " / " + size.byteCountToDisplaySize(),
                style = MaterialTheme.typography.bodySmall.copy(
                    color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f)
                ),
                maxLines = 1
            )
        }
    )
}