package fr.thomasbernard03.androidtools.presentation.information

import fr.thomasbernard03.androidtools.presentation.commons.Event

sealed class InformationEvent : Event {
    data object OnLoadInformation : InformationEvent()

    data class OnInputChanged(val input : String) : InformationEvent()
    data object OnClearInput : InformationEvent()
    data object OnDelete : InformationEvent()
}