package fr.thomasbernard03.androidtools.domain.usecases

import com.russhwolf.settings.Settings
import fr.thomasbernard03.androidtools.commons.SettingsConstants
import fr.thomasbernard03.androidtools.domain.models.InstallApplicationResult
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.BufferedReader
import java.io.InputStreamReader

class InstallApplicationUseCase(
    private val settings: Settings = Settings()
) {
    suspend operator fun invoke(path : String) : InstallApplicationResult  = withContext(Dispatchers.IO) {
        try {
            val currentDevice = settings.getString(key = SettingsConstants.SELECTED_DEVICE, defaultValue = "")
            val process = ProcessBuilder("/usr/local/bin/adb", "-s", currentDevice, "install", path).start()
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            val output = StringBuilder()

            reader.forEachLine { line ->
                output.append(line).append("\n")
            }

            val exitCode = process.waitFor()

            if (exitCode == 0){
                return@withContext InstallApplicationResult.Success.Installed
            }

        } catch (e: Exception) {
            e.printStackTrace()
        }

        return@withContext InstallApplicationResult.Error.Unknown
    }
}