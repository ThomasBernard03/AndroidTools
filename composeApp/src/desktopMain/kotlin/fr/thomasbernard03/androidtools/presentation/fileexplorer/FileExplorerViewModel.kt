package fr.thomasbernard03.androidtools.presentation.fileexplorer

import androidx.lifecycle.viewModelScope
import fr.thomasbernard03.androidtools.domain.models.Folder
import fr.thomasbernard03.androidtools.domain.usecases.GetFilesUseCase
import fr.thomasbernard03.androidtools.domain.usecases.file.DeleteFileUseCase
import fr.thomasbernard03.androidtools.domain.usecases.file.UploadFileUseCase
import fr.thomasbernard03.androidtools.presentation.commons.BaseViewModel
import kotlinx.coroutines.launch

class FileExplorerViewModel(
    private val getFilesUseCase: GetFilesUseCase = GetFilesUseCase(),
    private val uploadFileUseCase: UploadFileUseCase = UploadFileUseCase(),
    private val deleteFileUseCase : DeleteFileUseCase = DeleteFileUseCase()
) : BaseViewModel<FileExplorerUiState, FileExplorerEvent>() {

    override fun initializeUiState() = FileExplorerUiState()

    override fun onEvent(event: FileExplorerEvent) {
        when(event){
            is FileExplorerEvent.OnFileSelected -> updateUiState { copy(selectedFile = event.file) }
            FileExplorerEvent.OnAppearing -> {
                viewModelScope.launch {
                    updateUiState { copy(loading = true) }
                    val files = getFilesUseCase(path = "storage/emulated/0")
                    val folder = Folder().apply {
                        childens = files
                        name = ""
                        path = "storage/emulated/0"
                    }
                    updateUiState { copy(loading = false, folder = folder) }
                }
            }
            is FileExplorerEvent.OnGetFiles -> {
                viewModelScope.launch {
                    updateUiState { copy(loading = true, selectedFile = null) }
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
                    updateUiState { copy(folder = parent, selectedFile = null) }
                }
            }

            FileExplorerEvent.OnRefresh -> {
                uiState.value.folder?.let { folder ->
                    viewModelScope.launch {
                        updateUiState { copy(loading = true, selectedFile = null) }
                        val files = getFilesUseCase(path = "${folder.path}/${folder.name}")

                        folder.childens = files

                        updateUiState { copy(loading = false, folder = folder) }
                    }
                }
            }

            is FileExplorerEvent.OnAddFile -> {
                uiState.value.folder?.let { targetFolder ->
                    viewModelScope.launch {
                        updateUiState { copy(loading = true, selectedFile = null) }
                        uploadFileUseCase(event.path, "${targetFolder.path}/${targetFolder.name}")
                        val files = getFilesUseCase(path = "${targetFolder.path}/${targetFolder.name}")
                        targetFolder.childens = files
                        updateUiState { copy(loading = false, folder = targetFolder) }
                    }
                }
            }
            is FileExplorerEvent.OnDelete -> {
                viewModelScope.launch {
                    uiState.value.folder?.let { folder ->
                        updateUiState { copy(loading = true, selectedFile = null) }
                        deleteFileUseCase(event.path)
                        val files = getFilesUseCase(path = "${folder.path}/${folder.name}")
                        folder.childens = files
                        updateUiState { copy(loading = false, folder = folder) }
                    }
                }
            }

            is FileExplorerEvent.OnDownload -> {
                viewModelScope.launch {
                    uiState.value.folder?.let { folder ->
                        updateUiState { copy(loading = true) }
                        uploadFileUseCase(event.path, event.targetPath)
                        val files = getFilesUseCase(path = "${uiState.value.folder?.path}/${uiState.value.folder?.name}")
                        folder.childens = files
                        updateUiState { copy(loading = false, folder = folder) }
                    }
                }
            }
        }
    }
}