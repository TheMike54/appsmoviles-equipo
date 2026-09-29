# Tabla comparativa: Flutter vs Kotlin Multiplatform 

| Criterio | Flutter (Ej4 — cámara y micrófono) | Kotlin Multiplatform (Ej5 — gestor de archivos) |
|---|---|---|
| **Lenguaje** | Dart | Kotlin (lógica compartida) + Swift (UI de iOS) |
| **Forma de construir la UI** | Un solo árbol de widgets de Flutter (Material 3), compilado a Android e iOS por igual mediante el motor de renderizado propio de Flutter (Skia/Impeller) | UI **nativa por separado en cada plataforma**: Jetpack Compose (Material 3) en Android y SwiftUI en iOS, ambas consumiendo el mismo módulo `sharedLogic`. No se usó Compose Multiplatform para iOS: no publica librerías para `iosX64` (Mac Intel) y dibuja con Metal, que esa Mac no tiene |
| **Acceso a APIs nativas** | A través de paquetes de pub.dev (`camera`, `image_picker`, `record`, `just_audio`, `sqflite`, `share_plus`): abstraen la API nativa detrás de una interfaz Dart | A través de 6 declaraciones `expect`/`actual` escritas a mano (sistema de archivos, DataStore, botón atrás, selector de archivos, compartir, carga de imágenes): acceso directo a `java.io.File`/`NSFileManager`, Storage Access Framework/`fileImporter`, `Intent.ACTION_SEND`/`ShareLink`, etc. Más control, pero hay que escribir y mantener cada puente dos veces |
| **Cantidad de código compartido** | ~100 % del código Dart de `lib/` (arquitectura por capas `data`/`domain`/`presentation`) corre igual en Android e iOS; solo la configuración nativa (`Info.plist`, `AndroidManifest.xml`) es específica de cada plataforma | Solo la capa de lógica (`sharedLogic/commonMain`: modelo de archivos, ordenamiento, preferencias) se comparte de verdad entre Android e iOS. La interfaz y el estado de pantalla (`ViewModel`/`StateFlow` en Compose, `FileBrowserModel` en SwiftUI) están escritos **por separado y dos veces**, uno en Kotlin y otro en Swift. En archivos fuente, el módulo verdaderamente compartido es una fracción pequeña del proyecto (`sharedLogic/commonMain` frente a `sharedUI` + `androidApp` + los `.swift` de `iosApp`) |
| **Tamaño del binario (APK de release, Android)** | 49.1 MB (`ej4-flutter.apk`): incluye el motor de renderizado de Flutter (Skia/Impeller) empaquetado dentro del APK | 13.1 MB (`ej5-kmp.apk`): al usar Jetpack Compose nativo de Android (sin un motor de renderizado adicional embebido) el binario resulta bastante más ligero, casi una cuarta parte del tamaño del de Flutter |
| **Curva de aprendizaje** | Un solo lenguaje (Dart) y un solo framework de UI para ambas plataformas: más rápido de aprender si nadie del equipo conocía Flutter antes | Requiere Kotlin **y** Swift/SwiftUI (para la parte nativa de iOS), además de entender el patrón `expect`/`actual`. Más pesada si el equipo no maneja ya ambos lenguajes |
| **Madurez del ecosistema** | Framework maduro (desde 2017), con paquetes de terceros estables para cámara, audio y persistencia ya probados en producción por muchos equipos | El módulo de lógica compartida de KMP (`commonMain`) es estable y usado en producción por empresas grandes, pero **Compose Multiplatform para iOS todavía es joven** — en este mismo proyecto no compiló para el hardware disponible (Mac Intel sin GPU), lo que obligó a usar SwiftUI nativo en su lugar |

## Conclusión argumentada (punto 5.5)

Para el tipo de aplicación que desarrollamos, **Flutter resultó más adecuado cuando el
objetivo es compartir la mayor cantidad de código posible entre plataformas con el menor
esfuerzo**: un solo lenguaje, una sola base de UI, y paquetes de pub.dev que ya resuelven el
acceso a cámara, micrófono y almacenamiento en ambas plataformas con poco código propio.

**Kotlin Multiplatform, en la variante que terminamos usando (UI nativa por plataforma en
lugar de Compose Multiplatform), resultó más adecuado para lograr una interfaz que se sienta
genuinamente nativa en cada sistema** (Material 3 real en Android, SwiftUI real en iOS, con
sus propios patrones de navegación), a costa de compartir mucho menos código: solo la capa
de datos y lógica de negocio, mientras que la interfaz se escribe y mantiene dos veces. Esta
decisión no fue por preferencia sino por una limitación real de hardware (la Mac Intel sin
GPU no soporta Compose Multiplatform para iOS), lo cual es en sí mismo un hallazgo relevante
de la práctica: la elección de framework multiplataforma no depende solo del lenguaje o el
equipo, sino también del hardware de compilación disponible.

En resumen: si la prioridad es velocidad de desarrollo y máximo código compartido, Flutter
gana; si la prioridad es una experiencia nativa "de verdad" en cada plataforma y se cuenta
con el hardware adecuado para Compose Multiplatform, KMP es competitivo — pero en nuestras
condiciones reales, terminamos pagando el costo de escribir la UI dos veces.
