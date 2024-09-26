package fr.thomasbernard03.androidtools.presentation.main

import androidtools.composeapp.generated.resources.Res
import androidtools.composeapp.generated.resources.phone
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.materialIcon
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgedBox
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationRailItem
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.DpOffset
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.PopupProperties
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import fr.thomasbernard03.androidtools.domain.models.Screen
import fr.thomasbernard03.androidtools.presentation.connectdevice.ConnectDeviceScreen
import fr.thomasbernard03.androidtools.presentation.main.components.DeviceDropDown
import fr.thomasbernard03.androidtools.presentation.main.components.MainNavigationRail
import fr.thomasbernard03.androidtools.presentation.main.components.mainNavigationGraph
import org.jetbrains.compose.resources.painterResource
import org.jetbrains.compose.resources.stringResource


@Composable
fun MainScreen(uiState : MainUiState, onEvent : (MainEvent) -> Unit) {

    val navController = rememberNavController()
    val currentRoute = navController.currentBackStackEntryAsState().value?.destination?.route


    fun navigateTo(screen: Screen){
        navController.navigate(route = screen.route){
            popUpTo(currentRoute ?: ""){
                inclusive = true
            }
            launchSingleTop = true
        }
    }

    LaunchedEffect(uiState.devices, uiState.selectedDevice){
        if (uiState.devices.isEmpty() || uiState.selectedDevice.isNullOrEmpty()){
            navController.navigate("connectdevice") {
                currentRoute?.let { popUpTo(it){ inclusive = true } }
                launchSingleTop = true
            }
        }
    }



    LaunchedEffect(Unit){
        onEvent(MainEvent.OnLoadDevices)
    }

    Row {
        var expanded by remember { mutableStateOf(false) }

        MainNavigationRail(
            modifier = Modifier.width(80.dp),
            currentRoute = currentRoute,
            navigateTo = { navigateTo(it) },
            enabled = uiState.selectedDevice != null,
            header = {
                NavigationRailItem(
                    selected = false,
                    onClick = { expanded = true },
                    icon = {
                        BadgedBox(
                            badge = {
                                Badge(
                                    modifier = Modifier.align(Alignment.BottomEnd),
                                    containerColor = Color.Red,
                                    contentColor = Color.White
                                ) {
                                    Text(text = uiState.devices.size.toString(),)
                                }
                            },
                            content = {
                                Icon(
                                    painter = painterResource(Res.drawable.phone),
                                    contentDescription = "Phone",
                                    tint = MaterialTheme.colorScheme.onBackground,
                                    modifier = Modifier.size(24.dp),
                                )
                            }
                        )
                    }
                )
            }
        )
        DropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false },
            offset = DpOffset(x = 80.dp, y = 0.dp),
            modifier = Modifier.fillMaxHeight()
        ){
            uiState.devices.forEach { device ->
                DropdownMenuItem(
                    onClick = {
                        onEvent(MainEvent.OnDeviceSelected(device))
                        expanded = false
                        navigateTo(Screen.ApplicationInstaller)
                    },
                    text = {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            RadioButton(
                                selected = device == uiState.selectedDevice,
                                onClick = {
                                    onEvent(MainEvent.OnDeviceSelected(device))
                                    expanded = false
                                    navigateTo(Screen.ApplicationInstaller)
                                }
                            )

                            Text(
                                text = device,
                            )
                        }
                    }
                )
            }
        }

        NavHost(
            navController = navController,
            startDestination = Screen.ApplicationInstaller.route,
        ) {
            mainNavigationGraph()

            composable("connectdevice"){
                ConnectDeviceScreen()
            }
        }
    }
}