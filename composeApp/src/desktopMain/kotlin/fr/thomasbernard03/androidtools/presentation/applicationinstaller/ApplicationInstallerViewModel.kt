package fr.thomasbernard03.androidtools.presentation.applicationinstaller

import androidtools.composeapp.generated.resources.Res
import androidx.lifecycle.viewModelScope
import fr.thomasbernard03.androidtools.domain.usecases.InstallApplicationUseCase
import fr.thomasbernard03.androidtools.presentation.commons.BaseViewModel
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.ExperimentalResourceApi
import java.io.BufferedReader
import java.io.InputStreamReader

class ApplicationInstallerViewModel(
    private val installApplicationUseCase: InstallApplicationUseCase = InstallApplicationUseCase()
) : BaseViewModel<ApplicationInstallerUiState, ApplicationInstallerEvent>() {

    override fun initializeUiState() = ApplicationInstallerUiState()

    override fun onEvent(event: ApplicationInstallerEvent) {
        when(event){
            ApplicationInstallerEvent.OnAppearing -> {
                try {
                    val process = ProcessBuilder("/usr/local/bin/adb", "--version").start()
                    val reader = BufferedReader(InputStreamReader(process.inputStream))
                    val output = StringBuilder()

                    reader.forEachLine { line ->
                        output.append(line).append("\n")
                    }

                    val exitCode = process.waitFor()
                    if (exitCode == 0) {
                        updateUiState { copy(result = output.toString()) }
                    } else {
                        updateUiState { copy(result = "Error occurred while executing adb command") }

                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }

            is ApplicationInstallerEvent.OnInstallApplication -> {
                viewModelScope.launch {
                    updateUiState { copy(loading = true) }
                    val success = installApplicationUseCase(event.path)
                    updateUiState { copy(loading = false, result = if (success) "Application installed successfully" else "Error occurred while installing application") }
                }
            }
        }
    }
}