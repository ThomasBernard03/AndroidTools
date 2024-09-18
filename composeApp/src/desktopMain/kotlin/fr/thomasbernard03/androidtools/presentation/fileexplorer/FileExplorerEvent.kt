package fr.thomasbernard03.androidtools.presentation.fileexplorer

import fr.thomasbernard03.androidtools.presentation.commons.Event

sealed class FileExplorerEvent : Event {
    data object OnAppearing : FileExplorerEvent()

    data class OnGetFiles(val path: String) : FileExplorerEvent()
}