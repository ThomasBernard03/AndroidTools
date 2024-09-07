package fr.thomasbernard03.androidtools

import androidx.compose.ui.window.Window
import androidx.compose.ui.window.application

fun main() = application {
    Window(
        onCloseRequest = ::exitApplication,
        title = "Android Tools",
    ) {
        App()
    }
}