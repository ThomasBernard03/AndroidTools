package fr.thomasbernard03.androidtools.domain.usecases

import com.russhwolf.settings.Settings
import fr.thomasbernard03.androidtools.commons.SettingsConstants
import fr.thomasbernard03.androidtools.domain.models.DeviceInformation
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.BufferedReader
import java.io.InputStreamReader

class GetDeviceInformationUseCase(
    private val settings : Settings = Settings()
) {
    suspend operator fun invoke() : DeviceInformation = withContext(Dispatchers.IO) {
        val currentDevice = settings.getString(key = SettingsConstants.SELECTED_DEVICE_KEY, defaultValue = "")
        val process = ProcessBuilder("/usr/local/bin/adb", "-s", currentDevice, "shell", "getprop").start()
        val reader = BufferedReader(InputStreamReader(process.inputStream))
        val output = StringBuilder()

        reader.forEachLine { line ->
            output.append(line).append("\n")
        }

        val exitCode = process.waitFor()
        if (exitCode == 0) {
            parseDeviceInformation(output.toString())
        }

        parseDeviceInformation(output.toString())
    }

    private fun parseDeviceInformation(output : String) : DeviceInformation {
        val lines = output.split("\n")
        val manufacturer = lines.find { it.contains("ro.product.manufacturer") }?.split(":")?.get(1)?.replace("[", "")?.replace("]", "")?.trim() ?: ""
        val model = lines.find { it.contains("ro.product.model") }?.split(":")?.get(1)?.replace("[", "")?.replace("]", "")?.trim() ?: ""
        val version = lines.find { it.contains("ro.build.version.release") }?.split(":")?.get(1)?.replace("[", "")?.replace("]", "")?.trim() ?: ""
        val serial = lines.find { it.contains("ro.serialno") }?.split(":")?.get(1)?.replace("[", "")?.replace("]", "")?.trim() ?: ""
        return DeviceInformation(manufacturer, model, version.toInt(), serial)
    }
}