package fr.thomasbernard03.androidtools.presentation.fileexplorer.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ButtonColors
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

@Composable
fun FileExplorerItem(
    modifier: Modifier = Modifier,
    onClick : () -> Unit,
    onDoubleClick : () -> Unit = {},
    leadingIcon : @Composable () -> Unit,
    subTitle : @Composable () -> Unit = {},
    name: String,
    modifiedAt : LocalDateTime,
    colors : ButtonColors = ButtonDefaults.buttonColors(
        containerColor = MaterialTheme.colorScheme.surface,
        contentColor = MaterialTheme.colorScheme.onBackground,
    )
) {
    OutlinedButton(
        modifier =  modifier,
        onClick = onClick,
        shape = RoundedCornerShape(4.dp),
        contentPadding = PaddingValues(16.dp),
        elevation = ButtonDefaults.buttonElevation(
            defaultElevation = 0.dp,
            pressedElevation = 0.dp,
            hoveredElevation = 0.dp,
            focusedElevation = 0.dp
        ),
        colors = colors,
        border = BorderStroke(0.5.dp, MaterialTheme.colorScheme.onBackground.copy(alpha = 0.2f)),
    ){
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.fillMaxWidth(),
        ) {
            leadingIcon()

            Column(
                modifier = Modifier.weight(1f),
            ) {
                Text(
                    textAlign = TextAlign.Start,
                    text = name.substringBeforeLast("."),
                    style = MaterialTheme.typography.bodySmall,
                    maxLines = 1
                )
                subTitle()
            }



//            Text(
//                text = size.byteCountToDisplaySize(),
//                style = MaterialTheme.typography.bodySmall
//            )

            // HH:mm MMM dd, yyyy
            val outputFormatter = DateTimeFormatter.ofPattern("HH:mm MMM dd, yyyy")
            Text(
                text = modifiedAt.format(outputFormatter),
                style = MaterialTheme.typography.bodySmall.copy(
                    color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f)
                ),
                fontWeight = FontWeight.SemiBold
            )
        }
    }
}