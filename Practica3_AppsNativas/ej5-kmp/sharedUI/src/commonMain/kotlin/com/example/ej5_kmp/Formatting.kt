package com.example.ej5_kmp

import com.example.ej5_kmp.filesystem.FileEntry

/** Fecha y hora con el formato local del dispositivo (cada plataforma sabe cómo). */
expect fun formatDateTime(epochMillis: Long): String

fun formatSize(bytes: Long): String = when {
    bytes < 1024L -> "$bytes bytes"
    bytes < 1024L * 1024L -> "${oneDecimal(bytes / 1024.0)} KB"
    bytes < 1024L * 1024L * 1024L -> "${oneDecimal(bytes / (1024.0 * 1024.0))} MB"
    else -> "${oneDecimal(bytes / (1024.0 * 1024.0 * 1024.0))} GB"
}

private fun oneDecimal(value: Double): String {
    val tenths = (value * 10).toLong()
    return "${tenths / 10}.${tenths % 10}"
}

/** Texto secundario de cada fila: "Carpeta · fecha" o "tamaño · fecha". */
fun FileEntry.detailText(): String {
    val date = formatDateTime(lastModifiedEpochMillis)
    return if (isDirectory) "Carpeta · $date" else "${formatSize(sizeBytes)} · $date"
}
