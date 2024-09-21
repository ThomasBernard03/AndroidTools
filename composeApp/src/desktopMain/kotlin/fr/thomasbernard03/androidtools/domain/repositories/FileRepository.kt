package fr.thomasbernard03.androidtools.domain.repositories

interface FileRepository {
    /**
     * Upload a file from the computer to the android device
     * @param path the path of the file to upload (On the computer)
     * @param targetPath the path where to upload the file (On the android device)
     */
    suspend fun uploadFile(path: String, targetPath : String)


    /**
     * Download a file from the android device to the computer
     * @param path the path of the file to download (On the android device)
     * @param targetPath the path where to download the file (On the computer)
     */
    suspend fun downloadFile(path: String, targetPath : String)



    suspend fun deleteFile(path: String)
}