package fr.thomasbernard03.androidtools.presentation.applicationinstaller

import fr.thomasbernard03.androidtools.presentation.commons.Event

sealed class ApplicationInstallerEvent : Event {
    data class OnInstallApplication(val path: String) : ApplicationInstallerEvent()
}