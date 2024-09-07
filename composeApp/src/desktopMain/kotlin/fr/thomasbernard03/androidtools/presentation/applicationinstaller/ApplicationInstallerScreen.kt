package fr.thomasbernard03.androidtools.presentation.applicationinstaller

import androidtools.composeapp.generated.resources.Res
import androidtools.composeapp.generated.resources.folder
import androidtools.composeapp.generated.resources.open_file_explorer
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.DragData
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.onExternalDrag
import fr.thomasbernard03.androidtools.presentation.applicationinstaller.components.WavesAnimation
import org.jetbrains.compose.resources.painterResource
import org.jetbrains.compose.resources.stringResource
import java.awt.FileDialog
import java.io.FilenameFilter

@OptIn(ExperimentalComposeUiApi::class)
@Composable
fun ApplicationInstallerScreen(uiState : ApplicationInstallerUiState, onEvent: (ApplicationInstallerEvent) -> Unit) {

    var hoverred by remember { mutableStateOf(false) }

    Scaffold(
        modifier = Modifier
            .onExternalDrag(
                enabled = !uiState.loading,
                onDragStart = { hoverred = true },
                onDragExit = { hoverred = false },
                onDrop = { externalDragValue ->
                    hoverred = false
                    if (externalDragValue.dragData is DragData.FilesList) {
                        val draggedFiles = (externalDragValue.dragData as DragData.FilesList).readFiles().map { it.drop(5) } // Remove file: prefix
                        draggedFiles.firstOrNull()?.let {
                            onEvent(ApplicationInstallerEvent.OnInstallApplication(it))
                        }
                    }
                }
            ),
        floatingActionButton = {
            FloatingActionButton(
                onClick = {
                    val fileDialog = FileDialog(java.awt.Frame(), "", FileDialog.LOAD)
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
                    contentDescription = stringResource(Res.string.open_file_explorer)
                )
            }
        }
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .then(
                    if (hoverred)
                        Modifier.background(MaterialTheme.colorScheme.onBackground.copy(0.2f))
                    else
                        Modifier
                )
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