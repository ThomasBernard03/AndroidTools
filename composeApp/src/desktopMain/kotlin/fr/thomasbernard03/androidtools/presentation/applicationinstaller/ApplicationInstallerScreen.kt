package fr.thomasbernard03.androidtools.presentation.applicationinstaller

import androidtools.composeapp.generated.resources.Res
import androidtools.composeapp.generated.resources.folder
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import fr.thomasbernard03.androidtools.presentation.applicationinstaller.components.WavesAnimation
import org.jetbrains.compose.resources.painterResource
import java.awt.FileDialog
import java.io.FilenameFilter

@Composable
fun ApplicationInstallerScreen(uiState : ApplicationInstallerUiState, onEvent: (ApplicationInstallerEvent) -> Unit) {

    Scaffold(
        floatingActionButton = {
            FloatingActionButton(
                onClick = {
                    val fileDialog = FileDialog(java.awt.Frame(), "Choose a file", FileDialog.LOAD)
                    fileDialog.filenameFilter = FilenameFilter { _, name -> name.endsWith(".apk") }
                    fileDialog.isVisible = true
                    val selectedFile = fileDialog.file
                    val directory = fileDialog.directory

                    if (selectedFile != null) {
                        val apkPath = "$directory$selectedFile"
                        onEvent(ApplicationInstallerEvent.OnInstallApplication(apkPath))
                    }
                }
            ){
                Image(
                    painter = painterResource(Res.drawable.folder),
                    contentDescription = "load from files"
                )
            }
        }
    ) {


        Box(
            modifier = Modifier.fillMaxSize()
        ) {
            WavesAnimation()

            AnimatedVisibility(
                visible = uiState.loading,
                modifier = Modifier.align(Alignment.BottomStart)
            ){
                LinearProgressIndicator(
                    modifier = Modifier.fillMaxWidth()
                )
            }
        }
    }
}