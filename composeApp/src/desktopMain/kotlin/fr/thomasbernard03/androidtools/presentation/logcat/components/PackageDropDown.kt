package fr.thomasbernard03.androidtools.presentation.logcat.components

import androidtools.composeapp.generated.resources.Res
import androidtools.composeapp.generated.resources.arrow_down
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Divider
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
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

    ExposedDropdownMenuBox(
        modifier = modifier,
        expanded = expanded,
        onExpandedChange = { expanded = it },
    ) {
        Button(
            modifier = Modifier.menuAnchor().fillMaxWidth(),
            onClick = {},
            shape = RoundedCornerShape(4.dp),
            colors = ButtonDefaults.buttonColors(
                containerColor = Color.Transparent,
                contentColor = MaterialTheme.colorScheme.onBackground
            ),
            elevation = ButtonDefaults.buttonElevation(
                defaultElevation = 0.dp,
                pressedElevation = 0.dp,
                hoveredElevation = 0.dp,
                focusedElevation = 0.dp
            ),
            contentPadding = PaddingValues(start = 8.dp, top = 4.dp, end = 4.dp, bottom = 4.dp)
        ){
            Row(
                horizontalArrangement = Arrangement.SpaceBetween,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    text = selection ?: "Select a package",
                )

                Icon(
                    painterResource(Res.drawable.arrow_down),
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onBackground
                )
            }
        }

        ExposedDropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false }
        ) {
            DropdownMenuItem(
                contentPadding = PaddingValues(4.dp),
                onClick = {
                    onSelectionChange(null)
                    expanded = false
                },
                text = {
                    Text(
                        text = "Display all packages",
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            )

            HorizontalDivider()

            items.forEach { device ->
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
}