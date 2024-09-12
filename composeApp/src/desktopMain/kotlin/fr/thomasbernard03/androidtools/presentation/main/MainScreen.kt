package fr.thomasbernard03.androidtools.presentation.main

import androidtools.composeapp.generated.resources.Res
import androidtools.composeapp.generated.resources.app_installer
import androidtools.composeapp.generated.resources.information
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationRail
import androidx.compose.material3.NavigationRailItem
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import fr.thomasbernard03.androidtools.domain.models.Screen
import fr.thomasbernard03.androidtools.presentation.applicationinstaller.ApplicationInstallerScreen
import fr.thomasbernard03.androidtools.presentation.applicationinstaller.ApplicationInstallerViewModel
import fr.thomasbernard03.androidtools.presentation.information.InformationScreen
import fr.thomasbernard03.androidtools.presentation.information.InformationViewModel
import fr.thomasbernard03.androidtools.presentation.logcat.LogcatScreen
import fr.thomasbernard03.androidtools.presentation.logcat.LogcatViewModel
import fr.thomasbernard03.androidtools.presentation.main.components.DeviceDropDown
import fr.thomasbernard03.androidtools.presentation.main.components.mainNavigationGraph
import org.jetbrains.compose.resources.painterResource
import org.jetbrains.compose.resources.stringResource


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
        NavigationRail(
            modifier = Modifier.width(120.dp),
            containerColor = MaterialTheme.colorScheme.surfaceContainer,
            header = {
                DeviceDropDown(
                    modifier = Modifier.fillMaxWidth(),
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
        ) {
            Column(
                modifier = Modifier.padding(horizontal = 8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Screen.entries.forEach { item ->
                    NavigationRailItem(
                        selected = currentRoute == item.route,
                        onClick = {
                            if (currentRoute != item.route){
                                navigateTo(item.route)
                            }
                        },
                        icon = {
                            Icon(
                                painter = painterResource(item.icon),
                                contentDescription = stringResource(item.title),
                                tint = MaterialTheme.colorScheme.onBackground
                            )
                        },
                        label = { Text(stringResource(item.title)) }
                    )
                }
            }
        }

        NavHost(
            navController = navController,
            startDestination = Screen.ApplicationInstaller.route,
        ) {
            mainNavigationGraph()
        }
    }
}