package fr.thomasbernard03.androidtools.data.repositories

import androidtools.composeapp.generated.resources.Res
import com.russhwolf.settings.Settings
import fr.thomasbernard03.androidtools.commons.SettingsConstants
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.jetbrains.compose.resources.ExperimentalResourceApi
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader

class ShellRepositoryImpl(
    private val settings: Settings = Settings()
) {
    suspend fun executeAdbCommand(vararg formatArgs: String): String = withContext(Dispatchers.IO) {
        val arguments = mutableListOf<String>()

        val currentDevice = settings.getStringOrNull(key = SettingsConstants.SELECTED_DEVICE_KEY)

        if (currentDevice != null) {
            arguments.add("-s")
            arguments.add(currentDevice)
        }

        arguments.addAll(formatArgs)

        val adb = getAdb()

        val process = ProcessBuilder(listOf(adb.absolutePath) + arguments).start()
        val reader = BufferedReader(InputStreamReader(process.inputStream))
        val output = StringBuilder()

        reader.forEachLine { line ->
            output.append(line).append("\n")
        }

        process.waitFor()

        return@withContext output.toString()
    }

    @OptIn(ExperimentalResourceApi::class)
    private suspend fun getAdb(): File {
        settings.getStringOrNull(key = SettingsConstants.ADB_PATH_KEY)?.let {

            if (File(it).isFile) {
                return File(it)
            }
        }

        val adbBytes: ByteArray = Res.readBytes("files/adb")
        val tempFile = withContext(Dispatchers.IO) {
            File.createTempFile("adb-temp", null)
        }.apply {
            writeBytes(adbBytes)
            setExecutable(true)
        }

        settings.putString(key = SettingsConstants.ADB_PATH_KEY, value = tempFile.absolutePath)
        return tempFile
    }
}
