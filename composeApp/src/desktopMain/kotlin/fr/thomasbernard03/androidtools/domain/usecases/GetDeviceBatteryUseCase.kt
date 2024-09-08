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

class GetDeviceBatteryUseCase(
    private val settings: Settings = Settings()
) {
    fun invoke(): Flow<Int> = channelFlow {
        withContext(Dispatchers.IO) {
            val currentDevice = settings.getString(key = SettingsConstants.SELECTED_DEVICE, defaultValue = "")
            val process = ProcessBuilder("/usr/local/bin/adb", "-s", currentDevice, "shell", "dumpsys", "battery").start()
            val reader = BufferedReader(InputStreamReader(process.inputStream))

            try {
                while (true) {
                    val output = StringBuilder()
                    reader.use { bufferedReader ->
                        bufferedReader.forEachLine { line ->
                            output.append(line).append("\n")
                        }
                    }

                    val batteryLevel = parseBatteryLevel(output.toString())
                    send(batteryLevel)

                    kotlinx.coroutines.delay(20000) // Read battery level every 20 seconds
                }
            } finally {
                process.destroy()
            }
        }
    }

    private fun parseBatteryLevel(output: String): Int {
        val levelLine = output.lines().find { it.trim().startsWith("level:") }
        return levelLine?.split(":")?.get(1)?.trim()?.replace("[","")?.replace("]", "")?.toIntOrNull() ?: 0
    }
}
