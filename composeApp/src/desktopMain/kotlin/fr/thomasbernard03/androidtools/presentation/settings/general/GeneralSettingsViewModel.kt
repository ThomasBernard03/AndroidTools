package fr.thomasbernard03.androidtools.presentation.settings.general

import androidx.lifecycle.viewModelScope
import fr.thomasbernard03.androidtools.domain.usecases.GetAdbVersionUseCase
import fr.thomasbernard03.androidtools.presentation.commons.BaseViewModel
import kotlinx.coroutines.launch

class GeneralSettingsViewModel(
    private val getAdbVersionUseCase: GetAdbVersionUseCase = GetAdbVersionUseCase()
) : BaseViewModel<GeneralSettingsUiState, GeneralSettingsEvent>() {

    override fun initializeUiState() = GeneralSettingsUiState()

    override fun onEvent(event: GeneralSettingsEvent) {
        when(event){
            GeneralSettingsEvent.OnLoadSettings -> {
                viewModelScope.launch {
                    val adbVersion = getAdbVersionUseCase()
                    updateUiState { copy(adbVersion = adbVersion) }
                }
            }
        }
    }
}