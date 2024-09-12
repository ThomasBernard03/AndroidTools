package fr.thomasbernard03.androidtools.domain.models

open class File {
    var permissions : String = ""
    var size : Long = 0
    var name : String = ""
    var parent : Folder? = null
    var path : String = ""
}