package fr.thomasbernard03.androidtools.domain.usecases

import fr.thomasbernard03.androidtools.data.datasources.ShellDataSource
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.channelFlow

class GetLogcatUseCase(
    private val shellDataSource: ShellDataSource = ShellDataSource()
) {
    operator fun invoke(packageName : String? = null): Flow<String> = channelFlow {
        if (!packageName.isNullOrEmpty()){
            val pid = shellDataSource.executeAdbCommand("shell", "pidof", "-s", packageName).trim()
            shellDataSource.executeAdbCommandFlow("logcat", "--pid", pid).collect {
                send(it)
            }
        }
        else {
            shellDataSource.executeAdbCommandFlow("logcat").collect {
                send(it)
            }
        }
    }
}