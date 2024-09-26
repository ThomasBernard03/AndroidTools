package fr.thomasbernard03.androidtools.presentation.main

import androidx.lifecycle.viewModelScope
import com.russhwolf.settings.Settings
import fr.thomasbernard03.androidtools.commons.SettingsConstants
import fr.thomasbernard03.androidtools.domain.usecases.device.GetConnectedDevicesUseCase
import fr.thomasbernard03.androidtools.presentation.commons.BaseViewModel
import kotlinx.coroutines.launch

class MainViewModel(
    private val getConnectedDevicesUseCase: GetConnectedDevicesUseCase = GetConnectedDevicesUseCase(),
    private val settings : Settings = Settings()
) : BaseViewModel<MainUiState, MainEvent>() {

    override fun initializeUiState() = MainUiState()

    override fun onEvent(event: MainEvent) {
        when(event){
            is MainEvent.OnDeviceSelected -> {
                settings.putString(SettingsConstants.SELECTED_DEVICE_KEY, event.device)
                updateUiState { copy(selectedDevice = event.device) }
            }
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