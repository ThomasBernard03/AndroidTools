package fr.thomasbernard03.androidtools.presentation.logcat

import androidx.lifecycle.viewModelScope
import fr.thomasbernard03.androidtools.domain.usecases.ClearLogcatUseCase
import fr.thomasbernard03.androidtools.domain.usecases.GetAllPackagesUseCase
import fr.thomasbernard03.androidtools.domain.usecases.GetLogcatUseCase
import fr.thomasbernard03.androidtools.presentation.commons.BaseViewModel
import kotlinx.coroutines.launch

class LogcatViewModel(
    private val getLogcatUseCase: GetLogcatUseCase = GetLogcatUseCase(),
    private val clearLogcatUseCase: ClearLogcatUseCase = ClearLogcatUseCase(),
    private val getAllPackagesUseCase: GetAllPackagesUseCase = GetAllPackagesUseCase()
) : BaseViewModel<LogcatUiState, LogcatEvent>() {
    override fun initializeUiState() = LogcatUiState()

    init {
        viewModelScope.launch {
            getAllPackagesUseCase.invoke().let { packages ->
                updateUiState { copy(packages = packages.toList()) }
            }
        }
    }

    override fun onEvent(event: LogcatEvent) {
        when(event){
            is LogcatEvent.OnPackageSelected -> updateUiState { copy(selectedPackage = event.packageName) }
            LogcatEvent.OnClear -> {
                viewModelScope.launch {
                    updateUiState { copy(loading = true) }
                    clearLogcatUseCase()
                    updateUiState { copy(loading = false, lines = emptyList()) }
                }
            }
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