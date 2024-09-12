package fr.thomasbernard03.androidtools.presentation.fileexplorer

import androidx.lifecycle.viewModelScope
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
                    updateUiState { copy(loading = false, files = files) }
                }
            }
            is FileExplorerEvent.OnGetFiles -> {
                viewModelScope.launch {
                    updateUiState { copy(loading = true, path = event.path) }
                    val files = getFilesUseCase(path = event.path)
                    updateUiState { copy(loading = false, files = files) }
                }
            }
        }
    }
}