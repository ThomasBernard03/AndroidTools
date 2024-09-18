package fr.thomasbernard03.androidtools.data.repositories

import fr.thomasbernard03.androidtools.data.datasources.ShellDataSource
import fr.thomasbernard03.androidtools.domain.models.InstallApplicationResult
import fr.thomasbernard03.androidtools.domain.repositories.ApplicationRepository
import org.koin.java.KoinJavaComponent.get

class ApplicationRepositoryImpl(
    private val shellDataSource: ShellDataSource = get(ShellDataSource::class.java)
) : ApplicationRepository {

    override suspend fun installApplication(path: String): InstallApplicationResult {
        val result = shellDataSource.executeAdbCommand("install", path)

        val apkName : String = path.substringAfterLast("/")
        return if (result.contains("success", ignoreCase = true)){
            InstallApplicationResult.Finished.Success(apkName, result)
        } else {
            InstallApplicationResult.Finished.Error(apkName, result)
        }
    }
}