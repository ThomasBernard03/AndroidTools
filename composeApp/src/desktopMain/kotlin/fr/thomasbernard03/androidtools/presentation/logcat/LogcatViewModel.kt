package fr.thomasbernard03.androidtools.presentation.logcat

import androidx.lifecycle.viewModelScope
import fr.thomasbernard03.androidtools.domain.usecases.ClearLogcatUseCase
import fr.thomasbernard03.androidtools.domain.usecases.GetAllPackagesUseCase
import fr.thomasbernard03.androidtools.domain.usecases.GetLogcatUseCase
import fr.thomasbernard03.androidtools.presentation.commons.BaseViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.launch

class LogcatViewModel(
    private val getLogcatUseCase: GetLogcatUseCase = GetLogcatUseCase(),
    private val clearLogcatUseCase: ClearLogcatUseCase = ClearLogcatUseCase(),
    private val getAllPackagesUseCase: GetAllPackagesUseCase = GetAllPackagesUseCase()
) : BaseViewModel<LogcatUiState, LogcatEvent>() {

    private var logcatJob: Job? = null

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
            is LogcatEvent.OnPackageSelected -> {
                viewModelScope.launch {
                    updateUiState { copy(selectedPackage = event.packageName) }
                    logcatJob?.cancel()
                    onEvent(LogcatEvent.OnStartListening(event.packageName))
                }
            }
            LogcatEvent.OnClear -> {
                viewModelScope.launch {
                    updateUiState { copy(loading = true, lines = emptyList()) }
                    clearLogcatUseCase()
                    updateUiState { copy(loading = false) }
                }
            }
            LogcatEvent.OnRestart -> {
                updateUiState { copy(loading = true, lines = emptyList()) }
                logcatJob?.cancel()
                updateUiState { copy(loading = false) }
                logcatJob = viewModelScope.launch {
                    getLogcatUseCase(uiState.value.selectedPackage).collect { line ->
                        updateUiState { copy(lines = lines + line) }
                    }
                }
            }
            LogcatEvent.OnStopListening -> {
                viewModelScope.launch {
                    updateUiState { copy(loading = true, onPause = true) }
                    logcatJob?.cancel()
                    updateUiState { copy(loading = false) }
                }
            }
            is LogcatEvent.OnStartListening -> {
                logcatJob?.cancel()
                logcatJob = viewModelScope.launch {
                    updateUiState { copy(onPause = false, lines = emptyList()) }
                    getLogcatUseCase(event.packageName).collect { line ->
                        updateUiState { copy(lines = lines + line) }
                    }
                }
            }
        }
    }
}