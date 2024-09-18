package fr.thomasbernard03.androidtools.domain.usecases.application

import fr.thomasbernard03.androidtools.data.datasources.ShellDataSource
import fr.thomasbernard03.androidtools.domain.repositories.ApplicationRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.koin.java.KoinJavaComponent.get

class GetAllPackagesUseCase(
    private val applicationRepository: ApplicationRepository = get(ApplicationRepository::class.java)
) {
    suspend operator fun invoke() : List<String> = withContext(Dispatchers.IO) {
        applicationRepository.getAllPackages()
    }
}