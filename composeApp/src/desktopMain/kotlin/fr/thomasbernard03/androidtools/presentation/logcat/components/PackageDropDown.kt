package fr.thomasbernard03.androidtools.presentation.logcat.components

import androidtools.composeapp.generated.resources.Res
import androidtools.composeapp.generated.resources.arrow_down
import androidtools.composeapp.generated.resources.filter
import androidtools.composeapp.generated.resources.pause
import androidtools.composeapp.generated.resources.play
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Divider
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import org.jetbrains.compose.resources.painterResource

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PackageDropDown(
    modifier : Modifier = Modifier,
    selection : String?,
    onSelectionChange: (String?) -> Unit,
    items: List<String>
) { 
    var expanded by rememberSaveable { mutableStateOf(false) }

    IconButton(
        modifier = Modifier,
        onClick = { expanded = true },
    ) {
        Icon(
            painter = painterResource(Res.drawable.filter),
            contentDescription = "choose a package",
            tint = MaterialTheme.colorScheme.onBackground
        )
    }

    DropdownMenu(
        expanded = expanded,
        onDismissRequest = { expanded = false }
    ) {
        DropdownMenuItem(
            onClick = {
                expanded = false
                onSelectionChange(null)
            },
            text = {
                Text(
                    text = "Display all packages",
                    style = MaterialTheme.typography.bodySmall
                )
            }
        )

        HorizontalDivider()

        items.sortedBy { it }.forEach { device ->
            DropdownMenuItem(
                contentPadding = PaddingValues(horizontal = 4.dp),
                onClick = {
                    onSelectionChange(device)
                    expanded = false
                },
                text = {
                    Text(
                        text = device,
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            )
        }
    }
}