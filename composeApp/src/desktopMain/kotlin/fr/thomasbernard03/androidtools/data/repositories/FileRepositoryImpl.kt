package fr.thomasbernard03.androidtools.data.repositories

import fr.thomasbernard03.androidtools.data.datasources.ShellDataSource
import fr.thomasbernard03.androidtools.domain.repositories.FileRepository
import org.koin.java.KoinJavaComponent.get

class FileRepositoryImpl(
    private val shellDataSource: ShellDataSource = get(ShellDataSource::class.java)
) : FileRepository {
    override suspend fun uploadFile(path: String, targetPath : String) {
        shellDataSource.executeAdbCommand("push", path, targetPath)
    }

    override suspend fun deleteFile(path: String) {
        shellDataSource.executeAdbCommand("shell", "rm", "'$path'")
    }

    override suspend fun downloadFile(path: String, targetPath: String) {
        shellDataSource.executeAdbCommand("pull", path, targetPath)
    }
}