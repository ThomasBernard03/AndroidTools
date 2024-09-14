package fr.thomasbernard03.androidtools.presentation.settings.appearance

import fr.thomasbernard03.androidtools.presentation.commons.Event

sealed class AppearanceEvent : Event {
    data object OnLoadSettings : AppearanceEvent()

    data class OnAutoThemeChange(val isAutoTheme: Boolean) : AppearanceEvent()
}