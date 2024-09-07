package fr.thomasbernard03.androidtools.domain.usecases

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.BufferedReader
import java.io.InputStreamReader

class ClearLogcatUseCase {
    suspend operator fun invoke()  = withContext(Dispatchers.IO) {
        try {
            val process = ProcessBuilder("/usr/local/bin/adb", "logcat", "c").start()
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            val output = StringBuilder()

            reader.forEachLine { line ->
                output.append(line).append("\n")
            }

            val exitCode = process.waitFor()
            return@withContext exitCode == 0
        } catch (e: Exception) {
            e.printStackTrace()
            return@withContext false
        }
    }
}