package fr.thomasbernard03.androidtools.presentation.commons

import androidx.lifecycle.ViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

abstract class BaseViewModel<TState: UiState, TEvent: Event> : ViewModel() {
    private val _uiState by lazy { MutableStateFlow(initializeUiState()) }
    val uiState: StateFlow<TState> = _uiState.asStateFlow()

    abstract fun onEvent(event: TEvent)

    abstract fun initializeUiState(): TState

    protected fun updateUiState(updateBlock: TState.() -> TState) {
        _uiState.update(updateBlock)
    }
}