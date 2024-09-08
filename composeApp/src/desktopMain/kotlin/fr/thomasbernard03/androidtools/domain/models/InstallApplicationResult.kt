package fr.thomasbernard03.androidtools.domain.models

sealed class InstallApplicationResult(open val apk : String){
    data class Success(override val apk : String) : InstallApplicationResult(apk)
    data class Error(val message : String, override val apk : String) : InstallApplicationResult(apk)
}