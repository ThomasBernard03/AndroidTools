package fr.thomasbernard03.androidtools.presentation.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color


private val LightColorScheme = lightColorScheme(
    primary = Color(0xFF383B27),

    primaryContainer = Color(0xFFD1D7BD),
    onPrimaryContainer = Color(0xFF555C3B),

    secondaryContainer = Color(0xFFF5F6F0)
)

private val DarkColorScheme = darkColorScheme(
)

@Composable
fun AndroidToolsTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }

    MaterialTheme(
        colorScheme = colorScheme,
        content = content
    )
}