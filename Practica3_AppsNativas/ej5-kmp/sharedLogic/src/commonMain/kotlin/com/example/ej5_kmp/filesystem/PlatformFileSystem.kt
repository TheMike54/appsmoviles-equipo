package com.example.ej5_kmp.filesystem

/**
 * expect/actual #1 : ruta del sistema de archivos.
 *
 * Puente entre la lógica compartida (commonMain) y el sistema de archivos real de
 * cada plataforma:
 *  - Android -> actual con java.io.File (necesita el Context de la app, por eso init()).
 *  - iOS     -> actual con NSFileManager (no necesita Context).
 *
 * init() se llama una sola vez al arrancar la app. En Android, desde la Application,
 * pasando el Context. En iOS no hace falta pasar nada (se llama con null).
 */
expect object PlatformFileSystem {
    fun init(platformContext: Any?)
    fun defaultRootPath(): String
    fun listEntries(path: String): List<FileEntry>
    fun readTextFile(path: String): String
    fun writeTextFile(path: String, content: String): Boolean
    fun createDirectory(parentPath: String, name: String): Boolean
    fun delete(path: String): Boolean
    fun rename(path: String, newName: String): Boolean
    fun copy(sourcePath: String, destinationDirPath: String): Boolean
    fun move(sourcePath: String, destinationDirPath: String): Boolean
}
