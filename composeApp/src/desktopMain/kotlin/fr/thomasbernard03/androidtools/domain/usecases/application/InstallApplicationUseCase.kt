package fr.thomasbernard03.androidtools.domain.usecases.application

import fr.thomasbernard03.androidtools.domain.models.InstallApplicationResult
import fr.thomasbernard03.androidtools.domain.repositories.ApplicationRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.koin.java.KoinJavaComponent.inject

class InstallApplicationUseCase {
    private val applicationRepository: ApplicationRepository by inject(ApplicationRepository::class.java)

    suspend operator fun invoke(path : String, onStatusChanged : (InstallApplicationResult) -> Unit) = withContext(Dispatchers.IO) {
        onStatusChanged(InstallApplicationResult.Loading)
        val finalStatus = applicationRepository.installApplication(path)
        onStatusChanged(finalStatus)
    }
}