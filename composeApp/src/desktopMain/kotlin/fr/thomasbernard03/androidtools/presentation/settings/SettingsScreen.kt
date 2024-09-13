package fr.thomasbernard03.androidtools.presentation.settings

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import fr.thomasbernard03.androidtools.domain.models.Screen
import fr.thomasbernard03.androidtools.presentation.settings.components.SettingsNavigationRail

@Composable
fun SettingsScreen(
    uiState: SettingsUiState,
    onEvent: (SettingsEvent) -> Unit
) {
    val navController = rememberNavController()
    val currentRoute = navController.currentBackStackEntryAsState().value?.destination?.route

    fun navigateTo(route: String){
        navController.navigate(route = route){
            currentRoute?.let {
                popUpTo(it){
                    inclusive = true
                }
            }
            launchSingleTop = true
        }
    }

    LaunchedEffect(Unit){
        onEvent(SettingsEvent.OnAppearing)
    }

    Row {
        SettingsNavigationRail(
            modifier = Modifier.width(200.dp),
            currentRoute = navController.currentDestination?.route,
            navigateTo = ::navigateTo
        )

        Scaffold {
            NavHost(navController = navController, startDestination = Screen.SettingsScreen.General.route) {
                composable(Screen.SettingsScreen.General.route) {
                    Column(modifier = Modifier.fillMaxSize()) {
                        Text("General")
                    }
                }
                composable(Screen.SettingsScreen.Appearance.route) {
                    Column(modifier = Modifier.fillMaxSize()) {
                        Text("Appearance")
                    }
                }
                composable(Screen.SettingsScreen.Accessibility.route) {
                    Column(modifier = Modifier.fillMaxSize()) {
                        Text("Accessibility")
                    }
                }
            }
        }
    }
}