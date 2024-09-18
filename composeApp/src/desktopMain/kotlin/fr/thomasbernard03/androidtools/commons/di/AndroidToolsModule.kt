package fr.thomasbernard03.androidtools.commons.di

import fr.thomasbernard03.androidtools.data.datasources.ShellDataSource
import fr.thomasbernard03.androidtools.data.repositories.ApplicationRepositoryImpl
import fr.thomasbernard03.androidtools.domain.repositories.ApplicationRepository
import org.koin.dsl.module

val androidToolsModule = module {
    // Datasource
    single { ShellDataSource() }

    // Data
    single<ApplicationRepository> { ApplicationRepositoryImpl() }
}