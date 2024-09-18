package fr.thomasbernard03.androidtools.presentation.logcat.components

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import fr.thomasbernard03.androidtools.commons.extensions.backgroundColor
import fr.thomasbernard03.androidtools.commons.extensions.messageColor
import fr.thomasbernard03.androidtools.commons.extensions.onBackgroundColor
import fr.thomasbernard03.androidtools.domain.models.LogcatLevel
import fr.thomasbernard03.androidtools.domain.models.LogcatLine

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun LogcatItem(
    logcatLine: String,
) {
    val parsedLogcatLine = parseLogcatLine(logcatLine)

    if (parsedLogcatLine == null) {
        Row(
            modifier = Modifier.height(30.dp),
            verticalAlignment = Alignment.CenterVertically
        ){
            Text(
                text = logcatLine,
                maxLines = 1,
                style = MaterialTheme.typography.bodySmall,
            )
        }
    }
    else {
        Row(
            horizontalArrangement = Arrangement.spacedBy(4.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = parsedLogcatLine.time,
                modifier = Modifier.width(140.dp),
                maxLines = 1,
                style = MaterialTheme.typography.bodySmall
            )

            Text(
                text = parsedLogcatLine.tag,
                modifier = Modifier.width(120.dp),
                maxLines = 1,
                style = MaterialTheme.typography.bodySmall

            )

            Box(
                modifier = Modifier
                    .background(color = parsedLogcatLine.level.backgroundColor())
                    .size(30.dp)
            ) {
                Text(
                    text = parsedLogcatLine.level.name,
                    modifier = Modifier.align(Alignment.Center),
                    style = MaterialTheme.typography.bodySmall,
                    color = parsedLogcatLine.level.onBackgroundColor(),
                    fontWeight = FontWeight.SemiBold
                )
            }

            Text(
                text = parsedLogcatLine.message,
                maxLines = 1,
                style = MaterialTheme.typography.bodySmall.copy(color = parsedLogcatLine.level.messageColor())
            )
        }
    }
}


/**
 * Example of line :
 * 09-07 17:38:37.432  4392  4449 I BugleRcsEngine: Connected state: [1], networkType: [WIFI] [CONTEXT thread_id=59 ]
 * 09-07 19:00:58.661   617  2793 W AppOps  : Noting op not finished: uid 10137 pkg com.google.android.gms code 79 startTime of in progress event=1725727631561
 */
private fun parseLogcatLine(line: String): LogcatLine? {
    // Adjust the regex to handle optional spaces more flexibly
    val regex = Regex("^(\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}\\.\\d{3})\\s+(\\d+)\\s+(\\d+)\\s+([A-Z])\\s+([^:]+):\\s+(.*)$")
    val matchResult = regex.find(line) ?: return null

    val groups = matchResult.groupValues
    return LogcatLine(
        time = groups[1],      // Date and time
        pid = groups[2],       // Process ID
        tid = groups[3],       // Thread ID
        level = parseLogLevel(groups[4]), // Parse log level (single letter)
        tag = groups[5],       // Log tag
        message = groups[6]    // Log message
    )
}

private fun parseLogLevel(level: String): LogcatLevel {
    return when (level) {
        "V" -> LogcatLevel.V
        "D" -> LogcatLevel.D
        "I" -> LogcatLevel.I
        "W" -> LogcatLevel.W
        "E" -> LogcatLevel.E
        "F" -> LogcatLevel.F
        else ->  throw IllegalArgumentException("Unknown log level: $level")
    }
}