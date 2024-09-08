package fr.thomasbernard03.androidtools.data.repositories

import java.io.BufferedReader
import java.io.InputStreamReader

class ShellRepositoryImpl {

    suspend fun executeCommand(){
        val process = ProcessBuilder("/usr/local/bin/adb", "shell", "cmd", "package ", "list", "package", "-3").start()
        val reader = BufferedReader(InputStreamReader(process.inputStream))
        val output = StringBuilder()
    }
}