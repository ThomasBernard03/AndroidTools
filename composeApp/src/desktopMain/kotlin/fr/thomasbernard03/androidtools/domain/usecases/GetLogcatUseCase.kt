package fr.thomasbernard03.androidtools.domain.usecases

import com.russhwolf.settings.Settings
import fr.thomasbernard03.androidtools.commons.SettingsConstants
import fr.thomasbernard03.androidtools.data.repositories.ShellRepositoryImpl
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.channelFlow
import kotlinx.coroutines.withContext
import java.io.BufferedReader
import java.io.InputStreamReader

class GetLogcatUseCase(
    private val shellRepositoryImpl: ShellRepositoryImpl = ShellRepositoryImpl()
) {
    operator fun invoke(packageName : String? = null): Flow<String> = channelFlow {
        if (!packageName.isNullOrEmpty()){
            val pid = shellRepositoryImpl.executeAdbCommand("shell", "pidof", "-s", packageName).trim()
            shellRepositoryImpl.executeAdbCommandFlow("logcat", "--pid", pid).collect {
                send(it)
            }
        }
        else {
            shellRepositoryImpl.executeAdbCommandFlow("logcat").collect {
                send(it)
            }
        }
    }
}