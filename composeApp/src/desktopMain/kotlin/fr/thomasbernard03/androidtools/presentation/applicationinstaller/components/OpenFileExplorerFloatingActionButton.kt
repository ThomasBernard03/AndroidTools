package fr.thomasbernard03.androidtools.presentation.applicationinstaller.components

import androidtools.composeapp.generated.resources.Res
import androidtools.composeapp.generated.resources.folder
import androidtools.composeapp.generated.resources.open_file_explorer
import androidx.compose.foundation.Image
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import fr.thomasbernard03.androidtools.presentation.applicationinstaller.ApplicationInstallerEvent
import org.jetbrains.compose.resources.painterResource
import org.jetbrains.compose.resources.stringResource
import java.awt.FileDialog
import java.io.FilenameFilter

@Composable
fun OpenFileExplorerFloatingActionButton(
    onApkSelected : (String) -> Unit
) {
    FloatingActionButton(
        onClick = {
            val fileDialog = FileDialog(java.awt.Frame(), "", FileDialog.LOAD)
            fileDialog.filenameFilter = FilenameFilter { _, name -> name.endsWith(".apk") }
            fileDialog.isVisible = true
            val selectedFile = fileDialog.file
            val directory = fileDialog.directory

            if (selectedFile != null) {
                val apkPath = "$directory$selectedFile"
                onApkSelected(apkPath)
            }
        }
    ){
        Icon(
            painter = painterResource(Res.drawable.folder),
            contentDescription = stringResource(Res.string.open_file_explorer),
            tint = MaterialTheme.colorScheme.onBackground
        )
    }
}