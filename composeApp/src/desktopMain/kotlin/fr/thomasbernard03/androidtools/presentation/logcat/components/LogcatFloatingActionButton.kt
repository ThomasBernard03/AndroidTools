package fr.thomasbernard03.androidtools.presentation.logcat.components

import androidtools.composeapp.generated.resources.Res
import androidtools.composeapp.generated.resources.arrow_down
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import org.jetbrains.compose.resources.painterResource

@Composable
fun LogcatFloatingActionButton(
    onClick : () -> Unit
) {
    FloatingActionButton(
        onClick = onClick
    ){
        Icon(
            painter = painterResource(Res.drawable.arrow_down),
            contentDescription = "load from files",
            tint = MaterialTheme.colorScheme.onBackground
        )
    }
}