package fr.thomasbernard03.androidtools.presentation.connectdevice

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier

@Composable
fun ConnectDeviceScreen() {
    Scaffold {
        Box(modifier = Modifier.fillMaxSize()) {
            Text(
                text = "No device connected, please connect one and retry",
                modifier = Modifier.align(Alignment.Center)
            )
        }
    }
}