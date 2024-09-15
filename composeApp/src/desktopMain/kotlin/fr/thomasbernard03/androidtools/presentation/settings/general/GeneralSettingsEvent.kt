package fr.thomasbernard03.androidtools.presentation.settings.general

import fr.thomasbernard03.androidtools.presentation.commons.Event

sealed class GeneralSettingsEvent : Event {
    data object OnLoadSettings : GeneralSettingsEvent()
}