package fr.thomasbernard03.androidtools.presentation.applicationinstaller.components

import androidx.compose.foundation.layout.Column
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import fr.thomasbernard03.androidtools.domain.models.InstallApplicationResult

@Composable
fun InstallApplicationResult(
    modifier : Modifier = Modifier,
    result : InstallApplicationResult
) {
    Column(
        modifier = modifier
    ) {
        when(result){
            is InstallApplicationResult.Success.Installed -> {
                Text("Application installed")
            }
            is InstallApplicationResult.Error -> {
                Text("Error when installing application")
            }
        }
    }
}