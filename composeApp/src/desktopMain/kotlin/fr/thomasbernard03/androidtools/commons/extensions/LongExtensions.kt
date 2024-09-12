package fr.thomasbernard03.androidtools.commons.extensions

fun Long.byteCountToDisplaySize(): String {
    if (this / 1024 < 1) return "$this B"
    val sizeKb = this / 1024.0
    if (sizeKb / 1024 < 1) return "${"%.2f".format(sizeKb)} KB"
    val sizeMb = sizeKb / 1024.0
    if (sizeMb / 1024 < 1) return "${"%.2f".format(sizeMb)} MB"
    val sizeGb = sizeMb / 1024.0
    return "${"%.2f".format(sizeGb)} GB"
}