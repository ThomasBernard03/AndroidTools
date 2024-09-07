package fr.thomasbernard03.androidtools.presentation.main

import fr.thomasbernard03.androidtools.presentation.commons.UiState

data class MainUiState(
    val devices : List<String> = emptyList(),
    val selectedDevice : String? = null
) : UiState