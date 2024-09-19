package fr.thomasbernard03.androidtools.presentation.settings

import com.russhwolf.settings.Settings
import fr.thomasbernard03.androidtools.presentation.commons.BaseViewModel

class SettingsViewModel(
    private val settings : Settings = Settings()
) : BaseViewModel<SettingsUiState, SettingsEvent>() {

    override fun initializeUiState() = SettingsUiState()

    override fun onEvent(event: SettingsEvent) {
        when(event){
            SettingsEvent.OnAppearing -> {
            }
        }
    }
}