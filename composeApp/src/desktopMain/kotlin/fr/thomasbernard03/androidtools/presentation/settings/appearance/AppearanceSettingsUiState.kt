package fr.thomasbernard03.androidtools.presentation.settings.appearance

import fr.thomasbernard03.androidtools.presentation.commons.UiState

data class AppearanceSettingsUiState(
    val isAutoTheme : Boolean = true,
) : UiState