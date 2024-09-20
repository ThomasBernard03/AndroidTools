package fr.thomasbernard03.androidtools.domain.usecases.file

import fr.thomasbernard03.androidtools.domain.repositories.FileRepository
import org.koin.java.KoinJavaComponent.get

class DeleteFileUseCase(
    private val fileRepository: FileRepository = get(FileRepository::class.java)
) {
    suspend operator fun invoke(path: String) {
        fileRepository.deleteFile(path)
    }
}