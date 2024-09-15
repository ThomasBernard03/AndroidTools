package fr.thomasbernard03.androidtools.presentation.information

import fr.thomasbernard03.androidtools.presentation.commons.UiState

data class InformationUiState(
    val loading : Boolean = false,

    val androidVersion : Int? = null,
    val manufacturer : String = "",
    val model : String = "",
    val battery : Int = 0,
    val serialNumber : String = "",

    val lines : Map<String, String> = emptyMap()
) : UiState