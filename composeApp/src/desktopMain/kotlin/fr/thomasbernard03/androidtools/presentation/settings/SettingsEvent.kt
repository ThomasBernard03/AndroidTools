package fr.thomasbernard03.androidtools.presentation.settings

import fr.thomasbernard03.androidtools.presentation.commons.Event

sealed class SettingsEvent : Event {
    data object OnAppearing : SettingsEvent()
}