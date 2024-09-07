package fr.thomasbernard03.androidtools.presentation.logcat

import androidx.lifecycle.viewModelScope
import fr.thomasbernard03.androidtools.domain.usecases.GetLogcatUseCase
import fr.thomasbernard03.androidtools.presentation.commons.BaseViewModel
import kotlinx.coroutines.launch

class LogcatViewModel(
    private val getLogcatUseCase: GetLogcatUseCase = GetLogcatUseCase(),
) : BaseViewModel<LogcatUiState, LogcatEvent>() {
    override fun initializeUiState() = LogcatUiState()

    override fun onEvent(event: LogcatEvent) {
        when(event){
            LogcatEvent.OnClear -> TODO()
            LogcatEvent.OnRestart -> TODO()
            LogcatEvent.OnStopListening -> TODO()
            LogcatEvent.OnStartListening -> {
                viewModelScope.launch {
                    getLogcatUseCase.invoke().collect { line ->
                        updateUiState {
                            copy(lines = lines + line)
                        }
                    }
                }
            }
        }
    }
}