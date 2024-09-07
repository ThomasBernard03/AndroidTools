package fr.thomasbernard03.androidtools.presentation.information

import androidx.lifecycle.viewModelScope
import fr.thomasbernard03.androidtools.domain.usecases.GetDeviceInformationUseCase
import fr.thomasbernard03.androidtools.presentation.commons.BaseViewModel
import kotlinx.coroutines.launch

class InformationViewModel(
    private val getDeviceInformationUseCase: GetDeviceInformationUseCase = GetDeviceInformationUseCase()
) : BaseViewModel<InformationUiState, InformationEvent>() {

    override fun initializeUiState() = InformationUiState()

    override fun onEvent(event: InformationEvent) {
        when(event){
            InformationEvent.OnLoadInformation -> {
                viewModelScope.launch {
                    updateUiState { copy(loading = true) }
                    val deviceInformation = getDeviceInformationUseCase()
                    updateUiState { copy(loading = false, androidVersion = deviceInformation.version, model = deviceInformation.model, manufacturer = deviceInformation.manufacturer) }
                }
            }
        }
    }
}