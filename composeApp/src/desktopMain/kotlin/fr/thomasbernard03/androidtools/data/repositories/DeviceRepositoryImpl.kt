package fr.thomasbernard03.androidtools.data.repositories

import fr.thomasbernard03.androidtools.data.datasources.ShellDataSource
import fr.thomasbernard03.androidtools.domain.models.DeviceInformation
import fr.thomasbernard03.androidtools.domain.repositories.DeviceRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.channelFlow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.withContext
import org.koin.java.KoinJavaComponent.get

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
        fun parseBatteryLevel(output: String): Int {
            val levelLine = output.lines().find { it.trim().startsWith("level:") }
            return levelLine?.split(":")?.get(1)?.trim()?.replace("[","")?.replace("]", "")?.toIntOrNull() ?: 0
        }

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

    override suspend fun getDeviceInformation(): DeviceInformation {
        val result = shellDataSource.executeAdbCommand("shell", "getprop")
        return parseDeviceInformation(result)
    }

    override suspend fun sendInput(input: String) {
        shellDataSource.executeAdbCommand("shell", "input", "text", "\"$input\"")
    }

    override suspend fun deleteText() {
        shellDataSource.executeAdbCommand("shell", "input", "keyevent", "67")
    }

    private fun parseDeviceInformation(output : String) : DeviceInformation {
        val lines = output.split("\n")
        val manufacturer = lines.find { it.contains("ro.product.manufacturer") }?.split(":")?.get(1)?.replace("[", "")?.replace("]", "")?.trim() ?: ""
        val model = lines.find { it.contains("ro.product.model") }?.split(":")?.get(1)?.replace("[", "")?.replace("]", "")?.trim() ?: ""
        val version = lines.find { it.contains("ro.build.version.release") }?.split(":")?.get(1)?.replace("[", "")?.replace("]", "")?.trim() ?: ""
        val serial = lines.find { it.contains("ro.serialno") }?.split(":")?.get(1)?.replace("[", "")?.replace("]", "")?.trim() ?: ""


        val allLines = lines.filter { it.split(":").size >= 2 }.map {
            val key = it.split(":").first()
            val value = it.split(":").last()
            key to value
        }.toMap()

        return DeviceInformation(manufacturer, model, version.toInt(), serial, allLines)
    }
}