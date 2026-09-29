package com.example.ej5_kmp

import android.graphics.BitmapFactory
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap

/** Lado máximo (en píxeles) al que se decodifica una imagen: suficiente para una pantalla. */
private const val MAX_SIDE = 2048

/**
 * Decodifica la imagen reduciéndola si es muy grande (inSampleSize), para no agotar la
 * memoria con fotos de varios megapíxeles.
 */
actual fun loadImageBitmap(path: String): ImageBitmap? {
    val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
    BitmapFactory.decodeFile(path, bounds)
    if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null

    var sample = 1
    while (bounds.outWidth / sample > MAX_SIDE || bounds.outHeight / sample > MAX_SIDE) {
        sample *= 2
    }
    val options = BitmapFactory.Options().apply { inSampleSize = sample }
    return BitmapFactory.decodeFile(path, options)?.asImageBitmap()
}
