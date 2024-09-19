package fr.thomasbernard03.androidtools.domain.models

sealed class InstallApplicationResult(open val apk : String){

    data object NotStarted : InstallApplicationResult("")

    data object Loading : InstallApplicationResult("")

    sealed class Finished(override val apk : String, open val result : String) : InstallApplicationResult(apk){
        data class Success(override val apk : String, override val result : String) : Finished(apk, result)
        data class Error(override val apk : String, override val result : String) : Finished(apk, result)
    }
}