package fr.thomasbernard03.androidtools.domain.usecases

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.channelFlow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.withContext
import java.io.BufferedReader
import java.io.InputStreamReader

class GetLogcatUseCase {
    fun invoke(): Flow<String> = channelFlow {
        withContext(Dispatchers.IO) {
            val process = ProcessBuilder("/usr/local/bin/adb", "logcat").start()
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