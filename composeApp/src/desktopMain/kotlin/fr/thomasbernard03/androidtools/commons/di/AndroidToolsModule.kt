package fr.thomasbernard03.androidtools.commons.di

import fr.thomasbernard03.androidtools.commons.Environment
import fr.thomasbernard03.androidtools.commons.helpers.AdbProviderHelper
import fr.thomasbernard03.androidtools.commons.helpers.implementations.macos.MacOsAdbProviderHelper
import fr.thomasbernard03.androidtools.commons.helpers.implementations.windows.WindowsAdbProviderHelper
import fr.thomasbernard03.androidtools.data.datasources.ShellDataSource
import fr.thomasbernard03.androidtools.data.repositories.ApplicationRepositoryImpl
import fr.thomasbernard03.androidtools.data.repositories.DeviceRepositoryImpl
import fr.thomasbernard03.androidtools.data.repositories.FileRepositoryImpl
import fr.thomasbernard03.androidtools.data.repositories.LogcatRepositoryImpl
import fr.thomasbernard03.androidtools.domain.repositories.ApplicationRepository
import fr.thomasbernard03.androidtools.domain.repositories.DeviceRepository
import fr.thomasbernard03.androidtools.domain.repositories.FileRepository
import fr.thomasbernard03.androidtools.domain.repositories.LogcatRepository
import org.koin.dsl.module

val androidToolsModule = module {
    // Datasource
    single { ShellDataSource() }

    // Data
    single<ApplicationRepository> { ApplicationRepositoryImpl() }
    single<LogcatRepository> { LogcatRepositoryImpl() }
    single<DeviceRepository> { DeviceRepositoryImpl() }
    single<FileRepository> { FileRepositoryImpl() }

    // Register platform specific implementations
    when(Environment.currentOs){
        Environment.OperatingSystem.WINDOWS -> {
            single<AdbProviderHelper> { WindowsAdbProviderHelper() }
        }
        Environment.OperatingSystem.MAC_OS_X -> {
            single<AdbProviderHelper> { MacOsAdbProviderHelper() }
        }
        Environment.OperatingSystem.LINUX -> TODO()
    }
}