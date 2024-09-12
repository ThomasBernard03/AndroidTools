package fr.thomasbernard03.androidtools.presentation.fileexplorer

import fr.thomasbernard03.androidtools.domain.models.File
import fr.thomasbernard03.androidtools.presentation.commons.UiState

data class FileExplorerUiState(
    val loading : Boolean = false,
    val files : List<File> = emptyList(),

    val path : String = ""
) : UiState