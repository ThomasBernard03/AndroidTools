package fr.thomasbernard03.androidtools.domain.models

import androidtools.composeapp.generated.resources.Res
import androidtools.composeapp.generated.resources.accessibility
import androidtools.composeapp.generated.resources.app_installer
import androidtools.composeapp.generated.resources.app_name
import androidtools.composeapp.generated.resources.application_installer_rail_title
import androidtools.composeapp.generated.resources.file_explorer_rail_title
import androidtools.composeapp.generated.resources.filter
import androidtools.composeapp.generated.resources.folder
import androidtools.composeapp.generated.resources.gear
import androidtools.composeapp.generated.resources.information
import androidtools.composeapp.generated.resources.information_rail_title
import androidtools.composeapp.generated.resources.logcat
import androidtools.composeapp.generated.resources.logcat_rail_title
import androidtools.composeapp.generated.resources.settings_accessibility_title
import androidtools.composeapp.generated.resources.settings_appearance_title
import androidtools.composeapp.generated.resources.settings_general_title
import androidtools.composeapp.generated.resources.settings_rail_title
import org.jetbrains.compose.resources.DrawableResource
import org.jetbrains.compose.resources.StringResource

sealed class Screen(open val title: StringResource, open val route : String, open val icon : DrawableResource) {
    data object ApplicationInstaller : Screen(title = Res.string.application_installer_rail_title, route = "app_installer", icon = Res.drawable.app_installer)
    data object Information : Screen(title = Res.string.information_rail_title, "information", icon = Res.drawable.information)
    data object FileExplorer : Screen(title = Res.string.file_explorer_rail_title, "file_explorer", icon = Res.drawable.folder)
    data object Logcat : Screen(title = Res.string.logcat_rail_title, "logcat", icon = Res.drawable.logcat)
    data object Settings : Screen(title = Res.string.settings_rail_title, "settings", icon = Res.drawable.gear)

    sealed class SettingsScreen(override val title: StringResource, override val route : String, override val icon : DrawableResource) : Screen(title = title, route = route, icon = icon) {
        data object General : SettingsScreen(title = Res.string.settings_general_title, route = "general", icon = Res.drawable.gear)
        data object Appearance: SettingsScreen(title = Res.string.settings_appearance_title, route = "appearance", icon = Res.drawable.filter)
        data object Accessibility : SettingsScreen(title = Res.string.settings_accessibility_title, route = "accessibility", icon = Res.drawable.accessibility)
    }


    companion object {
        val mainScreens = listOf(ApplicationInstaller, Information, FileExplorer, Logcat, Settings)
    }
}