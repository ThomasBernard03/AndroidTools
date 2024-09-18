package fr.thomasbernard03.androidtools.domain.usecases.device

import fr.thomasbernard03.androidtools.data.datasources.ShellDataSource
import fr.thomasbernard03.androidtools.domain.repositories.DeviceRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.withContext
import org.koin.java.KoinJavaComponent.get

class GetConnectedDevicesUseCase(
    private val deviceRepository: DeviceRepository = get(DeviceRepository::class.java)
) {
    suspend operator fun invoke() : Flow<List<String>> = withContext(Dispatchers.IO) {
        deviceRepository.getConnectedDevices()
    }
}