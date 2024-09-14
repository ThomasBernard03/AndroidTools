package fr.thomasbernard03.androidtools.presentation.settings.appearance

import androidx.lifecycle.ViewModel
import fr.thomasbernard03.androidtools.presentation.commons.BaseViewModel

class AppearanceViewModel : BaseViewModel<AppearanceUiState, AppearanceEvent>() {

    override fun initializeUiState() = AppearanceUiState()

    override fun onEvent(event: AppearanceEvent) {
        when(event){
            AppearanceEvent.OnLoadSettings -> {

            }
            is AppearanceEvent.OnAutoThemeChange -> {
                updateUiState { copy(isAutoTheme = event.isAutoTheme) }
            }
        }
    }
}