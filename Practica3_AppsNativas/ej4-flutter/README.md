# Ejercicio 4 — Aplicación multiplataforma con Flutter (cámara y micrófono)

Responsable: Victor Eduardo Moreno López (boleta 2024630639).
Carpeta del proyecto: `ej4-flutter/` · Binario: `binarios/ej4-flutter.apk`

## 4.1 Qué hace la aplicación

La aplicación toma fotografías y graba audio, y guarda ambos en el almacenamiento del
propio dispositivo junto con sus metadatos (fecha, álbum, filtro aplicado y duración).
Funciona completamente sin conexión a internet: no consulta ningún servicio en línea y
todos los archivos y la base de datos viven dentro de la carpeta de documentos de la app.

Está organizada en cuatro pestañas, iguales y en el mismo orden en Android y en iOS:

**Cámara.** Vista previa en vivo con tres controles de captura:

- *Flash*, que alterna entre apagado, automático y linterna.
- *Temporizador* de 0, 3, 5 o 10 segundos; al dispararlo se muestra una cuenta regresiva
  en pantalla antes de tomar la foto.
- *Filtro*: Normal, Blanco y negro o Sepia. El filtro se ve aplicado en la vista previa y
  queda grabado en el archivo final, de modo que lo que el usuario ve es lo que se guarda.

Cuando el equipo no tiene cámara utilizable —por ejemplo el simulador de iPhone— o cuando
el usuario niega el permiso, la pantalla no se queda en blanco ni se traba: explica lo que
ocurrió y ofrece dos botones, *Elegir foto de la galería* y *Volver a intentar*. Esa es la
alternativa de captura que pide el ejercicio para entornos sin cámara física.

**Audio.** Grabadora con cronómetro en pantalla y dos opciones:

- *Sensibilidad* (Baja, Media o Alta), que configura el control automático de ganancia, la
  supresión de ruido y la cancelación de eco del micrófono.
- *Temporizador de grabación* de 15, 30, 60 o 120 segundos; al llegar al límite la
  grabación se detiene sola y el audio queda guardado.

Si el dispositivo no tiene micrófono, la app muestra un aviso explicándolo en lugar de
quedarse intentando grabar.

**Galería.** Las fotos se muestran en cuadrícula y los audios en una lista con su duración
y su fecha. Una fila de chips permite filtrar por álbum y crear álbumes nuevos.

- Al abrir una foto se puede *rotar* 90° y *volver a aplicar un filtro* (edición básica),
  además de compartirla o borrarla.
- Al abrir un audio se abre el reproductor, con reproducir/pausar y una barra de progreso
  que muestra la posición y la duración.
- Tanto las fotos como los audios se pueden exportar mediante la hoja de compartir del
  sistema operativo.

**Ajustes.** Selector del tema Guinda (IPN) o Azul (ESCOM). La elección se guarda en la
base de datos y se conserva al cerrar la aplicación. El modo claro u oscuro no se
configura aquí: la app sigue siempre la preferencia del sistema.

## 4.2 Arquitectura

El proyecto sigue una separación por capas al estilo de Clean Architecture. La regla es que
las dependencias apuntan siempre hacia adentro: la capa de presentación conoce únicamente
las interfaces declaradas en el dominio, y es la capa de datos la que las implementa. Así,
cambiar sqflite por otra base de datos no obligaría a tocar ninguna pantalla.

