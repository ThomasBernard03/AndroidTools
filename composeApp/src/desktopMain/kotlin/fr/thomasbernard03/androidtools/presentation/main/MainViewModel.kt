package fr.thomasbernard03.androidtools.presentation.main

import androidx.lifecycle.viewModelScope
import fr.thomasbernard03.androidtools.domain.usecases.GetConnectedDevicesUseCase
import fr.thomasbernard03.androidtools.presentation.commons.BaseViewModel
import kotlinx.coroutines.launch

class MainViewModel(
    private val getConnectedDevicesUseCase: GetConnectedDevicesUseCase = GetConnectedDevicesUseCase()
) : BaseViewModel<MainUiState, MainEvent>() {

    override fun initializeUiState() = MainUiState()

    override fun onEvent(event: MainEvent) {
        when(event){
            is MainEvent.OnDeviceSelected -> updateUiState { copy(selectedDevice = event.device) }
            MainEvent.OnLoadDevices -> {
                viewModelScope.launch {
                    getConnectedDevicesUseCase().collect { devices ->
                        updateUiState { copy(devices = devices.toList()) }

                        if (!devices.contains(uiState.value.selectedDevice))
                            updateUiState { copy(selectedDevice = null) }
                    }
                }
            }
        }
    }
}