package fr.thomasbernard03.androidtools.commons.extensions

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import fr.thomasbernard03.androidtools.domain.models.LogcatLevel
import fr.thomasbernard03.androidtools.presentation.theme.DebugBackgroundColorDark
import fr.thomasbernard03.androidtools.presentation.theme.DebugBackgroundColorLight
import fr.thomasbernard03.androidtools.presentation.theme.ErrorBackgroundColorDark
import fr.thomasbernard03.androidtools.presentation.theme.ErrorBackgroundColorLight
import fr.thomasbernard03.androidtools.presentation.theme.InfoBackgroundColorDark
import fr.thomasbernard03.androidtools.presentation.theme.InfoBackgroundColorLight
import fr.thomasbernard03.androidtools.presentation.theme.VerboseBackgroundColorDark
import fr.thomasbernard03.androidtools.presentation.theme.VerboseBackgroundColorLight
import fr.thomasbernard03.androidtools.presentation.theme.WarningBackgroundColorDark
import fr.thomasbernard03.androidtools.presentation.theme.WarningBackgroundColorLight

@Composable
fun LogcatLevel.backgroundColor() : Color {
    if (!isSystemInDarkTheme()){
        return when(this){
            LogcatLevel.V -> VerboseBackgroundColorLight
            LogcatLevel.D -> DebugBackgroundColorLight
            LogcatLevel.I -> InfoBackgroundColorLight
            LogcatLevel.W -> WarningBackgroundColorLight
            LogcatLevel.E -> ErrorBackgroundColorLight
            LogcatLevel.F -> ErrorBackgroundColorLight
        }
    }
    else {
        return when(this){
            LogcatLevel.V -> VerboseBackgroundColorDark
            LogcatLevel.D -> DebugBackgroundColorDark
            LogcatLevel.I -> InfoBackgroundColorDark
            LogcatLevel.W -> WarningBackgroundColorDark
            LogcatLevel.E -> ErrorBackgroundColorDark
            LogcatLevel.F -> ErrorBackgroundColorDark
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
            LogcatLevel.V -> VerboseBackgroundColorLight
            LogcatLevel.D -> Color(0xFF39A0D6)
            LogcatLevel.I -> Color(0xFF59A869)
            LogcatLevel.W -> Color(0xFF655708)
            LogcatLevel.E -> Color(0xFFCD0000)
            LogcatLevel.F -> Color(0xFFCD0000)
        }
    }
    else {
        return when(this){
            LogcatLevel.V -> VerboseBackgroundColorLight
            LogcatLevel.D -> DebugBackgroundColorLight
            LogcatLevel.I -> InfoBackgroundColorLight
            LogcatLevel.W -> WarningBackgroundColorLight
            LogcatLevel.E -> ErrorBackgroundColorLight
            LogcatLevel.F -> ErrorBackgroundColorLight
        }
    }
}