package fr.thomasbernard03.androidtools.domain.usecases

import com.russhwolf.settings.Settings
import fr.thomasbernard03.androidtools.commons.SettingsConstants
import fr.thomasbernard03.androidtools.data.repositories.ShellRepositoryImpl
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.channelFlow
import kotlinx.coroutines.withContext
import java.io.BufferedReader
import java.io.InputStreamReader

class GetLogcatUseCase(
    private val settings: Settings = Settings(),
    private val shellRepositoryImpl: ShellRepositoryImpl = ShellRepositoryImpl()
) {
    operator fun invoke(packageName : String? = null): Flow<String> = channelFlow {
        withContext(Dispatchers.IO) {
            val currentDevice = settings.getString(key = SettingsConstants.SELECTED_DEVICE_KEY, defaultValue = "")


            if (!packageName.isNullOrEmpty()){
                val pid = shellRepositoryImpl.executeAdbCommand("shell", "pidof", "-s", packageName).trim()
                val process = ProcessBuilder("/usr/local/bin/adb", "-s", currentDevice, "logcat", "--pid", pid).start()
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
            else {
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
}