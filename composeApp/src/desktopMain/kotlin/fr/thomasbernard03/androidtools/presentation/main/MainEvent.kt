package fr.thomasbernard03.androidtools.presentation.main

import fr.thomasbernard03.androidtools.presentation.commons.Event

sealed class MainEvent : Event {
    data object OnLoadDevices : MainEvent()
    data class OnDeviceSelected(val device : String) : MainEvent()
}