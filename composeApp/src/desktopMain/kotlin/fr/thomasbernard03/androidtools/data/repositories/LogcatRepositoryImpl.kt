package fr.thomasbernard03.androidtools.data.repositories

import fr.thomasbernard03.androidtools.data.datasources.ShellDataSource
import fr.thomasbernard03.androidtools.domain.repositories.LogcatRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.channelFlow
import org.koin.java.KoinJavaComponent.get

class LogcatRepositoryImpl(
    private val shellDataSource: ShellDataSource = get(ShellDataSource::class.java)
) : LogcatRepository {
    override suspend fun clearLogcat() {
        shellDataSource.executeAdbCommand("logcat", "-c")
    }

    override suspend fun listenLogcat(packageName: String?): Flow<String> = channelFlow {
        // If packageName is not null, get the pid of the package and listen to the logcat of this pid
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