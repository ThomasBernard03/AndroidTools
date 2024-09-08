package fr.thomasbernard03.androidtools.data.repositories

import com.russhwolf.settings.Settings
import fr.thomasbernard03.androidtools.commons.SettingsConstants
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.BufferedReader
import java.io.InputStreamReader

class ShellRepositoryImpl(
    private val settings: Settings = Settings()
) {
    suspend fun executeAdbCommand(vararg formatArgs: String) : String = withContext(Dispatchers.IO) {
        val arguments = mutableListOf<String>()

        val currentDevice = settings.getStringOrNull(key = SettingsConstants.SELECTED_DEVICE)

        if(currentDevice != null){
            arguments.add("-s")
            arguments.add(currentDevice)
        }

        arguments.addAll(formatArgs)

        val process = ProcessBuilder(listOf("/usr/local/bin/adb") + arguments).start()
        val reader = BufferedReader(InputStreamReader(process.inputStream))
        val output = StringBuilder()

        reader.forEachLine { line ->
            output.append(line).append("\n")
        }

        process.waitFor()

        return@withContext output.toString()
    }
}