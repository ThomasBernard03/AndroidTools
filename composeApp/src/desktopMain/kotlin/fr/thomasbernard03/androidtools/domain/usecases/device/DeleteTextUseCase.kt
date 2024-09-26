package fr.thomasbernard03.androidtools.domain.usecases.device

import fr.thomasbernard03.androidtools.domain.repositories.DeviceRepository
import org.koin.java.KoinJavaComponent.get

class DeleteTextUseCase(
    private val deviceRepository: DeviceRepository = get(DeviceRepository::class.java)
) {
    suspend operator fun invoke() {
        deviceRepository.deleteText()
    }
}