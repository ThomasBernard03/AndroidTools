package fr.thomasbernard03.androidtools

import androidx.compose.material.MaterialTheme
import androidx.compose.ui.window.Window
import androidx.compose.ui.window.application
import fr.thomasbernard03.androidtools.presentation.main.MainScreen

fun main() = application {
    Window(
        onCloseRequest = ::exitApplication,
        title = "Android Tools",
    ) {
        MaterialTheme {
            MainScreen()
        }
    }
}