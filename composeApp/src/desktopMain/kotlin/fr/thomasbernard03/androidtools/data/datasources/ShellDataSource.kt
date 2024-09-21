package fr.thomasbernard03.androidtools.data.datasources

import com.russhwolf.settings.Settings
import fr.thomasbernard03.androidtools.commons.SettingsConstants
import fr.thomasbernard03.androidtools.commons.helpers.AdbProviderHelper
import io.klogging.Klogger
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.channelFlow
import kotlinx.coroutines.withContext
import org.koin.java.KoinJavaComponent.get
import java.io.BufferedReader
import java.io.InputStreamReader

class ShellDataSource(
    private val settings: Settings = Settings(),
    private val logger : Klogger = get(Klogger::class.java),
    private val adbProviderHelper: AdbProviderHelper = get(AdbProviderHelper::class.java)
) {
    suspend fun executeAdbCommand(vararg formatArgs: String): String = withContext(Dispatchers.IO) {
        logger.info("*** Start executing adb command ***")
        val arguments = mutableListOf<String>()

        val currentDevice = settings.getStringOrNull(key = SettingsConstants.SELECTED_DEVICE_KEY)

        if (currentDevice != null) {
            arguments.add("-s")
            arguments.add(currentDevice)
        }

        arguments.addAll(formatArgs)

        val adb = adbProviderHelper.getAdb()
        logger.debug("Adb path: ${adb.absolutePath}")
        logger.info("${adb.absolutePath} ${arguments.joinToString(" ")}")

        val process = ProcessBuilder(listOf(adb.absolutePath) + arguments).start()
        val reader = BufferedReader(InputStreamReader(process.inputStream))
        val output = StringBuilder()

        reader.forEachLine { line ->
            output.append(line).append("\n")
        }

        process.waitFor()

        logger.info("$output")

        logger.info("*** End of adb command ***")

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
            val adb = adbProviderHelper.getAdb()

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
}
