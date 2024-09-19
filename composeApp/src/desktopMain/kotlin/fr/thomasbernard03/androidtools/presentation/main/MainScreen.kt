package fr.thomasbernard03.androidtools.presentation.main

import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import fr.thomasbernard03.androidtools.domain.models.Screen
import fr.thomasbernard03.androidtools.presentation.main.components.DeviceDropDown
import fr.thomasbernard03.androidtools.presentation.main.components.MainNavigationRail
import fr.thomasbernard03.androidtools.presentation.main.components.mainNavigationGraph


@Composable
fun MainScreen(uiState : MainUiState, onEvent : (MainEvent) -> Unit) {

    val navController = rememberNavController()
    val currentRoute = navController.currentBackStackEntryAsState().value?.destination?.route

    fun navigateTo(route: String){
        navController.navigate(route = route){
            popUpTo(currentRoute ?: ""){
                inclusive = true
            }
            launchSingleTop = true
        }
    }

    LaunchedEffect(Unit){
        onEvent(MainEvent.OnLoadDevices)
    }

    Row {
        MainNavigationRail(
            modifier = Modifier.width(80.dp),
            currentRoute = currentRoute,
            navigateTo = { navigateTo(it) },
            header = {
                DeviceDropDown(
                    selection = uiState.selectedDevice ?: "Select a device",
                    devices = uiState.devices,
                    onDeviceSelected = {
                        if (uiState.selectedDevice != it){
                            onEvent(MainEvent.OnDeviceSelected(it))
                            navigateTo(Screen.ApplicationInstaller.route)
                        }
                    }
                )
            }
        )

        NavHost(
            navController = navController,
            startDestination = Screen.ApplicationInstaller.route,
        ) {
            mainNavigationGraph()
        }
    }
}