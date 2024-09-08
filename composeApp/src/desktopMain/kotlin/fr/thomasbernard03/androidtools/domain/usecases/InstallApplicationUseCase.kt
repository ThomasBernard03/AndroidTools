package fr.thomasbernard03.androidtools.domain.usecases

import com.russhwolf.settings.Settings
import fr.thomasbernard03.androidtools.commons.SettingsConstants
import fr.thomasbernard03.androidtools.data.repositories.ShellRepositoryImpl
import fr.thomasbernard03.androidtools.domain.models.InstallApplicationResult
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.BufferedReader
import java.io.InputStreamReader

class InstallApplicationUseCase(
    private val settings: Settings = Settings(),
    private val shellRepositoryImpl: ShellRepositoryImpl = ShellRepositoryImpl()
) {
    suspend operator fun invoke(path : String) : InstallApplicationResult  = withContext(Dispatchers.IO) {

        val result = shellRepositoryImpl.executeAdbCommand("install", path)

        val apkName : String = path.substringAfterLast("/")
        if (result.contains("success", ignoreCase = true)){
            return@withContext InstallApplicationResult.Success(apkName)
        }
        else {
            return@withContext InstallApplicationResult.Error(result, apkName)
        }
    }
}