```
┌──────────────────────────────────────────────────────────┐
│ presentation                                             │
│   screens/   home, camera, audio, gallery, settings,     │
│              photo_detail, audio_player                  │
│   state/     ThemeProvider, GalleryProvider  (Provider)  │
│   theme/     AppTheme (Guinda / Azul, claro / oscuro)    │
│   utils/     photo_filters, audio_sensitivity            │
│   widgets/   MensajeEstado                               │
└───────────────────────────┬──────────────────────────────┘
                            │  depende de las interfaces
┌───────────────────────────▼──────────────────────────────┐
│ domain                                                   │
│   models/        MediaItem, MediaType                    │
│   repositories/  MediaRepository, SettingsRepository     │
│                  (contratos abstractos, sin Flutter)     │
└───────────────────────────▲──────────────────────────────┘
                            │  implementa los contratos
┌───────────────────────────┴──────────────────────────────┐
│ data                                                     │
│   db/            AppDatabase  (sqflite)                  │
│   repositories/  MediaRepositoryImpl                     │
│                  SettingsRepositoryImpl                  │
└──────────────────────────────────────────────────────────┘
```

**Gestión de estado: Provider.** `MultiProvider`, en `main.dart`, construye las
implementaciones concretas de la capa de datos y las inyecta. `GalleryProvider` mantiene la
lista de medios, los álbumes y el álbum seleccionado, y notifica a las pantallas cuando
algo cambia; `ThemeProvider` mantiene el tema elegido. Las pantallas de cámara y audio no
hablan con la base de datos: piden a `GalleryProvider` que guarde lo que capturaron.

**Persistencia: sqflite.** La base `ej4_flutter.db` tiene tres tablas:

| Tabla | Para qué |
|---|---|
| `media` | Metadatos de cada foto o audio: tipo, ruta, álbum, fecha, filtro y duración |
| `albums` | Nombres de álbumes, para que un álbum recién creado y vacío exista |
| `settings` | Preferencias en pares clave/valor; hoy guarda el tema elegido |

Los archivos no se guardan en la base: al capturar, el archivo se copia a
`documentos/ej4_flutter/fotos` o `…/audios` con un nombre único, y en la tabla `media` se
guarda su ruta. Cada edición de una foto genera un archivo nuevo y actualiza el registro,
en lugar de sobrescribir el archivo original; esto evita que Flutter siga mostrando la
imagen anterior desde su caché de imágenes, que se indexa por ruta.

## 4.3 Plugins utilizados

| Plugin | Versión | Para qué se usó y por qué |
|---|---|---|
| `camera` | 0.11.2 | Vista previa en vivo, captura y control de flash. Es el plugin oficial del equipo de Flutter y solicita por sí mismo el permiso de cámara al inicializarse |
| `image_picker` | 1.2.0 | Alternativa de captura sin cámara: elegir una imagen existente de la galería del sistema |
| `record` | 6.2.1 | Grabación de audio. Expone las opciones de ganancia automática, supresión de ruido y cancelación de eco con las que se implementó la sensibilidad, y pide el permiso de micrófono con `hasPermission()` |
| `just_audio` | 0.10.6 | Reproductor de los audios grabados, con posición y duración observables para la barra de progreso |
| `sqflite` | 2.4.1 | Base de datos local para los metadatos, los álbumes y las preferencias. Se eligió sobre Hive por ser SQL, lo que permite consultas y filtros por álbum directamente |
| `provider` | 6.1.5+1 | Gestión de estado e inyección de las implementaciones de la capa de datos |
| `path_provider` | 2.1.5 | Ubicación de la carpeta de documentos de la app, donde viven los archivos y la base |
| `path` | 1.9.0 | Construcción de rutas independiente del sistema operativo |
| `share_plus` | 12.0.2 | Exportar y compartir fotos y audios mediante la hoja del sistema |

Los filtros de imagen y la rotación **no** usan ningún paquete externo: se implementaron con
`dart:ui`, dibujando la imagen sobre un lienzo con una matriz de color (`ColorFilter.matrix`)
o con una transformación de rotación, y codificando el resultado. La misma matriz se usa en
la vista previa mediante el widget `ColorFiltered`, lo que garantiza que la foto guardada se
vea igual que la vista previa.

