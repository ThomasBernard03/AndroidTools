package fr.thomasbernard03.androidtools.domain.usecases

import fr.thomasbernard03.androidtools.data.repositories.ShellRepositoryImpl
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class GetAdbVersionUseCase(
    private val shellRepositoryImpl: ShellRepositoryImpl = ShellRepositoryImpl()
) {
    suspend operator fun invoke() : String = withContext(Dispatchers.IO) {
        shellRepositoryImpl.executeAdbCommand("version")
    }
}