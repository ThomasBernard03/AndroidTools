package fr.thomasbernard03.androidtools.commons.extensions

import androidx.compose.ui.graphics.Color
import fr.thomasbernard03.androidtools.domain.models.LogcatLevel
import fr.thomasbernard03.androidtools.presentation.theme.DebugBackgroundColor
import fr.thomasbernard03.androidtools.presentation.theme.ErrorBackgroundColor
import fr.thomasbernard03.androidtools.presentation.theme.InfoBackgroundColor
import fr.thomasbernard03.androidtools.presentation.theme.VerboseBackgroundColor
import fr.thomasbernard03.androidtools.presentation.theme.WarningBackgroundColor

fun LogcatLevel.backgroundColor() : Color {
    return when(this){
        LogcatLevel.V -> VerboseBackgroundColor
        LogcatLevel.D -> DebugBackgroundColor
        LogcatLevel.I -> InfoBackgroundColor
        LogcatLevel.W -> WarningBackgroundColor
        LogcatLevel.E -> ErrorBackgroundColor
    }
}