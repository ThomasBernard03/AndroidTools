package fr.thomasbernard03.androidtools.domain.usecases

import com.russhwolf.settings.Settings
import fr.thomasbernard03.androidtools.commons.SettingsConstants
import fr.thomasbernard03.androidtools.data.repositories.ShellRepositoryImpl
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.BufferedReader
import java.io.InputStreamReader

class ClearLogcatUseCase(
    private val shellRepositoryImpl: ShellRepositoryImpl = ShellRepositoryImpl()
) {
    suspend operator fun invoke()  = withContext(Dispatchers.IO) {
        shellRepositoryImpl.executeAdbCommand("logcat", "-c")
    }
}