@file:OptIn(ExperimentalForeignApi::class)

package com.example.ej5_kmp.settings

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.PreferenceDataStoreFactory
import androidx.datastore.preferences.core.Preferences
import kotlinx.cinterop.ExperimentalForeignApi
import okio.Path.Companion.toPath
import platform.Foundation.NSApplicationSupportDirectory
import platform.Foundation.NSSearchPathForDirectoriesInDomains
import platform.Foundation.NSUserDomainMask

// iOS: el archivo de preferencias vive en Application Support (no aparece en el explorador).
actual object PlatformDataStore {

    private val store: DataStore<Preferences> by lazy {
        PreferenceDataStoreFactory.createWithPath(
            produceFile = {
                val dir = NSSearchPathForDirectoriesInDomains(
                    NSApplicationSupportDirectory, NSUserDomainMask, true
                ).first() as String
                "$dir/app_settings.preferences_pb".toPath()
            }
        )
    }

    actual fun init(platformContext: Any?) {
        // iOS no necesita Context.
    }

    actual fun get(): DataStore<Preferences> = store
}
