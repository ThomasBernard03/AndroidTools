package fr.thomasbernard03.androidtools.domain.usecases

import com.russhwolf.settings.Settings
import fr.thomasbernard03.androidtools.commons.SettingsConstants
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.channelFlow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.withContext
import java.io.BufferedReader
import java.io.InputStreamReader

class GetLogcatUseCase(
    private val settings: Settings = Settings()
) {
    fun invoke(): Flow<String> = channelFlow {
        withContext(Dispatchers.IO) {
            val currentDevice = settings.getString(key = SettingsConstants.SELECTED_DEVICE, defaultValue = "")
            val process = ProcessBuilder("/usr/local/bin/adb", "-s", currentDevice, "logcat").start()
            val reader = BufferedReader(InputStreamReader(process.inputStream))

            try {
                reader.use { bufferedReader ->
                    var line: String?
                    while (bufferedReader.readLine().also { line = it } != null) {
                        send(line!!)
                    }
                }
            } finally {
                process.destroy()
            }
        }
    }
}