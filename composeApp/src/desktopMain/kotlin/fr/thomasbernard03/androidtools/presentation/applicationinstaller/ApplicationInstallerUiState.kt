package fr.thomasbernard03.androidtools.presentation.applicationinstaller

import fr.thomasbernard03.androidtools.presentation.commons.UiState

data class ApplicationInstallerUiState (
    val loading : Boolean = false,
) : UiState