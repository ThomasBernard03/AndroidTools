package fr.thomasbernard03.androidtools.domain.repositories

import fr.thomasbernard03.androidtools.domain.models.InstallApplicationResult

interface ApplicationRepository {
    /**
     * Install an application on the device
     * @param path the path of the .apk file on the local machine (computer)
     */
    suspend fun installApplication(path: String): InstallApplicationResult
}