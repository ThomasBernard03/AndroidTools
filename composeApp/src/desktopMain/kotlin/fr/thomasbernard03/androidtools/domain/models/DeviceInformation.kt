package fr.thomasbernard03.androidtools.domain.models

data class DeviceInformation(
    val manufacturer: String,
    val model: String,
    val version: Int,
    val serial: String
)