package fr.thomasbernard03.androidtools.commons.helpers.implementations.macos

import androidtools.composeapp.generated.resources.Res
import com.russhwolf.settings.Settings
import fr.thomasbernard03.androidtools.commons.SettingsConstants
import fr.thomasbernard03.androidtools.commons.helpers.AdbProviderHelper
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.jetbrains.compose.resources.ExperimentalResourceApi
import java.io.File

class MacOsAdbProviderHelper(
    private val settings: Settings = Settings()
) : AdbProviderHelper {
    @OptIn(ExperimentalResourceApi::class)
    override suspend fun getAdb(): File {
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
}