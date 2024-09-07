package fr.thomasbernard03.androidtools.domain.usecases

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.BufferedReader
import java.io.InputStreamReader

class GetAllPackagesUseCase {
    suspend operator fun invoke() : Collection<String> = withContext(Dispatchers.IO) {
        val process = ProcessBuilder("/usr/local/bin/adb", "shell", "cmd", "package ", "list", "package", "-3").start()
        val reader = BufferedReader(InputStreamReader(process.inputStream))
        val output = StringBuilder()

        reader.forEachLine { line ->
            output.append(line).append("\n")
        }

        val exitCode = process.waitFor()
        if (exitCode == 0) {
            return@withContext output.toString().lines().map { it.replace("package:", "") }.filter { it.isNotEmpty() }
        }

        return@withContext emptyList()
    }
}