**Sobre `permission_handler`.** Se evaluó y se descartó. La versión disponible de su
implementación para Android (`permission_handler_android` 14.1.0) exige el Android Gradle
Plugin 9, Kotlin 2.3 y `compileSdk` 37, versiones incompatibles con Flutter 3.27.4, que es
la versión fijada por el equipo por ser la única que compila en el entorno macOS disponible.
Los permisos se resuelven sin esa dependencia: el plugin `camera` solicita el de cámara al
inicializar y `record` el de micrófono con `hasPermission()`, y la aplicación muestra un
aviso propio cuando cualquiera de los dos es denegado.

## 4.4 Permisos

Declarados en `android/app/src/main/AndroidManifest.xml`:

| Permiso | Para qué |
|---|---|
| `CAMERA` | Tomar fotografías |
| `RECORD_AUDIO` | Grabar audio |
| `READ_MEDIA_IMAGES`, `READ_MEDIA_AUDIO` | Elegir archivos existentes de la galería |
| `READ_EXTERNAL_STORAGE` (hasta SDK 32) | Equivalente a lo anterior en versiones previas a Android 13 |

Además, las tres características de hardware (`camera`, `camera.autofocus` y `microphone`)
se declaran con `required="false"`, para que la aplicación pueda instalarse y ejecutarse en
equipos sin cámara o sin micrófono mostrando sus alternativas.

En `ios/Runner/Info.plist` se declaran `NSCameraUsageDescription`,
`NSMicrophoneUsageDescription` y `NSPhotoLibraryUsageDescription`, cada una con el texto que
el sistema muestra al usuario al pedir el permiso.

## 4.5 Cómo compilar

Requiere **Flutter 3.27.4** y un JDK 17 o superior.

```
flutter pub get
flutter run                  # ejecutar en el dispositivo o emulador conectado
flutter build apk --release  # generar el APK
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk` y se entrega como
`binarios/ej4-flutter.apk`.

Configuración de compilación de Android y el motivo de cada versión:

| Componente | Versión | Motivo |
|---|---|---|
| Flutter | 3.27.4 | Versión acordada por el equipo; es la que compila en el entorno macOS disponible |
| Gradle | 8.9 | Versión mínima que requiere el Android Gradle Plugin 8.7 |
| Android Gradle Plugin | 8.7.2 | `androidx.core` 1.16.0 exige 8.6 o superior |
| Kotlin | 2.1.0 | `audio_session`, dependencia de `just_audio`, usa el DSL `compilerOptions`, introducido en Kotlin 2.0 |
| Java / `jvmTarget` | 17 | Los plugins actuales se distribuyen compilados con Java 17 |
| `minSdk` | 24 | Mínimo que exige `audio_session`; es el más alto entre todos los plugins usados |

## 4.6 Capturas

Las capturas se encuentran en `fotos/vic/` y siguen el formato
`ej4_NN_que-muestra_tema`:

| Captura | Muestra |
|---|---|
| `ej4_01_permiso-camara` | Solicitud del permiso de cámara del sistema |
| `ej4_02_camara-lista` | Vista previa con la barra de controles |
| `ej4_03_flash` | Control de flash activado |
| `ej4_04_menu-temporizador` | Opciones de temporizador de captura |
| `ej4_05_cuenta-regresiva` | Cuenta regresiva antes de disparar |
| `ej4_06_menu-filtros` | Opciones de filtro |
| `ej4_07_preview-sepia` | Vista previa con el filtro sepia aplicado |
| `ej4_08_foto-guardada` | Confirmación de guardado |
| `ej4_09_permiso-microfono` | Solicitud del permiso de micrófono del sistema |
| `ej4_10_grabadora` | Pantalla de audio en reposo |
| `ej4_11_menu-sensibilidad` | Opciones de sensibilidad del micrófono |
| `ej4_12_menu-temporizador-grabacion` | Opciones de duración máxima de grabación |
| `ej4_13_grabando` | Grabación en curso con el cronómetro |
| `ej4_14_audio-guardado` | Confirmación de guardado del audio |
| `ej4_15_galeria` | Galería con fotos y audios |
| `ej4_16_nuevo-album` | Creación de un álbum |
| `ej4_17_galeria-filtrada-album` | Galería filtrada por álbum |
| `ej4_18_detalle-foto` | Detalle de una foto con las opciones de edición |
| `ej4_19_foto-rotada` | La misma foto después de rotarla |
| `ej4_20_reproductor` | Reproductor de audio |
| `ej4_21_compartir` | Hoja de compartir del sistema |
| `ej4_22_sin-permiso-camara-alternativa` | Aviso al negar el permiso de cámara, con la alternativa de galería |
| `ej4_23_ajustes-tema_guinda-claro` | Tema Guinda en modo claro |
| `ej4_24_ajustes-tema_azul-claro` | Tema Azul en modo claro |
| `ej4_25_ajustes-tema_guinda-oscuro` | Tema Guinda en modo oscuro |
| `ej4_26_ajustes-tema_azul-oscuro` | Tema Azul en modo oscuro |

