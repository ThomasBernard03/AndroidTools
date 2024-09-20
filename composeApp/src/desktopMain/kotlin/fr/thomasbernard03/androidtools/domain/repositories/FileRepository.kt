package fr.thomasbernard03.androidtools.domain.repositories

interface FileRepository {
    suspend fun uploadFile(path: String, targetPath : String)

    suspend fun deleteFile(path: String)
}