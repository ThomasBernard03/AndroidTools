package fr.thomasbernard03.androidtools.domain.repositories

import fr.thomasbernard03.androidtools.domain.models.DeviceInformation
import kotlinx.coroutines.flow.Flow

interface DeviceRepository {
    suspend fun getConnectedDevices() : Flow<List<String>>

    fun getDeviceBattery(): Flow<Int>

    suspend fun getDeviceInformation(): DeviceInformation

    suspend fun sendInput(input : String)
    suspend fun deleteText()
}