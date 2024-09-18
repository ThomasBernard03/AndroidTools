package fr.thomasbernard03.androidtools.domain.repositories

import kotlinx.coroutines.flow.Flow

interface DeviceRepository {
    suspend fun getConnectedDevices() : Flow<List<String>>

    fun getDeviceBattery(): Flow<Int>
}