package fr.thomasbernard03.androidtools.domain.usecases.logcat

import fr.thomasbernard03.androidtools.domain.repositories.LogcatRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.withContext
import org.koin.java.KoinJavaComponent.get

class GetLogcatUseCase(
    private val logcatRepository: LogcatRepository = get(LogcatRepository::class.java),
) {
    suspend operator fun invoke(packageName : String? = null): Flow<String> = withContext(Dispatchers.IO){
        logcatRepository.listenLogcat(packageName)
    }
}