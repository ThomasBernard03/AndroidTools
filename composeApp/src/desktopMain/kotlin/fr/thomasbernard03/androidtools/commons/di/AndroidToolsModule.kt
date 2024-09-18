package fr.thomasbernard03.androidtools.commons.di

import fr.thomasbernard03.androidtools.data.datasources.ShellDataSource
import fr.thomasbernard03.androidtools.data.repositories.ApplicationRepositoryImpl
import fr.thomasbernard03.androidtools.data.repositories.DeviceRepositoryImpl
import fr.thomasbernard03.androidtools.data.repositories.LogcatRepositoryImpl
import fr.thomasbernard03.androidtools.domain.repositories.ApplicationRepository
import fr.thomasbernard03.androidtools.domain.repositories.DeviceRepository
import fr.thomasbernard03.androidtools.domain.repositories.LogcatRepository
import org.koin.dsl.module

val androidToolsModule = module {
    // Datasource
    single { ShellDataSource() }

    // Data
    single<ApplicationRepository> { ApplicationRepositoryImpl() }
    single<LogcatRepository> { LogcatRepositoryImpl() }
    single<DeviceRepository> { DeviceRepositoryImpl() }
}