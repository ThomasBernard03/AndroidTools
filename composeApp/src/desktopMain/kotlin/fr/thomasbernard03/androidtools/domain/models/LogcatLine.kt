package fr.thomasbernard03.androidtools.domain.models

data class LogcatLine(
    val time: String,
    val pid: String,
    val tid: String,
    val level: LogcatLevel,
    val tag: String,
    val message: String
)