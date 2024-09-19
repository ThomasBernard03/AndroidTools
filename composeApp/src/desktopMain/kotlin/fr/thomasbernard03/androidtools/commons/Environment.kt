package fr.thomasbernard03.androidtools.commons

class Environment {
    enum class OperatingSystem {
        WINDOWS,
        LINUX,
        MAC_OS_X
    }

    companion object {
        val currentOs: OperatingSystem =
            when {
                System.getProperty("os.name").contains("Windows") -> OperatingSystem.WINDOWS
                System.getProperty("os.name") == "Mac OS X" -> OperatingSystem.MAC_OS_X
                else -> throw IllegalStateException("Unsupported OS ${System.getProperty("os.name")}")
            }
    }
}
