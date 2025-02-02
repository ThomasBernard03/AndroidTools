package fr.thomasbernard03.androidtools.presentation.logcat

import fr.thomasbernard03.androidtools.presentation.commons.Event

sealed class LogcatEvent : Event {
    data object OnGetAllPackages : LogcatEvent()
    data class OnStartListening(val packageName: String? = null) : LogcatEvent()
    data object OnStopListening : LogcatEvent()
    data object OnClear : LogcatEvent()
    data object OnRestart : LogcatEvent()

    data class OnPackageSelected(val packageName: String?) : LogcatEvent()
}