# Ejercicio 5 — Gestor de archivos con Kotlin Multiplatform

Gestor de archivos para **Android e iOS** con la lógica compartida en un módulo de Kotlin
Multiplatform. La interfaz es nativa en cada plataforma: **Jetpack Compose (Material 3)** en
Android y **SwiftUI** en iOS, ambas sobre el mismo módulo `sharedLogic`. Funciona sin
conexión a Internet: todo se guarda en el almacenamiento local de la app.

## Funciones

- Explorar las carpetas de la app con íconos según el tipo de archivo y la ruta actual siempre visible.
- Abrir archivos de texto y ver imágenes.
- Crear carpetas; copiar, mover, renombrar y eliminar (con confirmación).
- Búsqueda dentro de la carpeta actual y orden por nombre, fecha o tamaño (ascendente o descendente).
- Recientes y favoritos persistentes.
- Preferencias guardadas: tema, criterio de orden y última carpeta visitada.
- Importar archivos con el selector del sistema y compartirlos con la hoja de compartir.
- Temas **Guinda** (`#6C1D45`) y **Azul** (`#0D2F5A`), con modo claro y oscuro según el sistema.
- La primera vez que se abre, la app crea unas carpetas y archivos de ejemplo para poder probar
  todas las funciones.

## Estructura del proyecto

| Carpeta | Contenido |
|---|---|
| `sharedLogic/` | Módulo KMP con la lógica común: modelo `FileEntry`, ordenamiento, archivos de ejemplo, preferencias (`AppSettings`) y las piezas `expect`/`actual` de sistema de archivos y DataStore. Genera el framework `SharedLogic` para iOS (`iosArm64`, `iosSimulatorArm64` e `iosX64`). |
| `sharedUI/` | Interfaz de Android con Jetpack Compose: pantalla, `ViewModel` con `StateFlow`, temas y acciones de plataforma. |
| `androidApp/` | Aplicación Android (Activity, `Application`, manifiesto y `FileProvider`). |
| `iosApp/` | Aplicación iOS en SwiftUI que usa el framework `SharedLogic`. |

### Interfaz nativa en cada plataforma

La versión de iOS no usa Compose Multiplatform: se compila para un simulador de iPhone en
una Mac Intel sin GPU, donde Compose Multiplatform no publica librerías para `iosX64` y
dibuja con Metal. Por eso Android usa Jetpack Compose e iOS usa SwiftUI, y las dos comparten
`sharedLogic`, lo que el enunciado permite explícitamente.

### Implementaciones `expect`/`actual`

| Declaración | Módulo | Android | iOS |
|---|---|---|---|
| `PlatformFileSystem` (listar, leer, escribir, crear, borrar, renombrar, copiar y mover) | `sharedLogic` | `java.io.File` con el `Context` de la app | `NSFileManager` sobre el directorio Documents |
| `PlatformDataStore` (dónde vive el archivo de preferencias) | `sharedLogic` | `dataDir` de la app | Application Support |
| `PlatformBackHandler` (botón atrás del sistema) | `sharedUI` | `BackHandler` | No existe; se usa el botón "Atrás" de la barra de navegación |
| `rememberFileImporter` (importar) | `sharedUI` | Storage Access Framework (`OpenDocument`) | `fileImporter` de SwiftUI |
| `rememberFileSharer` (compartir) | `sharedUI` | `Intent.ACTION_SEND` con `FileProvider` | `ShareLink` de SwiftUI |
| `loadImageBitmap` y `formatDateTime` | `sharedUI` | `BitmapFactory` (con reducción de tamaño) y `DateFormat` | `UIImage` y `Date.formatted` en SwiftUI |

Las declaraciones de `sharedUI` solo tienen `actual` de Android; en iOS el equivalente se
escribe directamente en SwiftUI.

### Librerías

| Librería | Versión | Para qué |
|---|---|---|
| Kotlin / Kotlin Multiplatform | 2.4.20 | Lenguaje y módulos compartidos |
| kotlinx-coroutines-core | 1.10.2 | Asincronía (`Dispatchers`, `suspend`) |
| Flow / `StateFlow` | incluida en coroutines | Estado de la pantalla en Android |
| okio | 3.16.0 | Rutas de archivo para DataStore |
| androidx.datastore-preferences-core | 1.1.7 | Preferencias, favoritos y recientes |
| Jetpack Compose / Material 3 | Compose Multiplatform 1.12.1 | Interfaz de Android |
| AndroidX Activity y Core | 1.13.0 / 1.19.0 | Selector de archivos, botón atrás y `FileProvider` |

## Cómo compilar

Requisitos: **JDK 21** (el proyecto lo pide en `gradle/gradle-daemon-jvm.properties`; si no
lo tienes, Gradle lo descarga la primera vez, lo que necesita Internet solo al compilar) y
Android Studio con el plugin de Kotlin Multiplatform. La primera compilación descarga
dependencias, así que necesita conexión; la app ya instalada no.

**Android** (desde esta carpeta):

```bash
./gradlew :androidApp:assembleDebug
./gradlew :androidApp:assembleRelease
```

Los APK quedan en `androidApp/build/outputs/apk/debug/` y `.../release/` (el de release se
firma con la llave de depuración para poder instalarlo). También se puede abrir la carpeta en
Android Studio y ejecutar la configuración `androidApp` en un emulador.

**iOS:** requiere una Mac con Xcode 15 o superior, JDK 21 y el Android SDK (el módulo
compartido también declara el destino Android, así que Gradle necesita encontrar el SDK:
define `ANDROID_HOME` o crea `local.properties` con `sdk.dir=<ruta del SDK>`). Abrir
`iosApp/iosApp.xcodeproj` en Xcode, elegir un simulador de iPhone y ejecutar. Un paso previo
de la compilación llama a Gradle (`:sharedLogic:embedAndSignAppleFrameworkForXcode`) para
generar el framework `SharedLogic`, sin pasos manuales.

## Permisos

La app solo trabaja dentro de su almacenamiento interno (`filesDir` en Android, Documents en
iOS), por lo que no pide permisos de almacenamiento ni de Internet. Para leer archivos de
fuera se usan los selectores del sistema (Storage Access Framework en Android y el selector
de documentos en iOS), que otorgan acceso solo al archivo elegido. En iOS, el `Info.plist`
declara `UIFileSharingEnabled` y `LSSupportsOpeningDocumentsInPlace` para que los documentos
de la app se vean en la aplicación Archivos.
