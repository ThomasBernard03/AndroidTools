package fr.thomasbernard03.androidtools.presentation.fileexplorer.components

import androidtools.composeapp.generated.resources.Res
import androidtools.composeapp.generated.resources.folder
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import fr.thomasbernard03.androidtools.commons.extensions.byteCountToDisplaySize
import fr.thomasbernard03.androidtools.presentation.theme.FolderColor
import org.jetbrains.compose.resources.painterResource
import java.time.LocalDateTime

@Composable
fun FolderItem(
    modifier: Modifier = Modifier,
    name: String,
    size : Long,
    modifiedAt : LocalDateTime,
    onExpand : () -> Unit
) {
    FileExplorerItem(
        modifier = modifier,
        onDoubleClick = onExpand,
        onClick = onExpand,
        name = name,
        modifiedAt = modifiedAt,
        leadingIcon = {
            Icon(
                painter = painterResource(Res.drawable.folder),
                contentDescription = name,
                modifier = Modifier.size(24.dp),
                tint = FolderColor
            )
        },
        subTitle = {
            Text(
                textAlign = TextAlign.Start,
                text = size.byteCountToDisplaySize(),
                style = MaterialTheme.typography.bodySmall.copy(
                    color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f)
                ),
                maxLines = 1
            )
        }
    )
}