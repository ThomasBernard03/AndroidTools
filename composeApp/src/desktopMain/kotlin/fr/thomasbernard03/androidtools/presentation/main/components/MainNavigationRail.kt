package fr.thomasbernard03.androidtools.presentation.main.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationRail
import androidx.compose.material3.NavigationRailItem
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import fr.thomasbernard03.androidtools.domain.models.Screen
import org.jetbrains.compose.resources.painterResource
import org.jetbrains.compose.resources.stringResource

@Composable
fun MainNavigationRail(
    modifier : Modifier = Modifier,
    header : @Composable (ColumnScope.() -> Unit),
    enabled : Boolean = true,
    currentRoute : String?,
    navigateTo : (Screen) -> Unit
) {
    NavigationRail(
        modifier = modifier,
        containerColor = MaterialTheme.colorScheme.primaryContainer,
        header = {
            header()
            HorizontalDivider(
                color = MaterialTheme.colorScheme.onPrimaryContainer,
            )
        }
    ) {
        Column(
            modifier = Modifier
                .padding(horizontal = 8.dp)
                .fillMaxHeight()
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            Column(
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Screen.all.dropLast(1).forEach { item ->
                    NavigationRailItem(
                        enabled = enabled,
                        selected = currentRoute == item.route,
                        onClick = {
                            if (currentRoute != item.route){
                                navigateTo(item)
                            }
                        },
                        icon = {
                            Icon(
                                painter = painterResource(item.icon),
                                contentDescription = stringResource(item.title),
                                tint = MaterialTheme.colorScheme.onBackground,
                                modifier = Modifier.size(24.dp),
                            )
                        }
                    )
                }
            }

            Screen.all.last().let { item ->
                NavigationRailItem(
                    selected = currentRoute == item.route,
                    onClick = {
                        if (currentRoute != item.route){
                            navigateTo(item)
                        }
                    },
                    icon = {
                        Icon(
                            painter = painterResource(item.icon),
                            contentDescription = stringResource(item.title),
                            tint = MaterialTheme.colorScheme.onBackground
                        )
                    }
                )
            }
        }
    }
}