package fr.thomasbernard03.androidtools.presentation.settings.appearance

import fr.thomasbernard03.androidtools.presentation.commons.Event

sealed class AppearanceSettingsEvent : Event {
    data object OnLoadSettings : AppearanceSettingsEvent()

    data class OnAutoThemeChange(val isAutoTheme: Boolean) : AppearanceSettingsEvent()
}