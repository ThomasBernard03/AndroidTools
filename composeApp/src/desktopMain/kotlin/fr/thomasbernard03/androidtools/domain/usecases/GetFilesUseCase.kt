package fr.thomasbernard03.androidtools.domain.usecases

import fr.thomasbernard03.androidtools.data.datasources.ShellDataSource
import fr.thomasbernard03.androidtools.domain.models.File
import fr.thomasbernard03.androidtools.domain.models.Folder
import org.koin.java.KoinJavaComponent.get

class GetFilesUseCase(
    private val shellDataSource: ShellDataSource = get(ShellDataSource::class.java)
) {
    suspend operator fun invoke(path : String) : List<File> {
        val result = shellDataSource.executeAdbCommand("shell", "ls", "-l", path)
        return parseResult(path, result)
    }

    /**
     * Exemple of result :
     *
     * total 76
     *
     * drwxr-xr-x   2 root   root        27 2009-01-01 01:00 acct
     *
     * drwxr-xr-x  80 root   root      1640 2024-09-08 10:36 apex
     * lrw-r--r--   1 root   root        11 2009-01-01 01:00 bin -> /system/bin
     * drwxr-xr-x   9 root   root       220 2024-09-08 10:35 bootstrap-apex
     * lrw-r--r--   1 root   root        50 2009-01-01 01:00 bugreports -> /data/user_de/0/com.android.shell/files/bugreports
     * drwxrwx---   2 system cache       27 2009-01-01 01:00 cache
     * drwxr-xr-x   3 root   root         0 2024-09-08 10:35 config
     * lrw-r--r--   1 root   root        17 2009-01-01 01:00 d -> /sys/kernel/debug
     * drwxrwx--x  51 system system    4096 2024-09-08 10:37 data
     * d?????????   ? ?      ?            ?                ? data_mirror
     * drwxr-xr-x   2 root   root        27 2009-01-01 01:00 debug_ramdisk
     * drwxr-xr-x  21 root   root      2740 2024-09-08 10:36 dev
     * lrw-r--r--   1 root   root        11 2009-01-01 01:00 etc -> /system/etc
     * l?????????   ? ?      ?            ?                ? init -> ?
     * -?????????   ? ?      ?            ?                ? init.environ.rc
     * d?????????   ? ?      ?            ?                ? linkerconfig
     * d?????????   ? ?      ?            ?                ? metadata
     * drwxr-xr-x  16 root   system     340 2024-09-08 10:35 mnt
     * drwxr-xr-x   2 root   root       199 2009-01-01 01:00 odm
     * drwxr-xr-x   2 root   root        42 2009-01-01 01:00 odm_dlkm
     * drwxr-xr-x   2 root   root        27 2009-01-01 01:00 oem
     * d?????????   ? ?      ?            ?                ? postinstall
     * dr-xr-xr-x 364 root   root         0 2024-09-08 10:35 proc
     * drwxr-xr-x   9 root   root       151 2009-01-01 01:00 product
     * lrw-r--r--   1 root   root        21 2009-01-01 01:00 sdcard -> /storage/self/primary
     * drwxr-xr-x   2 root   root        27 2009-01-01 01:00 second_stage_resources
     * drwx--x---   5 shell  everybody  100 2024-09-08 10:37 storage
     * dr-xr-xr-x  13 root   root         0 2024-09-08 10:35 sys
     * drwxr-xr-x  12 root   root       274 2009-01-01 01:00 system
     * d?????????   ? ?      ?            ?                ? system_dlkm
     * drwxr-xr-x   8 root   root       130 2009-01-01 01:00 system_ext
     * drwxrwx--x   2 shell  shell       40 2024-09-08 10:35 tmp
     * drwxr-xr-x  12 root   shell      219 2009-01-01 01:00 vendor
     * drwxr-xr-x   2 root   root        42 2009-01-01 01:00 vendor_dlkm
     */
    private fun parseResult(path : String, result: String): List<File> {
        val lines = result.split("\n")
        val files = mutableListOf<File>()

        // Expression régulière pour matcher les lignes du format `ls -l`
        val regex = Regex("""^([\-dl])([rwxst\-]{9})\s+(\d+)\s+(\w+)\s+(\w+)\s+(\d+)\s+(\d{4}-\d{2}-\d{2})?\s*(\d{2}:\d{2})?\s+([^\s]+)(?:\s+->\s+.+)?$""")

        for (line in lines) {
            if (line.isNotEmpty()) {
                val matchResult = regex.find(line)

                if (matchResult != null) {
                    val (type, permissions, links, owner, group, size, date, time, name) = matchResult.destructured

//                    if(type.startsWith("l") || permissions.startsWith("?")){
//                        continue
//                    }

                    val isDirectory = type == "d"

                    if (isDirectory) {
                        files.add(
                            Folder().apply {
                                this.name = name
                                this.size = size.toLong()
                                this.permissions = "$type$permissions"
                                this.path = path
                            }
                        )
                    } else {
                        files.add(
                            File().apply {
                                this.name = name
                                this.size = size.toLong()
                                this.permissions = "$type$permissions"
                                this.path = path
                            }
                        )
                    }
                }
            }
        }
        return files
    }
}