package fr.thomasbernard03.androidtools.domain.usecases.device

import com.russhwolf.settings.Settings
import fr.thomasbernard03.androidtools.commons.SettingsConstants
import fr.thomasbernard03.androidtools.domain.models.DeviceInformation
import fr.thomasbernard03.androidtools.domain.repositories.DeviceRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.koin.java.KoinJavaComponent.get
import java.io.BufferedReader
import java.io.InputStreamReader

class GetDeviceInformationUseCase(
    private val deviceRepository: DeviceRepository = get(DeviceRepository::class.java)
) {
    suspend operator fun invoke() : DeviceInformation = withContext(Dispatchers.IO) {
        deviceRepository.getDeviceInformation()
    }
}