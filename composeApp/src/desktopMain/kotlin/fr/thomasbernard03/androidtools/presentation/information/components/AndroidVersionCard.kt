package fr.thomasbernard03.androidtools.presentation.information.components

import androidtools.composeapp.generated.resources.Res
import androidtools.composeapp.generated.resources.android_10
import androidtools.composeapp.generated.resources.android_11
import androidtools.composeapp.generated.resources.android_12
import androidtools.composeapp.generated.resources.android_13
import androidtools.composeapp.generated.resources.android_14
import androidtools.composeapp.generated.resources.android_15
import androidtools.composeapp.generated.resources.android_5
import androidtools.composeapp.generated.resources.android_6
import androidtools.composeapp.generated.resources.android_8
import androidtools.composeapp.generated.resources.android_9
import androidtools.composeapp.generated.resources.android_versions
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import org.jetbrains.compose.resources.painterResource

@Composable
fun AndroidVersionCard(
    modifier: Modifier = Modifier,
    version : Int?
) {
    Card(
        modifier = modifier,
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.secondaryContainer,
        )
    ){
        Column(
            modifier = Modifier.fillMaxHeight().padding(16.dp),
            verticalArrangement = Arrangement.SpaceBetween,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            val androidVersion = when(version){
                15 -> Res.drawable.android_15
                14 -> Res.drawable.android_14
                13 -> Res.drawable.android_13
                12 -> Res.drawable.android_12
                11 -> Res.drawable.android_11
                10 -> Res.drawable.android_10
                9 -> Res.drawable.android_9
                8 -> Res.drawable.android_8
                7 -> Res.drawable.android_8 // TODO : add android 7
                6 -> Res.drawable.android_6
                5 -> Res.drawable.android_5
                else -> Res.drawable.android_15 // TODO Add other versions
            }

            Image(
                painter = painterResource(androidVersion),
                contentDescription = "Android $version",
                modifier = Modifier.size(80.dp),
            )

            Column(
                horizontalAlignment = Alignment.Start,
                modifier = Modifier
            ) {
                Text(
                    text = "Android version",
                    style = MaterialTheme.typography.titleMedium.copy(
                        color = MaterialTheme.colorScheme.onSecondaryContainer.copy(alpha = 0.6f),
                    )
                )
                Text(
                    text = version.toString(),
                    style = MaterialTheme.typography.titleMedium.copy(
                    )
                )
            }
        }
    }
}