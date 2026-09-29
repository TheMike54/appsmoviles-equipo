## Ejercicio 5 — Gestor de archivos con Kotlin Multiplatform

Responsable: Ian Gael Reyna Mendoza (boleta 2024630099).
Carpeta del proyecto: `ej5-kmp/` · Binario: `binarios/ej5-kmp.apk`

### Descripción

Gestor de archivos para Android e iOS con la lógica compartida en un módulo de Kotlin
Multiplatform (KMP). La interfaz es **nativa en cada plataforma** en vez de compartida: se
eligió esta variante (permitida explícitamente por el punto 5.2 del enunciado) porque la Mac
disponible para el equipo es una Mac virtual Intel sin GPU, y Compose Multiplatform ya no
publica librerías para `iosX64` ni funciona sin GPU (dibuja con Metal). La plantilla oficial
de Compose Multiplatform no llegó a compilar en esas condiciones, así que se optó por Jetpack
Compose (Material 3) en Android y SwiftUI en iOS, ambas consumiendo el mismo módulo
compartido `sharedLogic`. La app funciona completamente sin conexión a internet.

### Estructura del proyecto

| Carpeta | Contenido |
|---|---|
| `sharedLogic/` | Módulo KMP con la lógica común: modelo `FileEntry`, ordenamiento, archivos de ejemplo, preferencias (`AppSettings`) y las piezas `expect`/`actual` de sistema de archivos y DataStore. Genera el framework `SharedLogic` para iOS (`iosArm64`, `iosSimulatorArm64` e `iosX64`) |
| `sharedUI/` | Interfaz de Android con Jetpack Compose: pantalla, `ViewModel` con `StateFlow`, temas y acciones de plataforma |
| `androidApp/` | Aplicación Android (Activity, `Application`, manifiesto y `FileProvider`) |
| `iosApp/` | Aplicación iOS en SwiftUI que usa el framework `SharedLogic` |

### Funciones implementadas

- Explorar las carpetas de la app con íconos según el tipo de archivo y la ruta actual
  siempre visible.
- Abrir archivos de texto y ver imágenes.
- Crear carpetas; copiar, mover, renombrar y eliminar (con confirmación).
- Búsqueda dentro de la carpeta actual y orden por nombre, fecha o tamaño (ascendente o
  descendente).
- Recientes y favoritos persistentes.
- Preferencias guardadas: tema, criterio de orden y última carpeta visitada.
- Importar archivos con el selector del sistema y compartirlos con la hoja de compartir.
- Temas Guinda (`#6C1D45`) y Azul (`#0D2F5A`), con modo claro y oscuro según el sistema.

### Implementaciones `expect`/`actual`

| Declaración | Módulo | Android | iOS |
|---|---|---|---|
| `PlatformFileSystem` (listar, leer, escribir, crear, borrar, renombrar, copiar y mover) | `sharedLogic` | `java.io.File` con el `Context` de la app | `NSFileManager` sobre el directorio Documents |
| `PlatformDataStore` (dónde vive el archivo de preferencias) | `sharedLogic` | `dataDir` de la app | Application Support |
| `PlatformBackHandler` (botón atrás del sistema) | `sharedUI` | `BackHandler` | No existe; se usa el botón "Atrás" de la barra de navegación (Human Interface Guidelines) |
| `rememberFileImporter` (importar) | `sharedUI` | Storage Access Framework (`OpenDocument`) | `UIDocumentPickerViewController` |
| `rememberFileSharer` (compartir) | `sharedUI` | `Intent.ACTION_SEND` con `FileProvider` | `UIActivityViewController` |
| `loadImageBitmap` | `sharedUI` | `BitmapFactory` | `UIImage` |

**Permisos:** la app solo trabaja dentro de su almacenamiento interno (`filesDir` en Android,
Documents en iOS), por lo que no solicita permisos de almacenamiento ni de internet. Para
archivos externos se usan los selectores del sistema (Storage Access Framework / selector de
documentos de iOS), que otorgan acceso solo al archivo elegido sin requerir un permiso
declarado.

### Librerías

| Librería | Versión | Para qué |
|---|---|---|
| Kotlin / Kotlin Multiplatform | 2.4.20 | Lenguaje y módulos compartidos |
| kotlinx-coroutines-core | 1.10.2 | Asincronía (`Dispatchers`, `suspend`) |
| Flow / `StateFlow` | incluida en coroutines | Estado de la pantalla |
| androidx.datastore-preferences-core | 1.1.7 | Preferencias, favoritos y recientes |
| Jetpack Compose / Material 3 | Compose Multiplatform 1.12.1 | Interfaz de Android |
| AndroidX Activity y Core | 1.13.0 / 1.19.0 | Selector de archivos, botón atrás y `FileProvider` |

### Cómo compilar

Requisitos: JDK 21 y Android Studio con el plugin de Kotlin Multiplatform.

```bash
./gradlew :androidApp:assembleDebug
./gradlew :androidApp:assembleRelease
```

