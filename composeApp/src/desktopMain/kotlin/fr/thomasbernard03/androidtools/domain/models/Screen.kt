package fr.thomasbernard03.androidtools.domain.models

import androidtools.composeapp.generated.resources.Res
import androidtools.composeapp.generated.resources.app_installer
import androidtools.composeapp.generated.resources.app_name
import androidtools.composeapp.generated.resources.application_installer_rail_title
import androidtools.composeapp.generated.resources.gear
import androidtools.composeapp.generated.resources.information
import androidtools.composeapp.generated.resources.information_rail_title
import androidtools.composeapp.generated.resources.logcat
import androidtools.composeapp.generated.resources.logcat_rail_title
import androidtools.composeapp.generated.resources.settings_rail_title
import org.jetbrains.compose.resources.DrawableResource
import org.jetbrains.compose.resources.StringResource

enum class Screen(val title: StringResource, val route : String, val icon : DrawableResource) {
    ApplicationInstaller(title = Res.string.application_installer_rail_title, "app_installer", icon = Res.drawable.app_installer),
    Information(title = Res.string.information_rail_title, "information", icon = Res.drawable.information),
    Logcat(title = Res.string.logcat_rail_title, "logcat", icon = Res.drawable.logcat),
    Settings(title = Res.string.settings_rail_title, "settings", icon = Res.drawable.gear),
}