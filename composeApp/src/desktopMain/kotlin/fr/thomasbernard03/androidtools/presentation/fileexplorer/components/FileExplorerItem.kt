package fr.thomasbernard03.androidtools.presentation.fileexplorer.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import fr.thomasbernard03.androidtools.commons.extensions.byteCountToDisplaySize
import fr.thomasbernard03.androidtools.presentation.theme.FolderColor
import org.jetbrains.compose.resources.DrawableResource
import org.jetbrains.compose.resources.painterResource
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

@Composable
fun FileExplorerItem(
    modifier: Modifier = Modifier,
    onClick : () -> Unit,
    icon : DrawableResource,
    iconTint : Color = MaterialTheme.colorScheme.onBackground,
    name: String,
    size : Long,
    modifiedAt : LocalDateTime
) {
    Button(
        modifier = modifier,
        onClick = onClick,
        shape = RoundedCornerShape(4.dp),
        contentPadding = PaddingValues(16.dp),
        elevation = ButtonDefaults.buttonElevation(
            defaultElevation = 4.dp,
            pressedElevation = 4.dp,
            hoveredElevation = 4.dp,
            focusedElevation = 4.dp
        ),
        colors = ButtonDefaults.buttonColors(
            containerColor = MaterialTheme.colorScheme.surface,
            contentColor = MaterialTheme.colorScheme.onBackground,
        )
    ){
        Row(
            horizontalArrangement = Arrangement.spacedBy(4.dp),
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.fillMaxWidth(),
        ) {
            Icon(
                painter = painterResource(icon),
                contentDescription = name,
                modifier = Modifier.size(24.dp),
                tint = iconTint
            )

            Text(
                modifier = Modifier.weight(1f),
                textAlign = TextAlign.Start,
                text = name,
                style = MaterialTheme.typography.bodySmall
            )

//            Text(
//                text = size.byteCountToDisplaySize(),
//                style = MaterialTheme.typography.bodySmall
//            )

            // HH:mm MMM dd, yyyy
            val outputFormatter = DateTimeFormatter.ofPattern("HH:mm MMM dd, yyyy")
            Text(
                text = modifiedAt.format(outputFormatter),
                style = MaterialTheme.typography.bodySmall
            )
        }
    }
}