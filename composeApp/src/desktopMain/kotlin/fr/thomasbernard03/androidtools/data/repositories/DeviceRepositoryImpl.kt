package fr.thomasbernard03.androidtools.data.repositories

import fr.thomasbernard03.androidtools.commons.SettingsConstants
import fr.thomasbernard03.androidtools.data.datasources.ShellDataSource
import fr.thomasbernard03.androidtools.domain.repositories.DeviceRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.channelFlow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.withContext
import org.koin.java.KoinJavaComponent.get
import java.io.BufferedReader
import java.io.InputStreamReader

class DeviceRepositoryImpl(
    private val shellDataSource: ShellDataSource = get(ShellDataSource::class.java)
) : DeviceRepository {
    override suspend fun getConnectedDevices(): Flow<List<String>> = flow {
        while (true) {
            val connectedDevices = withContext(Dispatchers.IO) {
                val result = shellDataSource.executeAdbCommand("devices")

                result.lines()
                    .drop(1) // Skip the header "List of devices attached"
                    .map { it.split("\t").first() } // Extract device name
                    .filter { it.isNotEmpty() } // Remove empty lines
            }

            emit(connectedDevices) // Emit the list of connected devices
            delay(5000) // Wait for 5 seconds before the next refresh
        }
    }

    override fun getDeviceBattery(): Flow<Int> = channelFlow {
        withContext(Dispatchers.IO) {
            while (true) {
                shellDataSource.executeAdbCommand("shell", "dumpsys", "battery").let { output ->
                    val batteryLevel = parseBatteryLevel(output)
                    send(batteryLevel)
                }
                delay(20000) // Read battery level every 20 seconds
            }
        }
    }

    private fun parseBatteryLevel(output: String): Int {
        val levelLine = output.lines().find { it.trim().startsWith("level:") }
        return levelLine?.split(":")?.get(1)?.trim()?.replace("[","")?.replace("]", "")?.toIntOrNull() ?: 0
    }
}