package fr.thomasbernard03.androidtools.presentation.information

import androidx.lifecycle.viewModelScope
import fr.thomasbernard03.androidtools.domain.usecases.GetDeviceInformationUseCase
import fr.thomasbernard03.androidtools.domain.usecases.device.GetDeviceBatteryUseCase
import fr.thomasbernard03.androidtools.presentation.commons.BaseViewModel
import kotlinx.coroutines.launch

class InformationViewModel(
    private val getDeviceInformationUseCase: GetDeviceInformationUseCase = GetDeviceInformationUseCase(),
    private val getDeviceBatteryUseCase: GetDeviceBatteryUseCase = GetDeviceBatteryUseCase(),
) : BaseViewModel<InformationUiState, InformationEvent>() {

    override fun initializeUiState() = InformationUiState()

    override fun onEvent(event: InformationEvent) {
        when(event){
            InformationEvent.OnLoadInformation -> {
                checkDeviceBattery()
                viewModelScope.launch {
                    updateUiState { copy(loading = true) }
                    val deviceInformation = getDeviceInformationUseCase()
                    updateUiState {
                        copy(
                            loading = false,
                            androidVersion = deviceInformation.version,
                            model = deviceInformation.model,
                            manufacturer = deviceInformation.manufacturer,
                            lines = deviceInformation.lines,
                            serialNumber = deviceInformation.serial
                        )
                    }
                }
            }
        }
    }

    private fun checkDeviceBattery() {
        viewModelScope.launch {
            getDeviceBatteryUseCase.invoke().collect { battery ->
                updateUiState {
                    copy(battery = battery)
                }
            }
        }
    }
}