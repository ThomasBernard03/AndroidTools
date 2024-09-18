package fr.thomasbernard03.androidtools.presentation.fileexplorer.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
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
import org.jetbrains.compose.resources.DrawableResource
import org.jetbrains.compose.resources.painterResource

@Composable
fun FileExplorerItem(
    modifier: Modifier = Modifier,
    onClick : () -> Unit,
    icon : DrawableResource,
    name: String,
    size : Long
) {
    Button(
        modifier = modifier,
        onClick = onClick,
        shape = RectangleShape,
        contentPadding = PaddingValues(start = 4.dp, end = 8.dp),
        elevation = ButtonDefaults.buttonElevation(
            defaultElevation = 0.dp,
            pressedElevation = 0.dp,
            hoveredElevation = 0.dp,
        ),
        colors = ButtonDefaults.buttonColors(
            containerColor = Color.Transparent,
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
                modifier = Modifier.size(12.dp)
            )

            Text(
                modifier = Modifier.weight(1f),
                textAlign = TextAlign.Start,
                text = name,
                style = MaterialTheme.typography.bodySmall
            )

            Text(
                text = size.byteCountToDisplaySize(),
                style = MaterialTheme.typography.bodySmall
            )
        }
    }
}