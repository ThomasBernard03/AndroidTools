package fr.thomasbernard03.androidtools.domain.usecases

import com.russhwolf.settings.Settings
import fr.thomasbernard03.androidtools.commons.SettingsConstants
import fr.thomasbernard03.androidtools.data.repositories.ShellRepositoryImpl
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.BufferedReader
import java.io.InputStreamReader

class GetAllPackagesUseCase(
    private val shellRepositoryImpl: ShellRepositoryImpl = ShellRepositoryImpl(),
) {
    suspend operator fun invoke() : Collection<String> = withContext(Dispatchers.IO) {
        val result = shellRepositoryImpl.executeAdbCommand("shell", "cmd", "package ", "list", "package", "-3")
        return@withContext result.lines().map { it.replace("package:", "") }.filter { it.isNotEmpty() }
    }
}