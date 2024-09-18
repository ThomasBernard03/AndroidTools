package fr.thomasbernard03.androidtools.domain.usecases.logcat

import fr.thomasbernard03.androidtools.domain.repositories.LogcatRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.koin.java.KoinJavaComponent.get

class ClearLogcatUseCase(
    private val logcatRepository: LogcatRepository = get(LogcatRepository::class.java)
) {
    suspend operator fun invoke()  = withContext(Dispatchers.IO) {
        logcatRepository.clearLogcat()
    }
}