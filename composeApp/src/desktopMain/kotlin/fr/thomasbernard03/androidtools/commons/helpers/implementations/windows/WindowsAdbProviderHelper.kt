package fr.thomasbernard03.androidtools.commons.helpers.implementations.windows

import androidtools.composeapp.generated.resources.Res
import com.russhwolf.settings.Settings
import fr.thomasbernard03.androidtools.commons.SettingsConstants
import fr.thomasbernard03.androidtools.commons.helpers.AdbProviderHelper
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.jetbrains.compose.resources.ExperimentalResourceApi
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.util.zip.ZipInputStream

class WindowsAdbProviderHelper(
    private val settings: Settings = Settings()
) : AdbProviderHelper {
    @OptIn(ExperimentalResourceApi::class)
    override suspend fun getAdb(): File {
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