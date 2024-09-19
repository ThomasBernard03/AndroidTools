package fr.thomasbernard03.androidtools.domain.models

class Folder : File() {
    var childens: List<File> = emptyList()
}