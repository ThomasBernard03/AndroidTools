package fr.thomasbernard03.androidtools.domain.usecases.device

import fr.thomasbernard03.androidtools.domain.models.DeviceInformation
import fr.thomasbernard03.androidtools.domain.repositories.DeviceRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.koin.java.KoinJavaComponent.get

class GetDeviceInformationUseCase(
    private val deviceRepository: DeviceRepository = get(DeviceRepository::class.java)
) {
    suspend operator fun invoke() : DeviceInformation = withContext(Dispatchers.IO) {
        deviceRepository.getDeviceInformation()
    }
}