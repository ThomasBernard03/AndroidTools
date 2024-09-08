package fr.thomasbernard03.androidtools.domain.usecases

import com.russhwolf.settings.Settings
import fr.thomasbernard03.androidtools.commons.SettingsConstants
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.BufferedReader
import java.io.InputStreamReader

class ClearLogcatUseCase(
    private val settings : Settings = Settings()
) {
    suspend operator fun invoke()  = withContext(Dispatchers.IO) {
        try {
            val currentDevice = settings.getString(key = SettingsConstants.SELECTED_DEVICE, defaultValue = "")
            val process = ProcessBuilder("/usr/local/bin/adb", "-s", currentDevice, "logcat", "c").start()
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            val output = StringBuilder()

            reader.forEachLine { line ->
                output.append(line).append("\n")
            }

            val exitCode = process.waitFor()
            return@withContext exitCode == 0
        } catch (e: Exception) {
            e.printStackTrace()
            return@withContext false
        }
    }
}