package fr.thomasbernard03.androidtools.presentation.information

import androidx.lifecycle.viewModelScope
import fr.thomasbernard03.androidtools.domain.usecases.device.DeleteTextUseCase
import fr.thomasbernard03.androidtools.domain.usecases.device.GetDeviceBatteryUseCase
import fr.thomasbernard03.androidtools.domain.usecases.device.GetDeviceInformationUseCase
import fr.thomasbernard03.androidtools.domain.usecases.device.SendInputUseCase
import fr.thomasbernard03.androidtools.presentation.commons.BaseViewModel
import kotlinx.coroutines.launch

class InformationViewModel(
    private val getDeviceInformationUseCase: GetDeviceInformationUseCase = GetDeviceInformationUseCase(),
    private val getDeviceBatteryUseCase: GetDeviceBatteryUseCase = GetDeviceBatteryUseCase(),
    private val sendInputUseCase: SendInputUseCase = SendInputUseCase(),
    private val deleteTextUseCase: DeleteTextUseCase = DeleteTextUseCase()
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

            is InformationEvent.OnInputChanged -> {
                val newInput = event.input.substringAfter(uiState.value.input)
                updateUiState { copy(input = event.input) }
                viewModelScope.launch {
                    sendInputUseCase(newInput)
                }
            }
            is InformationEvent.OnDelete -> {
                viewModelScope.launch {
                    deleteTextUseCase()
                }
            }

            InformationEvent.OnDelete -> {
                viewModelScope.launch {
                    deleteTextUseCase()
                    if (uiState.value.input.isNotEmpty()){
                        val newInput = uiState.value.input.dropLast(1)
                        updateUiState { copy(input = newInput) }
                    }
                }
            }

            InformationEvent.OnClearInput -> {
                viewModelScope.launch {
                    updateUiState { copy(input = "") }
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