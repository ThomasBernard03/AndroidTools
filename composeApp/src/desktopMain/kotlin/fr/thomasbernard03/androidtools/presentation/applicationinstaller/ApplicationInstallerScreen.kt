package fr.thomasbernard03.androidtools.presentation.applicationinstaller

import androidtools.composeapp.generated.resources.Res
import androidtools.composeapp.generated.resources.install_application_card_text
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
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
import androidx.compose.ui.unit.dp
import fr.thomasbernard03.androidtools.presentation.applicationinstaller.components.InstallApplicationResult
import fr.thomasbernard03.androidtools.presentation.applicationinstaller.components.OpenFileExplorerFloatingActionButton
import fr.thomasbernard03.androidtools.presentation.applicationinstaller.components.WavesAnimation
import org.jetbrains.compose.resources.stringResource

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
                    if (hoverred){
                        hoverred = false
                        if (externalDragValue.dragData is DragData.FilesList) {
                            val draggedFiles = (externalDragValue.dragData as DragData.FilesList).readFiles().map { it.drop(5) } // Remove file: prefix
                            draggedFiles.firstOrNull { it.endsWith(".apk") }?.let {
                                onEvent(ApplicationInstallerEvent.OnInstallApplication(it))
                            }
                        }
                    }
                }
            ),
        floatingActionButton = {
            OpenFileExplorerFloatingActionButton(
                onApkSelected = { onEvent(ApplicationInstallerEvent.OnInstallApplication(it)) }
            )
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

            ElevatedCard(
                modifier = Modifier.align(Alignment.TopStart).padding(16.dp).widthIn(max = 300.dp),
            ){
                Text(
                    modifier = Modifier.padding(16.dp),
                    text = stringResource(Res.string.install_application_card_text),
                )
            }

            if (uiState.result != null){
                InstallApplicationResult(
                    modifier = Modifier.align(Alignment.BottomStart).padding(8.dp),
                    result = uiState.result
                )
            }

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