package fr.thomasbernard03.androidtools.commons.helpers

import java.io.File

interface AdbProviderHelper {

    suspend fun getAdb (): File
}