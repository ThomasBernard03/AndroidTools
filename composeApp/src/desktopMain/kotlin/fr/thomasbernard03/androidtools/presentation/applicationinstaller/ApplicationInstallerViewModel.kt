package fr.thomasbernard03.androidtools.presentation.applicationinstaller

import fr.thomasbernard03.androidtools.presentation.commons.BaseViewModel

class ApplicationInstallerViewModel : BaseViewModel<ApplicationInstallerUiState, ApplicationInstallerEvent>() {

    override fun initializeUiState() = ApplicationInstallerUiState()

    override fun onEvent(event: ApplicationInstallerEvent) {
        when(event){
            ApplicationInstallerEvent.OnAppearing -> {


            }
        }
    }
}