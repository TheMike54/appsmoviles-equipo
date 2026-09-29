package com.example.ej5_kmp.filesystem

/**
 * Representa un archivo o carpeta dentro del gestor. Es el mismo modelo que usan
 * Android e iOS: lo llena PlatformFileSystem (actual) en cada plataforma.
 */
data class FileEntry(
    val name: String,
    val path: String,
    val isDirectory: Boolean,
    val sizeBytes: Long,
    val lastModifiedEpochMillis: Long
) {
    val extension: String
        get() = if (isDirectory) "" else name.substringAfterLast('.', "")
}

private val imageExtensions = setOf("jpg", "jpeg", "png", "gif", "webp", "bmp")
private val textExtensions = setOf("txt", "md", "log", "json", "kt", "swift", "xml", "csv")

val FileEntry.isImage: Boolean
    get() = !isDirectory && extension.lowercase() in imageExtensions

val FileEntry.isTextFile: Boolean
    get() = !isDirectory && extension.lowercase() in textExtensions
