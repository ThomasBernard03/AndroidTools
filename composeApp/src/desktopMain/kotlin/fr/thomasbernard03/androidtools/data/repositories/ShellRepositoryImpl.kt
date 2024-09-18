package fr.thomasbernard03.androidtools.data.repositories

import androidtools.composeapp.generated.resources.Res
import com.russhwolf.settings.Settings
import fr.thomasbernard03.androidtools.commons.SettingsConstants
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.channelFlow
import kotlinx.coroutines.withContext
import org.jetbrains.compose.resources.ExperimentalResourceApi
import java.io.BufferedReader
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.io.InputStreamReader
import java.util.zip.ZipInputStream

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

    suspend fun executeAdbCommandFlow(vararg formatArgs: String): Flow<String> = channelFlow {
        withContext(Dispatchers.IO){
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

    @OptIn(ExperimentalResourceApi::class)
    private suspend fun getAdb(): File {
        settings.getStringOrNull(key = SettingsConstants.ADB_PATH_KEY)?.let {
            if (File(it).isFile) {
                return File(it)
            }
        }

        val adbBytes: ByteArray = Res.readBytes("files/adb_darwin")

        val tempFile = withContext(Dispatchers.IO) {
            File.createTempFile("android_tools_adb_temp", "darwin")
        }.apply {
            writeBytes(adbBytes)

            setExecutable(true, false)

            if (!canExecute()) {
                throw IllegalStateException("ADB temp file is not executable")
            }
        }

        settings.putString(key = SettingsConstants.ADB_PATH_KEY, value = tempFile.absolutePath)

        return tempFile
    }


    @OptIn(ExperimentalResourceApi::class)
    private suspend fun getAdbWindows(): File {
        settings.getStringOrNull(key = SettingsConstants.ADB_PATH_KEY)?.let {
            if (File(it).isFile) {
                return File(it)
            }
        }

        val adbZipBytes: ByteArray = Res.readBytes("files/adb_windows.zip")

        val tempDir = withContext(Dispatchers.IO) {
            File.createTempFile("android_tools_adb_temp", "windows").apply {
                delete()
                mkdir()
            }
        }

        withContext(Dispatchers.IO) {
            unzip(adbZipBytes.inputStream(), tempDir)
        }

        val adbExecutable = File("$tempDir\\platform-tools", "adb.exe")

        if (!adbExecutable.exists() || !adbExecutable.setExecutable(true)) {
            throw IllegalStateException("Failed to extract and set adb executable.")
        }

        settings.putString(key = SettingsConstants.ADB_PATH_KEY, value = adbExecutable.absolutePath)

        return adbExecutable
    }

    private fun unzip(zipInputStream: InputStream, targetDirectory: File) {
        ZipInputStream(zipInputStream).use { zis ->
            var entry = zis.nextEntry
            while (entry != null) {
                val file = File(targetDirectory, entry.name)

                if (entry.isDirectory) {
                    file.mkdirs()
                } else {
                    file.parentFile?.mkdirs()
                    FileOutputStream(file).use { fos ->
                        zis.copyTo(fos)
                    }
                }

                zis.closeEntry()
                entry = zis.nextEntry
            }
        }
    }
}
