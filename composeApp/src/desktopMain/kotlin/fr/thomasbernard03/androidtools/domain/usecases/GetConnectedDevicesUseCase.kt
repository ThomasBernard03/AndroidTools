package fr.thomasbernard03.androidtools.domain.usecases

import fr.thomasbernard03.androidtools.data.repositories.ShellRepositoryImpl
import fr.thomasbernard03.androidtools.domain.models.DeviceInformation
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.withContext
import java.io.BufferedReader
import java.io.InputStreamReader

class GetConnectedDevicesUseCase(
    private val shellRepositoryImpl: ShellRepositoryImpl = ShellRepositoryImpl()
) {
    suspend operator fun invoke() : Flow<List<String>> = flow {
        while (true) {
            val connectedDevices = withContext(Dispatchers.IO) {
                val result = shellRepositoryImpl.executeAdbCommand("devices")

                result.lines()
                    .drop(1) // Skip the header "List of devices attached"
                    .map { it.split("\t").first() } // Extract device name
                    .filter { it.isNotEmpty() } // Remove empty lines
            }

            emit(connectedDevices) // Emit the list of connected devices
            delay(5000) // Wait for 5 seconds before the next refresh
        }
    }
}