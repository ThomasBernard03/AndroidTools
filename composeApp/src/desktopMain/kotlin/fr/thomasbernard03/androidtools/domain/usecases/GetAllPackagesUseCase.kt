package fr.thomasbernard03.androidtools.domain.usecases

import fr.thomasbernard03.androidtools.data.datasources.ShellDataSource
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class GetAllPackagesUseCase(
    private val shellDataSource: ShellDataSource = ShellDataSource(),
) {
    suspend operator fun invoke() : Collection<String> = withContext(Dispatchers.IO) {
        val result = shellDataSource.executeAdbCommand("shell", "cmd", "package ", "list", "package", "-3")
        return@withContext result.lines().map { it.replace("package:", "") }.filter { it.isNotEmpty() }
    }
}