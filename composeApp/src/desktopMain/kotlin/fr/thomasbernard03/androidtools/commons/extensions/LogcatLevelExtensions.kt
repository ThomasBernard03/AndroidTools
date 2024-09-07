package fr.thomasbernard03.androidtools.commons.extensions

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import fr.thomasbernard03.androidtools.domain.models.LogcatLevel
import fr.thomasbernard03.androidtools.presentation.theme.DebugBackgroundColor
import fr.thomasbernard03.androidtools.presentation.theme.ErrorBackgroundColor
import fr.thomasbernard03.androidtools.presentation.theme.InfoBackgroundColor
import fr.thomasbernard03.androidtools.presentation.theme.VerboseBackgroundColor
import fr.thomasbernard03.androidtools.presentation.theme.WarningBackgroundColor

@Composable
fun LogcatLevel.backgroundColor() : Color {
    if (!isSystemInDarkTheme()){
        return when(this){
            LogcatLevel.V -> VerboseBackgroundColor
            LogcatLevel.D -> DebugBackgroundColor
            LogcatLevel.I -> InfoBackgroundColor
            LogcatLevel.W -> WarningBackgroundColor
            LogcatLevel.E -> ErrorBackgroundColor
        }
    }
    else {
        return when(this){
            LogcatLevel.V -> VerboseBackgroundColor
            LogcatLevel.D -> DebugBackgroundColor
            LogcatLevel.I -> InfoBackgroundColor
            LogcatLevel.W -> WarningBackgroundColor
            LogcatLevel.E -> ErrorBackgroundColor
        }
    }
}

@Composable
fun LogcatLevel.onBackgroundColor() : Color {
    if (!isSystemInDarkTheme()){
        return when(this){
            LogcatLevel.E -> MaterialTheme.colorScheme.background
            else -> MaterialTheme.colorScheme.onBackground
        }
    }
    else {
        return when(this){
            LogcatLevel.E -> MaterialTheme.colorScheme.background
            else -> MaterialTheme.colorScheme.onBackground
        }
    }
}

@Composable
fun LogcatLevel.messageColor() : Color {
    if (!isSystemInDarkTheme()){
        return when(this){
            LogcatLevel.V -> VerboseBackgroundColor
            LogcatLevel.D -> Color(0xFF39A0D6)
            LogcatLevel.I -> Color(0xFF59A869)
            LogcatLevel.W -> Color(0xFF655708)
            LogcatLevel.E -> Color(0xFFCD0000)
        }
    }
    else {
        return when(this){
            LogcatLevel.V -> VerboseBackgroundColor
            LogcatLevel.D -> DebugBackgroundColor
            LogcatLevel.I -> InfoBackgroundColor
            LogcatLevel.W -> WarningBackgroundColor
            LogcatLevel.E -> ErrorBackgroundColor
        }
    }
}