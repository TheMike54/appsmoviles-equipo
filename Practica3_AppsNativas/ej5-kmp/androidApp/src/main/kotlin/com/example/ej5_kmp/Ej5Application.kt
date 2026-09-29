package com.example.ej5_kmp

import android.app.Application
import com.example.ej5_kmp.filesystem.PlatformFileSystem
import com.example.ej5_kmp.settings.PlatformDataStore

/**
 * Se ejecuta una sola vez, antes que cualquier Activity. Aquí le pasamos el Context
 * a las piezas de la lógica compartida que lo necesitan en Android.
 */
class Ej5Application : Application() {
    override fun onCreate() {
        super.onCreate()
        PlatformFileSystem.init(this)
        PlatformDataStore.init(this)
    }
}
