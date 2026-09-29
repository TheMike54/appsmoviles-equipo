package com.example.ej5_kmp

import androidx.compose.runtime.Composable

/**
 * expect/actual #4 : botón "atrás" del sistema.
 * En Android se intercepta con BackHandler (para subir de carpeta o cerrar el visor en
 * lugar de salir de la app). En iOS no existe un botón atrás del sistema: allí la
 * navegación es el botón "‹ Atrás" de la barra superior (Human Interface Guidelines).
 */
@Composable
expect fun PlatformBackHandler(enabled: Boolean, onBack: () -> Unit)

/**
 * expect/actual #5 : selector de archivos (importar).
 * Devuelve una función que abre el selector del sistema. El archivo elegido se copia
 * dentro de la carpeta que devuelva [destinationDir] y luego se llama a [onResult] con
 * el nombre copiado (o null si se canceló o falló).
 * Android: Storage Access Framework (OpenDocument). iOS: UIDocumentPickerViewController.
 */
@Composable
expect fun rememberFileImporter(
    destinationDir: () -> String,
    onResult: (importedName: String?) -> Unit
): () -> Unit

/**
 * expect/actual #6 : compartir un archivo con la hoja de compartir del sistema.
 * Android: Intent.ACTION_SEND con FileProvider. iOS: UIActivityViewController.
 * Devuelve una función que recibe la ruta del archivo.
 */
@Composable
expect fun rememberFileSharer(): (path: String) -> Unit
