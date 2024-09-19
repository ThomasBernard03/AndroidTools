package fr.thomasbernard03.androidtools.domain.usecases.file

import fr.thomasbernard03.androidtools.domain.repositories.FileRepository
import org.koin.java.KoinJavaComponent.get

class UploadFileUseCase(
    private val fileRepository: FileRepository = get(FileRepository::class.java)
) {
    suspend operator fun invoke(path: String, targetPath: String) {
        fileRepository.uploadFile(path, targetPath)
    }
}
