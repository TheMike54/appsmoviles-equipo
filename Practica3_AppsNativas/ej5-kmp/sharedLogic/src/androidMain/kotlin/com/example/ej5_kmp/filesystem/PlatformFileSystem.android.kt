package com.example.ej5_kmp.filesystem

import android.content.Context
import java.io.File

actual object PlatformFileSystem {

    private lateinit var appContext: Context

    actual fun init(platformContext: Any?) {
        appContext = platformContext as Context
    }

    actual fun defaultRootPath(): String = appContext.filesDir.absolutePath

    actual fun listEntries(path: String): List<FileEntry> {
        val children = File(path).listFiles() ?: return emptyList()
        return children.map { it.toFileEntry() }
    }

    actual fun readTextFile(path: String): String = File(path).readText()

    actual fun writeTextFile(path: String, content: String): Boolean = try {
        File(path).writeText(content)
        true
    } catch (e: Exception) {
        false
    }

    actual fun createDirectory(parentPath: String, name: String): Boolean =
        File(parentPath, name).mkdir()

    actual fun delete(path: String): Boolean = File(path).deleteRecursively()

    actual fun rename(path: String, newName: String): Boolean {
        val file = File(path)
        val target = File(file.parentFile, newName)
        return file.renameTo(target)
    }

    actual fun copy(sourcePath: String, destinationDirPath: String): Boolean {
        val source = File(sourcePath)
        val target = File(destinationDirPath, source.name)
        return try {
            source.copyRecursively(target, overwrite = false)
            true
        } catch (e: Exception) {
            false
        }
    }

    actual fun move(sourcePath: String, destinationDirPath: String): Boolean {
        val source = File(sourcePath)
        val target = File(destinationDirPath, source.name)
        // Mismo almacenamiento: renombrar es instantáneo y no duplica los datos.
        if (source.renameTo(target)) return true
        if (!copy(sourcePath, destinationDirPath)) return false
        return delete(sourcePath)
    }

    private fun File.toFileEntry() = FileEntry(
        name = name,
        path = absolutePath,
        isDirectory = isDirectory,
        sizeBytes = if (isDirectory) 0L else length(),
        lastModifiedEpochMillis = lastModified()
    )
}
