package com.example.ej5_kmp

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import android.webkit.MimeTypeMap
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.platform.LocalContext
import androidx.core.content.FileProvider
import java.io.File

@Composable
actual fun PlatformBackHandler(enabled: Boolean, onBack: () -> Unit) {
    BackHandler(enabled = enabled, onBack = onBack)
}

@Composable
actual fun rememberFileImporter(
    destinationDir: () -> String,
    onResult: (importedName: String?) -> Unit
): () -> Unit {
    val context = LocalContext.current
    // rememberUpdatedState: el launcher se crea una sola vez, pero siempre usa la carpeta
    // y el callback más recientes.
    val currentDestination by rememberUpdatedState(destinationDir)
    val currentOnResult by rememberUpdatedState(onResult)

    val launcher = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri: Uri? ->
        val importedName = if (uri == null) null else copyUriIntoDir(context, uri, currentDestination())
        currentOnResult(importedName)
    }
    return { launcher.launch(arrayOf("*/*")) }
}

@Composable
actual fun rememberFileSharer(): (path: String) -> Unit {
    val context = LocalContext.current
    return { path ->
        try {
            val file = File(path)
            val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
            val mime = MimeTypeMap.getSingleton()
                .getMimeTypeFromExtension(file.extension.lowercase()) ?: "*/*"
            val send = Intent(Intent.ACTION_SEND).apply {
                type = mime
                putExtra(Intent.EXTRA_STREAM, uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            context.startActivity(Intent.createChooser(send, "Compartir ${file.name}"))
        } catch (e: Exception) {
            // Sin app que reciba el archivo o ruta no compartible: no hacemos nada.
        }
    }
}

/** Copia el archivo elegido dentro de [dir] sin sobrescribir; devuelve el nombre final. */
private fun copyUriIntoDir(context: Context, uri: Uri, dir: String): String? {
    return try {
        val rawName = displayNameOf(context, uri) ?: "archivo_importado"
        val name = File(rawName).name.ifEmpty { "archivo_importado" }
        val base = name.substringBeforeLast('.', name)
        val ext = name.substringAfterLast('.', "")

        var target = File(dir, name)
        var counter = 1
        while (target.exists()) {
            val candidate = if (ext.isEmpty()) "$base ($counter)" else "$base ($counter).$ext"
            target = File(dir, candidate)
            counter++
        }

        val input = context.contentResolver.openInputStream(uri) ?: return null
        input.use { source -> target.outputStream().use { out -> source.copyTo(out) } }
        target.name
    } catch (e: Exception) {
        null
    }
}

private fun displayNameOf(context: Context, uri: Uri): String? =
    context.contentResolver
        .query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
        ?.use { cursor -> if (cursor.moveToFirst()) cursor.getString(0) else null }
