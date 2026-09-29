package com.example.ej5_kmp.settings

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.PreferenceDataStoreFactory
import androidx.datastore.preferences.core.Preferences
import okio.Path.Companion.toPath
import java.io.File

actual object PlatformDataStore {

    private var appContext: Context? = null

    // Se guarda en dataDir (no en filesDir) para que el archivo de preferencias
    // NO aparezca dentro del explorador de archivos de la app.
    private val store: DataStore<Preferences> by lazy {
        val context = requireNotNull(appContext) { "PlatformDataStore.init(context) no se llamó" }
        PreferenceDataStoreFactory.createWithPath(
            produceFile = {
                File(context.dataDir, "datastore/app_settings.preferences_pb").absolutePath.toPath()
            }
        )
    }

    actual fun init(platformContext: Any?) {
        appContext = platformContext as Context
    }

    actual fun get(): DataStore<Preferences> = store
}
