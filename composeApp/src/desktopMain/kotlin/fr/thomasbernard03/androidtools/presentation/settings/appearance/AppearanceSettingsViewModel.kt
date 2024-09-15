package fr.thomasbernard03.androidtools.presentation.settings.appearance

import fr.thomasbernard03.androidtools.presentation.commons.BaseViewModel

class AppearanceSettingsViewModel : BaseViewModel<AppearanceSettingsUiState, AppearanceSettingsEvent>() {

    override fun initializeUiState() = AppearanceSettingsUiState()

    override fun onEvent(event: AppearanceSettingsEvent) {
        when(event){
            AppearanceSettingsEvent.OnLoadSettings -> {

            }
            is AppearanceSettingsEvent.OnAutoThemeChange -> {
                updateUiState { copy(isAutoTheme = event.isAutoTheme) }
            }
        }
    }
}