package fr.thomasbernard03.androidtools.presentation.settings

import androidtools.composeapp.generated.resources.Res
import androidtools.composeapp.generated.resources.settings_accessibility_title
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import fr.thomasbernard03.androidtools.domain.models.Screen
import fr.thomasbernard03.androidtools.presentation.settings.appearance.AppearanceScreen
import fr.thomasbernard03.androidtools.presentation.settings.appearance.AppearanceSettingsViewModel
import fr.thomasbernard03.androidtools.presentation.settings.components.SettingsNavigationRail
import fr.thomasbernard03.androidtools.presentation.settings.components.SettingsScaffold
import fr.thomasbernard03.androidtools.presentation.settings.general.GeneralSettingsScreen
import fr.thomasbernard03.androidtools.presentation.settings.general.GeneralSettingsViewModel

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

        NavHost(navController = navController, startDestination = Screen.SettingsScreen.General.route) {
            composable(Screen.SettingsScreen.General.route) {
                val viewModel = viewModel { GeneralSettingsViewModel() }
                val uiState by viewModel.uiState.collectAsStateWithLifecycle()
                GeneralSettingsScreen(uiState = uiState, onEvent = viewModel::onEvent)
            }
            composable(Screen.SettingsScreen.Appearance.route) {
                val viewModel = viewModel { AppearanceSettingsViewModel() }
                val uiState by viewModel.uiState.collectAsStateWithLifecycle()
                AppearanceScreen(uiState = uiState, onEvent = viewModel::onEvent)
            }
            composable(Screen.SettingsScreen.Accessibility.route) {
                SettingsScaffold(
                    title = Res.string.settings_accessibility_title
                ){
                    Box(
                        modifier = Modifier.fillMaxSize()
                    ) {
                        Text(text = "In progress...", modifier = Modifier.align(Alignment.Center))
                    }
                }
            }
        }
    }
}