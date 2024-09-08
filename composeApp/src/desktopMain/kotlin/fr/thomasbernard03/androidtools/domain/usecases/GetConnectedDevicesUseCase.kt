package fr.thomasbernard03.androidtools.domain.usecases

import fr.thomasbernard03.androidtools.domain.models.DeviceInformation
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.withContext
import java.io.BufferedReader
import java.io.InputStreamReader

class GetConnectedDevicesUseCase {
    suspend operator fun invoke() : Flow<List<String>> = flow {
        while (true) {
            val connectedDevices = withContext(Dispatchers.IO) {
                val process = ProcessBuilder("/usr/local/bin/adb", "devices").start()
                val reader = BufferedReader(InputStreamReader(process.inputStream))
                val output = StringBuilder()

                reader.forEachLine { line ->
                    output.append(line).append("\n")
                }

                val exitCode = process.waitFor()
                if (exitCode == 0) {
                    output.toString().lines()
                        .drop(1) // Skip the header "List of devices attached"
                        .map { it.split("\t").first() } // Extract device name
                        .filter { it.isNotEmpty() } // Remove empty lines
                } else {
                    emptyList<String>()
                }
            }

            emit(connectedDevices) // Emit the list of connected devices
            delay(5000) // Wait for 5 seconds before the next refresh
        }
    }
}