package fr.thomasbernard03.androidtools.presentation.applicationinstaller

import androidx.lifecycle.viewModelScope
import fr.thomasbernard03.androidtools.domain.usecases.application.InstallApplicationUseCase
import fr.thomasbernard03.androidtools.presentation.commons.BaseViewModel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class ApplicationInstallerViewModel(
    private val installApplicationUseCase: InstallApplicationUseCase = InstallApplicationUseCase()
) : BaseViewModel<ApplicationInstallerUiState, ApplicationInstallerEvent>() {

    override fun initializeUiState() = ApplicationInstallerUiState()

    override fun onEvent(event: ApplicationInstallerEvent) {
        when(event){
            is ApplicationInstallerEvent.OnInstallApplication -> {
                viewModelScope.launch {
                    updateUiState { copy(loading = true, result = null) }
                    installApplicationUseCase(event.path){ status ->
                        updateUiState { copy(result = status) }
                    }
                    updateUiState { copy(loading = false) }
                    delay(3000)
                    updateUiState { copy(result = null) }
                }
            }
        }
    }
}