package fr.thomasbernard03.androidtools.domain.models

sealed class InstallApplicationResult {
    sealed class Success : InstallApplicationResult() {
        data object Installed : Success()
    }

    sealed class Error : InstallApplicationResult() {
        data object NoDevice : Error()
        data object NoAdb : Error()
        data object NoApplication : Error()
        data object NoPermission : Error()
        data object Unknown : Error()
    }
}