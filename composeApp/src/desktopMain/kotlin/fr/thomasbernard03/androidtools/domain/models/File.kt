package fr.thomasbernard03.androidtools.domain.models

import java.time.LocalDateTime

open class File {
    var permissions : String = ""
    var size : Long = 0
    var name : String = ""
    var parent : Folder? = null
    var modifiedAt : LocalDateTime = LocalDateTime.MIN
    var path : String = ""
}