## Pruebas realizadas — Ejercicio 4

Equipo de prueba: Samsung SM-S938B (Android), compilación en modo depuración y en modo
liberación desde una computadora Windows 11 con Flutter 3.27.4.

| Prueba | Dispositivo | Resultado |
|---|---|---|
| Solicitud y concesión del permiso de cámara | SM-S938B | Correcto |
| Captura de fotografía | SM-S938B | Correcto |
| Cambio de modo de flash | SM-S938B | Correcto |
| Temporizador de captura con cuenta regresiva | SM-S938B | Correcto |
| Filtros en vista previa y en la foto guardada | SM-S938B | Correcto |
| Aviso y alternativa de galería al negar el permiso de cámara | SM-S938B | Correcto |
| Selección de una imagen existente de la galería | SM-S938B | Correcto |
| Solicitud y concesión del permiso de micrófono | SM-S938B | Correcto |
| Grabación de audio con cronómetro | SM-S938B | Correcto |
| Cambio de sensibilidad del micrófono | SM-S938B | Correcto |
| Detención automática al llegar al temporizador de grabación | SM-S938B | Correcto |
| Listado de fotos y audios en la galería | SM-S938B | Correcto |
| Creación de álbum y filtrado por álbum | SM-S938B | Correcto |
| Rotación de una fotografía | SM-S938B | Correcto |
| Reaplicación de filtro sobre una fotografía guardada | SM-S938B | Correcto |
| Reproducción de audio con barra de progreso | SM-S938B | Correcto |
| Exportar y compartir foto y audio | SM-S938B | Correcto |
| Cambio de tema Guinda / Azul y persistencia de la elección | SM-S938B | Correcto |
| Modo claro y oscuro siguiendo la preferencia del sistema | SM-S938B | Correcto |
| Operación completa sin conexión a internet | SM-S938B | Correcto |
| Generación del APK en modo liberación | Windows 11 | Correcto (49.1 MB) |

## Especificaciones del equipo de Vic (para el Ejercicio 1)

| Dato | Valor |
|---|---|
| Modelo | Honor X14 (nombre del equipo: Vicompu) |
| Procesador | Intel Core i5-10210U @ 1.60 GHz (frecuencia base 2.11 GHz) |
| Núcleos / procesadores lógicos | 4 / 8 |
| Virtualización | Habilitada |
| Memoria RAM | 8.00 GB SODIMM a 2400 MT/s (2 de 2 ranuras; 7.84 GB utilizables) |
| Almacenamiento | SSD NVMe, 226 GB libres de 421 GB |
| Tarjeta gráfica | Intel UHD Graphics (3.9 GB de memoria compartida, DirectX 12) |
| Sistema operativo | Windows 11 de 64 bits (compilación 10.0.22631) |

Capturas del Administrador de tareas: `ej1_specs_cpu_vic.png`, `ej1_specs_memoria_vic.png`
y `ej1_specs_gpu_vic.png`.
