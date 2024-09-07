package fr.thomasbernard03.androidtools.presentation.logcat

import fr.thomasbernard03.androidtools.presentation.commons.UiState

data class LogcatUiState(
    val loading : Boolean = false,
    val lines : List<String> = emptyList(),
) : UiState