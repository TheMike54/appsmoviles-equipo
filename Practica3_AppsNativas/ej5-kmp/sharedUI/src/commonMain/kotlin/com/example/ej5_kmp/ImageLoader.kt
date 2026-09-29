package com.example.ej5_kmp

import androidx.compose.ui.graphics.ImageBitmap

/**
 * Cargar una imagen desde una ruta de archivo. En commonMain no se
 * puede usar android.graphics.BitmapFactory directamente (es específico de Android),
 * así que aquí solo va la firma; el actual (androidMain) hace el trabajo real.
 */
expect fun loadImageBitmap(path: String): ImageBitmap?
