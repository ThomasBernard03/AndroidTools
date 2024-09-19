package fr.thomasbernard03.androidtools.presentation.fileexplorer

import androidx.lifecycle.viewModelScope
import fr.thomasbernard03.androidtools.domain.models.Folder
import fr.thomasbernard03.androidtools.domain.usecases.GetFilesUseCase
import fr.thomasbernard03.androidtools.presentation.commons.BaseViewModel
import kotlinx.coroutines.launch

class FileExplorerViewModel(
    private val getFilesUseCase: GetFilesUseCase = GetFilesUseCase()
) : BaseViewModel<FileExplorerUiState, FileExplorerEvent>() {

    override fun initializeUiState() = FileExplorerUiState()

    override fun onEvent(event: FileExplorerEvent) {
        when(event){
            FileExplorerEvent.OnAppearing -> {
                viewModelScope.launch {
                    updateUiState { copy(loading = true) }
                    val files = getFilesUseCase(path = "")
                    val folder = Folder().apply {
                        childens = files
                        name = "/"
                        path = ""
                    }
                    updateUiState { copy(loading = false, folder = folder) }
                }
            }
            is FileExplorerEvent.OnGetFiles -> {
                viewModelScope.launch {
                    updateUiState { copy(loading = true, path = "${event.folder.path}/${event.folder.name}") }
                    val files = getFilesUseCase(path = "${event.folder.path}/${event.folder.name}")

                    val newFolder = event.folder.apply {
                        parent = uiState.value.folder
                        childens = files
                    }

                    updateUiState { copy(loading = false, folder = newFolder) }
                }
            }

            FileExplorerEvent.OnGoBack -> {
                uiState.value.folder?.parent?.let { parent ->
                    updateUiState { copy(loading = false, folder = parent) }
                }
            }
        }
    }
}