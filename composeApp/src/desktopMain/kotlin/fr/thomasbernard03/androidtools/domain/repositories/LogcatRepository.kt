package fr.thomasbernard03.androidtools.domain.repositories

import kotlinx.coroutines.flow.Flow


interface LogcatRepository {
    /**
     * Clear the logcat with the adb command `logcat -c`
     */
    suspend fun clearLogcat()


    /**
     * Listen to the logcat with the adb command `logcat`
     * @param packageName the package name of the app to listen to (if null, listen to all logcat messages)
     * @return a flow of logcat messages line by line
     */
    suspend fun listenLogcat(packageName: String? = null): Flow<String>
}