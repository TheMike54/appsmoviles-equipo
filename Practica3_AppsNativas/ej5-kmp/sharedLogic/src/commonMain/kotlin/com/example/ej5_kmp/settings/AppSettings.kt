package com.example.ej5_kmp.settings

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import kotlinx.coroutines.flow.first

/**
 * expect/actual #3: dónde vive el archivo de preferencias (DataStore).
 * La ruta cambia por plataforma (Android: dataDir; iOS: Application Support),
 * pero todo lo demás (leer/guardar) es común y está en AppSettings.
 */
expect object PlatformDataStore {
    fun init(platformContext: Any?)
    fun get(): DataStore<Preferences>
}

/** Preferencias simples clave/valor (tema, y más adelante última carpeta, orden, etc.). */
object AppSettings {
    suspend fun getString(key: String): String? =
        PlatformDataStore.get().data.first()[stringPreferencesKey(key)]

    suspend fun putString(key: String, value: String) {
        PlatformDataStore.get().edit { it[stringPreferencesKey(key)] = value }
    }

    /** Listas de rutas (favoritos, recientes): se guardan como texto, una por línea. */
    suspend fun getList(key: String): List<String> =
        getString(key)?.split('\n')?.filter { it.isNotEmpty() } ?: emptyList()

    suspend fun putList(key: String, values: List<String>) {
        putString(key, values.joinToString("\n"))
    }
}
