package fr.thomasbernard03.androidtools.presentation.commons.extensions

import androidtools.composeapp.generated.resources.Res
import androidtools.composeapp.generated.resources.android
import androidtools.composeapp.generated.resources.file
import androidtools.composeapp.generated.resources.image
import androidtools.composeapp.generated.resources.video
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import fr.thomasbernard03.androidtools.presentation.theme.AndroidColor
import fr.thomasbernard03.androidtools.presentation.theme.FileColor
import fr.thomasbernard03.androidtools.presentation.theme.ImageColor
import fr.thomasbernard03.androidtools.presentation.theme.VideoColor
import org.jetbrains.compose.resources.painterResource

@Composable
fun String.fileIcon() {
    if (this.endsWith(".apk")) {
        Icon(
            painter = painterResource(Res.drawable.android),
            contentDescription = "Android icon",
            tint = AndroidColor,
            modifier = Modifier.size(24.dp)
        )
    }
    else if (this.endsWith(".mp4") || this.endsWith(".avi") || this.endsWith(".mkv")) {
        Icon(
            painter = painterResource(Res.drawable.video),
            contentDescription = "Video icon",
            modifier = Modifier.size(24.dp),
            tint = VideoColor
        )
    }
//    else if (this.endsWith(".mp3") || this.endsWith(".wav") || this.endsWith(".flac")) {
//        Icon(
//            painter = painterResource(Res.drawable.music),
//            contentDescription = "",
//            modifier = Modifier.size(24.dp),
//            tint = MaterialTheme.colorScheme.onBackground
//        )
//    }
    else if (this.endsWith(".jpg", ignoreCase = true) || this.endsWith(".jpeg") || this.endsWith(".png", ignoreCase = true) || this.endsWith(".gif")) {
        Icon(
            painter = painterResource(Res.drawable.image),
            contentDescription = "",
            modifier = Modifier.size(24.dp).padding(4.dp),
            tint = ImageColor
        )
    }
    else {
        Icon(
            painter = painterResource(Res.drawable.file),
            contentDescription = "",
            modifier = Modifier.size(24.dp),
            tint = FileColor
        )
    }
}