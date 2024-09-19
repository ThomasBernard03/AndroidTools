package fr.thomasbernard03.androidtools.presentation.fileexplorer

import fr.thomasbernard03.androidtools.domain.models.File
import fr.thomasbernard03.androidtools.domain.models.Folder
import fr.thomasbernard03.androidtools.presentation.commons.UiState

data class FileExplorerUiState(
    val loading : Boolean = false,
    val folder: Folder? = null,

    val path : String = ""
) : UiState