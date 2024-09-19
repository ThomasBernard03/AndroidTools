package fr.thomasbernard03.androidtools.domain.usecases.device

import fr.thomasbernard03.androidtools.domain.repositories.DeviceRepository
import kotlinx.coroutines.flow.Flow
import org.koin.java.KoinJavaComponent.get

class GetDeviceBatteryUseCase(
    private val deviceRepository: DeviceRepository = get(DeviceRepository::class.java)
) {
    fun invoke(): Flow<Int> {
        return deviceRepository.getDeviceBattery()
    }
}
