package fr.thomasbernard03.androidtools.domain.usecases

import fr.thomasbernard03.androidtools.data.datasources.ShellDataSource
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class GetAdbVersionUseCase(
    private val shellDataSource: ShellDataSource = ShellDataSource()
) {
    suspend operator fun invoke() : String = withContext(Dispatchers.IO) {
        shellDataSource.executeAdbCommand("version")
    }
}