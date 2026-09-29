@file:OptIn(ExperimentalForeignApi::class)

package com.example.ej5_kmp.filesystem

import kotlinx.cinterop.BooleanVar
import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.addressOf
import kotlinx.cinterop.alloc
import kotlinx.cinterop.memScoped
import kotlinx.cinterop.ptr
import kotlinx.cinterop.usePinned
import kotlinx.cinterop.value
import platform.Foundation.NSData
import platform.Foundation.NSDate
import platform.Foundation.NSDocumentDirectory
import platform.Foundation.NSFileManager
import platform.Foundation.NSFileModificationDate
import platform.Foundation.NSFileSize
import platform.Foundation.NSNumber
import platform.Foundation.NSSearchPathForDirectoriesInDomains
import platform.Foundation.NSString
import platform.Foundation.NSUTF8StringEncoding
import platform.Foundation.NSUserDomainMask
import platform.Foundation.create
import platform.Foundation.stringWithContentsOfFile
import platform.Foundation.timeIntervalSince1970

actual object PlatformFileSystem {

    private val fileManager = NSFileManager.defaultManager

    actual fun init(platformContext: Any?) {
        // iOS no necesita Context, aquí no hay nada que inicializar.
    }

    actual fun defaultRootPath(): String {
        val paths = NSSearchPathForDirectoriesInDomains(
            NSDocumentDirectory, NSUserDomainMask, true
        )
        return paths.first() as String
    }

    actual fun listEntries(path: String): List<FileEntry> = memScoped {
        val names = fileManager.contentsOfDirectoryAtPath(path, null) ?: return@memScoped emptyList()
        names.mapNotNull { rawName ->
            val name = rawName as? String ?: return@mapNotNull null
            val childPath = "$path/$name"
            val isDirVar = alloc<BooleanVar>()
            fileManager.fileExistsAtPath(childPath, isDirVar.ptr)
            val isDirectory = isDirVar.value
            // Tamaño y fecha de modificación reales (los necesita el orden por tamaño/fecha).
            val attributes = fileManager.attributesOfItemAtPath(childPath, null)
            FileEntry(
                name = name,
                path = childPath,
                isDirectory = isDirectory,
                sizeBytes = if (isDirectory) 0L else attributes.sizeInBytes(),
                lastModifiedEpochMillis = attributes.modifiedMillis()
            )
        }
    }

    actual fun readTextFile(path: String): String =
        NSString.stringWithContentsOfFile(path, NSUTF8StringEncoding, null) as? String ?: ""

    actual fun writeTextFile(path: String, content: String): Boolean {
        val bytes = content.encodeToByteArray()
        val data = if (bytes.isEmpty()) {
            NSData()
        } else {
            bytes.usePinned { pinned ->
                NSData.create(bytes = pinned.addressOf(0), length = bytes.size.toULong())
            }
        }
        return fileManager.createFileAtPath(path, data, null)
    }

    actual fun createDirectory(parentPath: String, name: String): Boolean =
        fileManager.createDirectoryAtPath("$parentPath/$name", true, null, null)

    actual fun delete(path: String): Boolean =
        fileManager.removeItemAtPath(path, null)

    actual fun rename(path: String, newName: String): Boolean {
        val parent = path.substringBeforeLast('/')
        return fileManager.moveItemAtPath(path, "$parent/$newName", null)
    }

    actual fun copy(sourcePath: String, destinationDirPath: String): Boolean {
        val name = sourcePath.substringAfterLast('/')
        return fileManager.copyItemAtPath(sourcePath, "$destinationDirPath/$name", null)
    }

    actual fun move(sourcePath: String, destinationDirPath: String): Boolean {
        val name = sourcePath.substringAfterLast('/')
        return fileManager.moveItemAtPath(sourcePath, "$destinationDirPath/$name", null)
    }
}

/** Tamaño en bytes que reporta NSFileManager (0 si no hay dato). */
private fun Map<Any?, *>?.sizeInBytes(): Long = when (val value = this?.get(NSFileSize)) {
    is NSNumber -> value.longLongValue
    is Number -> value.toLong()
    else -> 0L
}

/** Fecha de última modificación en milisegundos desde 1970 (0 si no hay dato). */
private fun Map<Any?, *>?.modifiedMillis(): Long {
    val date = this?.get(NSFileModificationDate) as? NSDate ?: return 0L
    return (date.timeIntervalSince1970 * 1000).toLong()
}
