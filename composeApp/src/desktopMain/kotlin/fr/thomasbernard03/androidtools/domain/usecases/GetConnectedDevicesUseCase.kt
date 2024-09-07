package fr.thomasbernard03.androidtools.domain.usecases

import fr.thomasbernard03.androidtools.domain.models.DeviceInformation
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.BufferedReader
import java.io.InputStreamReader

class GetConnectedDevicesUseCase {
    suspend operator fun invoke() : Collection<String> = withContext(Dispatchers.IO) {
        val process = ProcessBuilder("/usr/local/bin/adb", "devices").start()
        val reader = BufferedReader(InputStreamReader(process.inputStream))
        val output = StringBuilder()

        reader.forEachLine { line ->
            output.append(line).append("\n")
        }

        val exitCode = process.waitFor()
        if (exitCode == 0) {
            return@withContext output.toString().lines().drop(1).map { it.split("\t").first() }.filter { it.isNotEmpty() }
        }

        return@withContext emptyList()
    }
}