Para iOS: Mac con Xcode 15+, JDK 21 y Android SDK configurado; abrir
`iosApp/iosApp.xcodeproj` en Xcode y ejecutar en un simulador de iPhone.

### Coherencia Android ↔ iOS (punto 5.3)

La app de iOS (SwiftUI) implementa el mismo flujo y las mismas tres secciones que Android
(Explorar, Recientes, Favoritos), los mismos diálogos (nueva carpeta, renombrar, eliminar,
selector de destino para copiar/mover) y el mismo esquema de temas, respetando en cada
plataforma su propio patrón de navegación: Material 3 en Android y las Human Interface
Guidelines de Apple en iOS (por ejemplo, el botón "Atrás" en la barra superior en vez de
depender del botón físico/de gestos de Android).

### Capturas

Todas en `fotos/ian/`, tomadas en el emulador de Android.

| Captura | Muestra |
|---|---|
| `ej5_01_explorar_guinda-claro.png` | Pantalla principal, tema Guinda claro |
| `ej5_02_explorar_guinda-oscuro.png` | Tema Guinda oscuro |
| `ej5_03_explorar_azul-claro.png` | Tema Azul claro |
| `ej5_04_explorar_azul-oscuro.png` | Tema Azul oscuro |
| `ej5_05_ruta-actual_guinda-claro.png` | Ruta actual visible al entrar a una subcarpeta |
| `ej5_07_ver-imagen_guinda-claro.png` | Visor de imágenes |
| `ej5_08_crear-carpeta_guinda-claro.png` | Diálogo de nueva carpeta |
| `ej5_09_copiar_guinda-claro.png` | Selector de carpeta destino al copiar |
| `ej5_10_mover_guinda-claro.png` | Selector de carpeta destino al mover |
| `ej5_11_renombrar_guinda-claro.png` | Diálogo de renombrar |
| `ej5_12_eliminar-confirmacion_guinda-claro.png` | Confirmación antes de eliminar |
| `ej5_13_busqueda_guinda-claro.png` | Búsqueda por nombre dentro de la carpeta actual |
| `ej5_14_ordenamiento_guinda-claro.png` | Menú de orden (nombre, fecha, tamaño; ascendente/descendente) |
| `ej5_15_recientes_guinda-claro.png` | Pestaña Recientes |
| `ej5_16_favoritos_guinda-claro.png` | Pestaña Favoritos |
| `ej5_17_importar_guinda-claro.png` | Selector del sistema para importar un archivo |
| `ej5_18_compartir_guinda-claro.png` | Hoja de compartir del sistema |

## Pruebas realizadas — Ejercicio 5

Equipo de prueba: PC de Ian (ver especificaciones en el Ejercicio 1), emulador de Android
(Android Studio), compilación en modo depuración y en modo liberación.

| Prueba | Dispositivo | Resultado |
|---|---|---|
| Explorar carpetas con íconos por tipo de archivo | Emulador Android | Correcto |
| Ruta actual visible al navegar | Emulador Android | Correcto |
| Ver imagen | Emulador Android | Correcto |
| Crear carpeta | Emulador Android | Correcto |
| Copiar archivo/carpeta a otra carpeta | Emulador Android | Correcto |
| Mover archivo/carpeta a otra carpeta | Emulador Android | Correcto |
| Renombrar | Emulador Android | Correcto |
| Eliminar con confirmación | Emulador Android | Correcto |
| Búsqueda por nombre en la carpeta actual | Emulador Android | Correcto |
| Ordenar por nombre, fecha y tamaño, ascendente/descendente | Emulador Android | Correcto |
| Agregar y quitar favoritos | Emulador Android | Correcto |
| Registro automático en Recientes al abrir un archivo | Emulador Android | Correcto |
| Persistencia de tema, orden, favoritos, recientes y última carpeta al reabrir la app | Emulador Android | Correcto |
| Importar archivo con el selector del sistema | Emulador Android | Correcto |
| Compartir archivo con la hoja del sistema | Emulador Android | Correcto |
| Cambio de tema Guinda/Azul y claro/oscuro | Emulador Android | Correcto |
| Operación completa sin conexión a internet | Emulador Android | Correcto |
| Generación del APK en modo liberación | PC de Ian | Correcto |

## Especificaciones del equipo de Ian (para el Ejercicio 1)

| Dato | Valor |
|---|---|
| Procesador | AMD Ryzen 7 8700G con gráficos Radeon 780M |
| Núcleos / procesadores lógicos | 8 / 16 |
| Virtualización | Habilitada |
| Velocidad base | 4.20 GHz |
| Memoria RAM | 16.0 GB DDR5 a 6000 MT/s (1 de 4 ranuras) |
| Almacenamiento | SSD NVMe |
| Tarjeta gráfica | AMD Radeon 780M Graphics (2.2/9.7 GB en uso; 1.5/3.9 GB dedicada, 0.7/5.8 GB compartida) |
| Sistema operativo | Windows 11 |

Capturas del Administrador de tareas: `ej1_specs_cpu_ian.png`, `ej1_specs_memoria_ian.png`
y `ej1_specs_gpu_ian.png`.
