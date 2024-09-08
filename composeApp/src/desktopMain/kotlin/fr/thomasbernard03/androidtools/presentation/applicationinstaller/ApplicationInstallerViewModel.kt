package fr.thomasbernard03.androidtools.presentation.applicationinstaller

import androidtools.composeapp.generated.resources.Res
import androidx.lifecycle.viewModelScope
import fr.thomasbernard03.androidtools.domain.usecases.InstallApplicationUseCase
import fr.thomasbernard03.androidtools.presentation.commons.BaseViewModel
import kotlinx.coroutines.delay
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
            is ApplicationInstallerEvent.OnInstallApplication -> {
                viewModelScope.launch {
                    updateUiState { copy(loading = true, result = null) }
                    val result = installApplicationUseCase(event.path)
                    updateUiState { copy(loading = false, result = result) }
                    delay(3000)
                    updateUiState { copy(result = null) }
                }
            }
        }
    }
}