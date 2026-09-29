# Práctica 3 — Aplicaciones Nativas

| | |
|---|---|
| **Escuela** | Escuela Superior de Cómputo (ESCOM) — Instituto Politécnico Nacional |
| **Unidad de aprendizaje** | Desarrollo de Aplicaciones Móviles Nativas |
| **Grupo** | 7CV4 |
| **Profesor** | Gabriel Hurtado Avilés |
| **Fecha de entrega** | 28 de septiembre de 2026 |

| Integrante | Boleta | GitHub | Ejercicios |
|---|---|---|---|
| Miguel Ángel Rodríguez Candelario | 2024630606 | [@TheMike54](https://github.com/TheMike54) | 1, 2 y 3 |
| Victor Eduardo Moreno López | 2024630639 | [@VictorMoreno-Code](https://github.com/VictorMoreno-Code) | 4 |
| Ian Gael Reyna Mendoza | 2024630099 | [@IanRey692](https://github.com/IanRey692) | 5 |

## Introducción

En esta práctica se desarrollaron aplicaciones móviles con tres enfoques distintos para
comparar qué implica cada uno: desarrollo **nativo puro** para iPhone con Swift y SwiftUI,
desarrollo **multiplataforma con un solo código** usando Flutter, y desarrollo con **lógica
compartida e interfaz nativa** usando Kotlin Multiplatform. Como ninguno de los integrantes
tiene una Mac, primero se instaló macOS con Xcode dentro de una máquina virtual en la PC más
potente del equipo, y desde ahí se compilaron y probaron todas las versiones de iOS.

| # | Ejercicio | Tecnología | Responsable | Carpeta |
|---|---|---|---|---|
| 1 | macOS y Xcode en la PC del equipo | Docker + QEMU (MacOS-Docker) | Miguel | [`fotos/mike/`](fotos/mike/) |
| 2 | Gestor de archivos para iPhone | Swift, SwiftUI, FileManager, Quick Look | Miguel | [`ej2-gestor-swift/`](ej2-gestor-swift/) |
| 3 | Cámara y micrófono para iPhone | Swift, SwiftUI, AVFoundation, Core Data | Miguel | [`ej3-camara-swift/`](ej3-camara-swift/) |
| 4 | Cámara y micrófono para Android e iOS | Flutter 3.27.4, Provider, sqflite | Vic | [`ej4-flutter/`](ej4-flutter/) |
| 5 | Gestor de archivos para Android e iOS | Kotlin Multiplatform, Jetpack Compose, SwiftUI | Ian | [`ej5-kmp/`](ej5-kmp/) |

Las cuatro aplicaciones funcionan sin conexión a internet (todos los datos se guardan en el
dispositivo), tienen los temas **Guinda** (`#6C1D45`) y **Azul** (`#0D2F5A`) con modo claro
y oscuro según el sistema, y piden los permisos con mensajes claros. Ninguna necesita llaves
ni configuración adicional para compilar.

## Desarrollo

### Ejercicio 1 — macOS y Xcode en la PC del equipo

#### 1.1 Comparación de las PCs del equipo

| Dato | PC de Miguel | PC de Ian | PC de Vic |
|---|---|---|---|
| Modelo | Razer Blade | — | Honor X14 |
| Procesador | Intel Core i7-12800H | AMD Ryzen 7 8700G | Intel Core i5-10210U |
| Núcleos / hilos | 14 / 20 | 8 / 16 | 4 / 8 |
| Virtualización | Habilitada | Habilitada | Habilitada |
| Memoria RAM | 32 GB DDR5 | 16 GB DDR5 | 8 GB |
| Almacenamiento | SSD NVMe | SSD NVMe | SSD NVMe (226 GB libres) |
| GPU | NVIDIA RTX 3080 Ti Laptop (16 GB) | AMD Radeon 780M (integrada) | Intel UHD Graphics (integrada) |
| Sistema operativo | Windows 11 | Windows 11 | Windows 11 |

**PC elegida: la de Miguel.** La máquina virtual de macOS necesita reservar para sí misma
varios núcleos y bastante memoria (a la nuestra se le asignaron 8 CPUs y, al final, 12 GB de
RAM), y además Windows, Docker y el emulador de Android tienen que seguir funcionando al mismo
tiempo. Con 8 GB de RAM la PC de Vic se quedaba sin memoria para el sistema anfitrión, y la de
Ian, aunque es buena, tiene la mitad de memoria y menos hilos que la de Miguel, que con 32 GB y
20 hilos podía darle a macOS lo que necesita sin dejar sin recursos a Windows.

Capturas del Administrador de tareas de cada PC:

<table>
<tr>
<td align="center"><img src="fotos/mike/ej1_01_pc_cpu_virtualizacion.png" width="230"><br><sub>ej1_01_pc_cpu_virtualizacion</sub></td>
<td align="center"><img src="fotos/mike/ej1_02_pc_memoria_32gb.png" width="230"><br><sub>ej1_02_pc_memoria_32gb</sub></td>
<td align="center"><img src="fotos/mike/ej1_03_pc_gpu.png" width="230"><br><sub>ej1_03_pc_gpu</sub></td>
</tr>
</table>
<table>
<tr>
<td align="center"><img src="fotos/ian/ej1_specs_cpu_ian.png" width="230"><br><sub>ej1_specs_cpu_ian</sub></td>
<td align="center"><img src="fotos/ian/ej1_specs_gpu_ian.png" width="230"><br><sub>ej1_specs_gpu_ian</sub></td>
<td align="center"><img src="fotos/ian/ej1_specs_memoria_ian.png" width="230"><br><sub>ej1_specs_memoria_ian</sub></td>
</tr>
</table>
<table>
<tr>
<td align="center"><img src="fotos/vic/ej1_specs_cpu_vic.png" width="230"><br><sub>ej1_specs_cpu_vic</sub></td>
<td align="center"><img src="fotos/vic/ej1_specs_gpu_vic.png" width="230"><br><sub>ej1_specs_gpu_vic</sub></td>
<td align="center"><img src="fotos/vic/ej1_specs_memoria_vic.png" width="230"><br><sub>ej1_specs_memoria_vic</sub></td>
</tr>
</table>

#### 1.2 Instalación de macOS y Xcode

Se usó el contenedor de macOS que compartió el profesor (MacOS-Docker), que corre macOS en
QEMU dentro de Docker. Los pasos fueron:

1. Comprobar que la virtualización está habilitada y que WSL 2 tiene acceso a KVM (`kvm-ok`).
2. Activar en Docker Desktop la integración con la distribución de WSL.
3. Arrancar el contenedor, que inicia en macOS Recovery.
4. Con la Utilidad de Discos, borrar el disco virtual y darle formato APFS.
5. Instalar macOS Ventura en ese volumen y hacer la configuración inicial (país, cuenta
   local, sin Apple ID).
6. Descargar Xcode e instalar el simulador de iPhone.
7. Crear un proyecto de SwiftUI y ejecutarlo en el simulador de iPhone 15.

Entorno final: macOS Ventura 13.7.8 (Intel x86_64) en Docker/QEMU, 8 CPUs y 12 GB de RAM
(el contenedor se creó con 8 GB, pero la Mac iba muy lenta y se trababa, así que se le subió
a 12 GB), Xcode 15.2 con el SDK de iOS 17.2 y simulador de iPhone 15 (iOS 17.2).

<table>
<tr>
<td align="center"><img src="fotos/mike/ej1_04_wsl_kvm-ok.png" width="230"><br><sub>ej1_04_wsl_kvm-ok</sub></td>
<td align="center"><img src="fotos/mike/ej1_05_docker_wsl_integracion_apagada.png" width="230"><br><sub>ej1_05_docker_wsl_integracion_apagada</sub></td>
<td align="center"><img src="fotos/mike/ej1_06_docker_wsl_integracion_activada.png" width="230"><br><sub>ej1_06_docker_wsl_integracion_activada</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej1_07_macos_recovery_arranque.png" width="230"><br><sub>ej1_07_macos_recovery_arranque</sub></td>
<td align="center"><img src="fotos/mike/ej1_08_diskutility_inicial.png" width="230"><br><sub>ej1_08_diskutility_inicial</sub></td>
<td align="center"><img src="fotos/mike/ej1_09_diskutility_borrar_config.png" width="230"><br><sub>ej1_09_diskutility_borrar_config</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej1_10_diskutility_borrando.png" width="230"><br><sub>ej1_10_diskutility_borrando</sub></td>
<td align="center"><img src="fotos/mike/ej1_11_diskutility_borrado_completo.png" width="230"><br><sub>ej1_11_diskutility_borrado_completo</sub></td>
<td align="center"><img src="fotos/mike/ej1_12_diskutility_volumen_macos_apfs.png" width="230"><br><sub>ej1_12_diskutility_volumen_macos_apfs</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej1_13_instalador_ventura_inicio.png" width="230"><br><sub>ej1_13_instalador_ventura_inicio</sub></td>
<td align="center"><img src="fotos/mike/ej1_14_instalador_licencia.png" width="230"><br><sub>ej1_14_instalador_licencia</sub></td>
<td align="center"><img src="fotos/mike/ej1_15_instalador_elegir_disco.png" width="230"><br><sub>ej1_15_instalador_elegir_disco</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej1_16_instalando_ventura_progreso.png" width="230"><br><sub>ej1_16_instalando_ventura_progreso</sub></td>
<td align="center"><img src="fotos/mike/ej1_17_menu_arranque_macos_installer.png" width="230"><br><sub>ej1_17_menu_arranque_macos_installer</sub></td>
<td align="center"><img src="fotos/mike/ej1_18_instalacion_logo_apple_progreso.png" width="230"><br><sub>ej1_18_instalacion_logo_apple_progreso</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej1_19_recursos_memoria_durante_instalacion.png" width="230"><br><sub>ej1_19_recursos_memoria_durante_instalacion</sub></td>
<td align="center"><img src="fotos/mike/ej1_20_macos_config_pais.png" width="230"><br><sub>ej1_20_macos_config_pais</sub></td>
<td align="center"><img src="fotos/mike/ej1_21_macos_config_appleid_omitido.png" width="230"><br><sub>ej1_21_macos_config_appleid_omitido</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej1_22_macos_config_cuenta_local.png" width="230"><br><sub>ej1_22_macos_config_cuenta_local</sub></td>
<td align="center"><img src="fotos/mike/ej1_23_macos_config_ubicacion.png" width="230"><br><sub>ej1_23_macos_config_ubicacion</sub></td>
<td align="center"><img src="fotos/mike/ej1_24_macos_escritorio_ventura.png" width="230"><br><sub>ej1_24_macos_escritorio_ventura</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej1_25_xcode_descarga_en_curso.png" width="230"><br><sub>ej1_25_xcode_descarga_en_curso</sub></td>
<td align="center"><img src="fotos/mike/ej1_26_proyecto_swiftui_en_simulador_iphone15.png" width="230"><br><sub>ej1_26_proyecto_swiftui_en_simulador_iphone15</sub></td>
<td align="center"><img src="fotos/mike/ej1_27_simulador_iphone15_en_macos_qemu.png" width="230"><br><sub>ej1_27_simulador_iphone15_en_macos_qemu</sub></td>
</tr>
</table>

#### 1.3 Limitaciones de la Mac virtual

Estas limitaciones del entorno afectaron a todas las versiones de iOS y se resolvieron así:

| Limitación | Consecuencia | Cómo se resolvió |
|---|---|---|
| No hay GPU (Metal) | SwiftUI y Quick Look usan renderizado por software; Flutter reciente se ve en negro | Filtros de imagen con `CIContext` por software (Ej3); Flutter 3.27.4 con Impeller desactivado (Ej4) |
| No hay dispositivo de audio | No se puede grabar audio en el simulador | Las apps revisan si hay micrófono y muestran un aviso; la grabación se prueba en Android |
| El simulador no tiene cámara | No hay vista previa en vivo | Las apps detectan que no hay cámara y ofrecen elegir una foto de la fototeca |
| Flutter estable exige macOS 14 | La versión actual de Flutter no arranca en macOS 13 | Se fijó Flutter 3.27.4 para todo el equipo |
| Compose Multiplatform no publica librerías para `iosX64` | La plantilla oficial de KMP no compila para el simulador Intel | Módulo compartido de KMP con interfaz nativa en cada plataforma (Ej5) |

Pruebas del entorno para Flutter: con Flutter 3.35.7 la app se veía en negro; con Flutter
3.27.4 y `FLTEnableImpeller = false` se ve bien.

Las pruebas del entorno y el desarrollo de los Ejercicios 2 y 3 se hicieron con apoyo de
Claude Code (asistente de IA de Anthropic), que se conectó a la Mac virtual por SSH para
compilar, ejecutar las pruebas y proponer soluciones a los errores que se describen en cada
ejercicio.

<table>
<tr>
<td align="center"><img src="fotos/mike/prueba_flutter327_simulador.png" width="230"><br><sub>prueba_flutter327_simulador</sub></td>
<td align="center"><img src="fotos/mike/prueba_flutter335_pantalla_negra.png" width="230"><br><sub>prueba_flutter335_pantalla_negra</sub></td>
</tr>
</table>

### Ejercicio 2 — Gestor de archivos nativo para iPhone (Swift)

Carpeta: [`ej2-gestor-swift/`](ej2-gestor-swift/)

Gestor de archivos escrito en Swift con SwiftUI que trabaja sobre el sandbox de la app
(carpeta Documentos). La lógica de archivos usa `FileManager` y la interfaz usa
`NavigationStack`, así que cada carpeta es una pantalla nueva con la ruta visible arriba.

**Funciones:**

- Navegar por carpetas con íconos según el tipo de archivo (`UniformTypeIdentifiers`), en
  vista de lista o de cuadrícula con miniaturas de las imágenes.
- Visor de texto y de código, visor de imágenes con zoom y rotación, y vista previa de PDF y
  otros formatos con Quick Look. Si un archivo está dañado, se muestra un error en vez de
  cerrarse la app.
- Crear carpetas, renombrar, copiar y mover (eligiendo la carpeta destino) y eliminar con
  confirmación, desde el menú contextual o deslizando la fila.
- Búsqueda, orden por nombre, fecha o tamaño, y jalar para actualizar.
- Compartir con la hoja del sistema (`UIActivityViewController`) e importar desde la app
  Archivos (`UIDocumentPickerViewController`).
- Recientes y favoritos; las preferencias (tema, orden, vista y última carpeta) se guardan con
  `UserDefaults` y se restauran al abrir la app.
- Los documentos de la app se ven también desde la app Archivos, en "En mi iPhone".

**Problemas que surgieron y cómo se resolvieron:**

| Problema | Causa | Solución |
|---|---|---|
| Error de enlazado `Undefined symbols … VistaCarpeta` | Error del compilador de Swift 5.9 al declarar `@Bindable var` dentro de un `Menu` de la barra de herramientas | Usar `Bindable(preferencias).orden` directamente en el `Picker` |
| Las carpetas con acento ("Código", "Imágenes") no se encontraban | El sistema de archivos de Apple guarda los acentos descompuestos (Unicode NFD) | Normalizar cada nombre con `precomposedStringWithCanonicalMapping` (también arregla la búsqueda) |
| La vista previa de PDF salía en blanco | `QLPreviewController` dentro de la pila de navegación de SwiftUI no dibuja en este entorno | Presentar Quick Look a pantalla completa con `.quickLookPreview`, como la app Archivos |
| Las filas no se podían localizar en las pruebas | SwiftUI junta nombre, tamaño y fecha en una sola etiqueta de accesibilidad | `.accessibilityIdentifier(nombre)` en cada fila |

**Cómo compilar:** abrir `ej2-gestor-swift/GestorArchivos.xcodeproj` en Xcode 15.2 o
posterior, elegir un simulador de iPhone y ejecutar (⌘R). No necesita ninguna configuración
adicional. Las pruebas se ejecutan con *Product ▸ Test* (⌘U).

<table>
<tr>
<td align="center"><img src="fotos/mike/ej2/ej2_01_raiz_sandbox.png" width="230"><br><sub>ej2_01_raiz_sandbox</sub></td>
<td align="center"><img src="fotos/mike/ej2/ej2_02_documentos_ruta.png" width="230"><br><sub>ej2_02_documentos_ruta</sub></td>
<td align="center"><img src="fotos/mike/ej2/ej2_03_visor_texto.png" width="230"><br><sub>ej2_03_visor_texto</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej2/ej2_04_visor_codigo.png" width="230"><br><sub>ej2_04_visor_codigo</sub></td>
<td align="center"><img src="fotos/mike/ej2/ej2_05_imagenes_miniaturas.png" width="230"><br><sub>ej2_05_imagenes_miniaturas</sub></td>
<td align="center"><img src="fotos/mike/ej2/ej2_06_visor_imagen.png" width="230"><br><sub>ej2_06_visor_imagen</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej2/ej2_07_visor_imagen_zoom_rotacion.png" width="230"><br><sub>ej2_07_visor_imagen_zoom_rotacion</sub></td>
<td align="center"><img src="fotos/mike/ej2/ej2_08_error_archivo_danado.png" width="230"><br><sub>ej2_08_error_archivo_danado</sub></td>
<td align="center"><img src="fotos/mike/ej2/ej2_09_quick_look_pdf.png" width="230"><br><sub>ej2_09_quick_look_pdf</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej2/ej2_10_crear_carpeta.png" width="230"><br><sub>ej2_10_crear_carpeta</sub></td>
<td align="center"><img src="fotos/mike/ej2/ej2_11_menu_contextual.png" width="230"><br><sub>ej2_11_menu_contextual</sub></td>
<td align="center"><img src="fotos/mike/ej2/ej2_12_renombrar.png" width="230"><br><sub>ej2_12_renombrar</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej2/ej2_13_copiar_elegir_destino.png" width="230"><br><sub>ej2_13_copiar_elegir_destino</sub></td>
<td align="center"><img src="fotos/mike/ej2/ej2_14_mover_elegir_destino.png" width="230"><br><sub>ej2_14_mover_elegir_destino</sub></td>
<td align="center"><img src="fotos/mike/ej2/ej2_15_resultado_copia_en_proyectos.png" width="230"><br><sub>ej2_15_resultado_copia_en_proyectos</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej2/ej2_16_deslizar_para_eliminar.png" width="230"><br><sub>ej2_16_deslizar_para_eliminar</sub></td>
<td align="center"><img src="fotos/mike/ej2/ej2_17_confirmar_eliminar.png" width="230"><br><sub>ej2_17_confirmar_eliminar</sub></td>
<td align="center"><img src="fotos/mike/ej2/ej2_18_carpeta_vacia.png" width="230"><br><sub>ej2_18_carpeta_vacia</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej2/ej2_19_menu_ordenar.png" width="230"><br><sub>ej2_19_menu_ordenar</sub></td>
<td align="center"><img src="fotos/mike/ej2/ej2_20_ordenado_por_tamano.png" width="230"><br><sub>ej2_20_ordenado_por_tamano</sub></td>
<td align="center"><img src="fotos/mike/ej2/ej2_21_busqueda.png" width="230"><br><sub>ej2_21_busqueda</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej2/ej2_22_jalar_para_actualizar.png" width="230"><br><sub>ej2_22_jalar_para_actualizar</sub></td>
<td align="center"><img src="fotos/mike/ej2/ej2_23_vista_cuadricula.png" width="230"><br><sub>ej2_23_vista_cuadricula</sub></td>
<td align="center"><img src="fotos/mike/ej2/ej2_24_hoja_compartir.png" width="230"><br><sub>ej2_24_hoja_compartir</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej2/ej2_25_importar_desde_archivos.png" width="230"><br><sub>ej2_25_importar_desde_archivos</sub></td>
<td align="center"><img src="fotos/mike/ej2/ej2_26_recientes.png" width="230"><br><sub>ej2_26_recientes</sub></td>
<td align="center"><img src="fotos/mike/ej2/ej2_27_favoritos.png" width="230"><br><sub>ej2_27_favoritos</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej2/ej2_28_restaura_ultima_carpeta.png" width="230"><br><sub>ej2_28_restaura_ultima_carpeta</sub></td>
<td align="center"><img src="fotos/mike/ej2/ej2_29_horizontal.png" width="230"><br><sub>ej2_29_horizontal</sub></td>
<td align="center"><img src="fotos/mike/ej2/ej2_30_tema_guinda_claro.png" width="230"><br><sub>ej2_30_tema_guinda_claro</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej2/ej2_30_tema_guinda_oscuro.png" width="230"><br><sub>ej2_30_tema_guinda_oscuro</sub></td>
<td align="center"><img src="fotos/mike/ej2/ej2_31_ajustes_tema_azul_claro.png" width="230"><br><sub>ej2_31_ajustes_tema_azul_claro</sub></td>
<td align="center"><img src="fotos/mike/ej2/ej2_31_ajustes_tema_azul_oscuro.png" width="230"><br><sub>ej2_31_ajustes_tema_azul_oscuro</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej2/ej2_32_tema_azul_claro.png" width="230"><br><sub>ej2_32_tema_azul_claro</sub></td>
<td align="center"><img src="fotos/mike/ej2/ej2_32_tema_azul_oscuro.png" width="230"><br><sub>ej2_32_tema_azul_oscuro</sub></td>
<td align="center"><img src="fotos/mike/ej2/ej2_33_app_archivos_en_mi_iphone.png" width="230"><br><sub>ej2_33_app_archivos_en_mi_iphone</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej2/ej2_34_app_archivos_carpeta_de_la_app.png" width="230"><br><sub>ej2_34_app_archivos_carpeta_de_la_app</sub></td>
</tr>
</table>

<details>
<summary>Capturas del código del Ejercicio 2</summary>

<table>
<tr>
<td align="center"><img src="fotos/mike/ej2_codigo/02_documentos__ServicioArchivos_listar.png" width="230"><br><sub>02_documentos__ServicioArchivos_listar</sub></td>
<td align="center"><img src="fotos/mike/ej2_codigo/03_menu_contextual__VistaCarpeta_menuContextual.png" width="230"><br><sub>03_menu_contextual__VistaCarpeta_menuContextual</sub></td>
<td align="center"><img src="fotos/mike/ej2_codigo/04_visor_texto__Visores_VisorTexto.png" width="230"><br><sub>04_visor_texto__Visores_VisorTexto</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej2_codigo/06_imagen_zoom__Visores_VisorImagen.png" width="230"><br><sub>06_imagen_zoom__Visores_VisorImagen</sub></td>
<td align="center"><img src="fotos/mike/ej2_codigo/07_error_archivo_danado__ServicioArchivos_ErrorArchivo.png" width="230"><br><sub>07_error_archivo_danado__ServicioArchivos_ErrorArchivo</sub></td>
<td align="center"><img src="fotos/mike/ej2_codigo/08_quick_look_pdf__Visores_VisorQuickLook.png" width="230"><br><sub>08_quick_look_pdf__Visores_VisorQuickLook</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej2_codigo/09_nueva_carpeta__ServicioArchivos_crearCarpeta.png" width="230"><br><sub>09_nueva_carpeta__ServicioArchivos_crearCarpeta</sub></td>
<td align="center"><img src="fotos/mike/ej2_codigo/10_deslizar_para_eliminar__VistaCarpeta_swipeActions.png" width="230"><br><sub>10_deslizar_para_eliminar__VistaCarpeta_swipeActions</sub></td>
<td align="center"><img src="fotos/mike/ej2_codigo/11_confirmar_eliminar__VistaCarpeta_swipeActions.png" width="230"><br><sub>11_confirmar_eliminar__VistaCarpeta_swipeActions</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej2_codigo/12_busqueda__VistaCarpeta_visibles.png" width="230"><br><sub>12_busqueda__VistaCarpeta_visibles</sub></td>
<td align="center"><img src="fotos/mike/ej2_codigo/13_cuadricula_miniaturas__ElementoArchivo_Orden.png" width="230"><br><sub>13_cuadricula_miniaturas__ElementoArchivo_Orden</sub></td>
<td align="center"><img src="fotos/mike/ej2_codigo/14_favoritos__Preferencias_alternarFavorito.png" width="230"><br><sub>14_favoritos__Preferencias_alternarFavorito</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej2_codigo/15_tema_azul__Tema_colores.png" width="230"><br><sub>15_tema_azul__Tema_colores</sub></td>
<td align="center"><img src="fotos/mike/ej2_codigo/16_info_plist__carpeta_en_cuadricula.png" width="230"><br><sub>16_info_plist__carpeta_en_cuadricula</sub></td>
<td align="center"><img src="fotos/mike/ej2_codigo/17_importar_archivos__PuentesUIKit_SelectorDocumentos.png" width="230"><br><sub>17_importar_archivos__PuentesUIKit_SelectorDocumentos</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej2_codigo/18_oscuro_inicio__Tema.png" width="230"><br><sub>18_oscuro_inicio__Tema</sub></td>
<td align="center"><img src="fotos/mike/ej2_codigo/19_oscuro_documentos__Pestanas_VistaExplorar.png" width="230"><br><sub>19_oscuro_documentos__Pestanas_VistaExplorar</sub></td>
<td align="center"><img src="fotos/mike/ej2_codigo/20_oscuro_imagenes__VistaCarpeta_FilaElemento.png" width="230"><br><sub>20_oscuro_imagenes__VistaCarpeta_FilaElemento</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej2_codigo/21_oscuro_ajustes_guinda__VistaCarpeta.png" width="230"><br><sub>21_oscuro_ajustes_guinda__VistaCarpeta</sub></td>
<td align="center"><img src="fotos/mike/ej2_codigo/22_oscuro_ajustes_azul__Tema_colores.png" width="230"><br><sub>22_oscuro_ajustes_azul__Tema_colores</sub></td>
</tr>
</table>
<table>
<tr>
<td align="center"><img src="fotos/mike/ej2_codigo/extras/05_imagenes_miniaturas__Visores_VisorTexto.png" width="230"><br><sub>05_imagenes_miniaturas__Visores_VisorTexto</sub></td>
<td align="center"><img src="fotos/mike/ej2_codigo/extras/06_imagen_zoom__CacheMiniaturas.png" width="230"><br><sub>06_imagen_zoom__CacheMiniaturas</sub></td>
<td align="center"><img src="fotos/mike/ej2_codigo/extras/07b_carpeta_documentos__ServicioArchivos_ErrorArchivo.png" width="230"><br><sub>07b_carpeta_documentos__ServicioArchivos_ErrorArchivo</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej2_codigo/extras/08b_menu_agregar__Visores_VisorQuickLook.png" width="230"><br><sub>08b_menu_agregar__Visores_VisorQuickLook</sub></td>
<td align="center"><img src="fotos/mike/ej2_codigo/extras/09b_nueva_carpeta__Visores_VisorQuickLook.png" width="230"><br><sub>09b_nueva_carpeta__Visores_VisorQuickLook</sub></td>
<td align="center"><img src="fotos/mike/ej2_codigo/extras/13b_menu_ordenar__VistaCarpeta_visibles.png" width="230"><br><sub>13b_menu_ordenar__VistaCarpeta_visibles</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej2_codigo/extras/13c_pantalla_inicial__ElementoArchivo_Orden.png" width="230"><br><sub>13c_pantalla_inicial__ElementoArchivo_Orden</sub></td>
<td align="center"><img src="fotos/mike/ej2_codigo/extras/14b_menu_contextual_notas__ElementoArchivo_Orden.png" width="230"><br><sub>14b_menu_contextual_notas__ElementoArchivo_Orden</sub></td>
<td align="center"><img src="fotos/mike/ej2_codigo/extras/15_ajustes__Preferencias.png" width="230"><br><sub>15_ajustes__Preferencias</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej2_codigo/extras/16b_info_plist__menu_agregar.png" width="230"><br><sub>16b_info_plist__menu_agregar</sub></td>
</tr>
</table>

</details>

### Ejercicio 3 — Cámara y micrófono nativa para iPhone (Swift)

Carpeta: [`ej3-camara-swift/`](ej3-camara-swift/)

Aplicación en Swift y SwiftUI que toma fotos y graba audio con AVFoundation, y guarda los
metadatos (fecha, álbum, filtro, duración) con Core Data. El modelo de Core Data se definió
en código (`NSManagedObjectModel`) para no depender del editor gráfico de Xcode.

**Funciones:**

- Cámara con flash, temporizador con cuenta regresiva y filtros (Core Image) con editor antes
  de guardar.
- Si no hay cámara, como en el simulador, el disparador abre la fototeca con
  `PHPickerViewController`; el flash y el temporizador siguen funcionando.
- Grabadora con cronómetro, temporizador de grabación y opciones de grabación. Si el equipo no
  tiene micrófono, la app lo detecta con `AVAudioSession.isInputAvailable` y muestra un aviso.
- Galería con fotos y audios, álbumes, filtro por tipo, detalle de cada foto con sus
  metadatos, edición, reproductor de audio, mover a otro álbum, exportar e importar.
- Permisos de cámara, micrófono y fototeca con su texto en `Info.plist`.

**Problemas que surgieron y cómo se resolvieron:**

| Problema | Causa | Solución |
|---|---|---|
| El simulador no tiene cámara | `AVCaptureDevice.default(...)` devuelve `nil` | Detectarlo y abrir la fototeca como fuente alternativa |
| La Mac virtual no tiene micrófono | QEMU no emula un dispositivo de audio | Aviso claro en la grabadora; el reproductor se demuestra con un tono de ejemplo que genera la app |
| Error de compilación en los filtros (`trailing 'where' clause for extension of non-generic type 'CIFilter'`) | Swift 5.9 no permite extender `CIFilter` con `where Self: CIPhotoEffect` | Función auxiliar `efecto(_ filtro: CIFilter & CIPhotoEffect, …)` |
| Los filtros no deben depender de la GPU | La Mac virtual no tiene Metal | `CIContext(options: [.useSoftwareRenderer: true])` |
| La cuenta regresiva no se leía | Sin cámara el fondo es claro (blanco sobre blanco) | Número dentro de un círculo del color del tema |

**Cómo compilar:** abrir `ej3-camara-swift/CamaraMicrofono.xcodeproj` en Xcode 15.2 o
posterior, elegir un simulador de iPhone y ejecutar (⌘R). Las pruebas se ejecutan con
*Product ▸ Test* (⌘U).

<table>
<tr>
<td align="center"><img src="fotos/mike/ej3/ej3_01_permiso_1.png" width="230"><br><sub>ej3_01_permiso_1</sub></td>
<td align="center"><img src="fotos/mike/ej3/ej3_01_permiso_2.png" width="230"><br><sub>ej3_01_permiso_2</sub></td>
<td align="center"><img src="fotos/mike/ej3/ej3_02_camara_sin_dispositivo.png" width="230"><br><sub>ej3_02_camara_sin_dispositivo</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej3/ej3_03_menu_flash.png" width="230"><br><sub>ej3_03_menu_flash</sub></td>
<td align="center"><img src="fotos/mike/ej3/ej3_04_menu_temporizador.png" width="230"><br><sub>ej3_04_menu_temporizador</sub></td>
<td align="center"><img src="fotos/mike/ej3/ej3_05_flash_y_temporizador_activos.png" width="230"><br><sub>ej3_05_flash_y_temporizador_activos</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej3/ej3_06_cuenta_regresiva.png" width="230"><br><sub>ej3_06_cuenta_regresiva</sub></td>
<td align="center"><img src="fotos/mike/ej3/ej3_07_fototeca_phpicker.png" width="230"><br><sub>ej3_07_fototeca_phpicker</sub></td>
<td align="center"><img src="fotos/mike/ej3/ej3_08_editor_sin_filtro.png" width="230"><br><sub>ej3_08_editor_sin_filtro</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej3/ej3_09_editor_filtro_sepia.png" width="230"><br><sub>ej3_09_editor_filtro_sepia</sub></td>
<td align="center"><img src="fotos/mike/ej3/ej3_10_galeria_con_foto_nueva.png" width="230"><br><sub>ej3_10_galeria_con_foto_nueva</sub></td>
<td align="center"><img src="fotos/mike/ej3/ej3_11_permiso_1.png" width="230"><br><sub>ej3_11_permiso_1</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej3/ej3_12_grabadora.png" width="230"><br><sub>ej3_12_grabadora</sub></td>
<td align="center"><img src="fotos/mike/ej3/ej3_13_temporizador_grabacion.png" width="230"><br><sub>ej3_13_temporizador_grabacion</sub></td>
<td align="center"><img src="fotos/mike/ej3/ej3_14_grabadora_opciones.png" width="230"><br><sub>ej3_14_grabadora_opciones</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej3/ej3_14b_grabando.png" width="230"><br><sub>ej3_14b_grabando</sub></td>
<td align="center"><img src="fotos/mike/ej3/ej3_14c_despues_de_grabar.png" width="230"><br><sub>ej3_14c_despues_de_grabar</sub></td>
<td align="center"><img src="fotos/mike/ej3/ej3_15_galeria.png" width="230"><br><sub>ej3_15_galeria</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej3/ej3_16_album_escom.png" width="230"><br><sub>ej3_16_album_escom</sub></td>
<td align="center"><img src="fotos/mike/ej3/ej3_17_filtro_audios.png" width="230"><br><sub>ej3_17_filtro_audios</sub></td>
<td align="center"><img src="fotos/mike/ej3/ej3_18_detalle_foto_metadatos.png" width="230"><br><sub>ej3_18_detalle_foto_metadatos</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej3/ej3_19_editar_foto.png" width="230"><br><sub>ej3_19_editar_foto</sub></td>
<td align="center"><img src="fotos/mike/ej3/ej3_20_foto_editada.png" width="230"><br><sub>ej3_20_foto_editada</sub></td>
<td align="center"><img src="fotos/mike/ej3/ej3_21_reproductor.png" width="230"><br><sub>ej3_21_reproductor</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej3/ej3_22_reproduciendo.png" width="230"><br><sub>ej3_22_reproduciendo</sub></td>
<td align="center"><img src="fotos/mike/ej3/ej3_23_menu_contextual.png" width="230"><br><sub>ej3_23_menu_contextual</sub></td>
<td align="center"><img src="fotos/mike/ej3/ej3_24_mover_a_album.png" width="230"><br><sub>ej3_24_mover_a_album</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej3/ej3_25_exportar.png" width="230"><br><sub>ej3_25_exportar</sub></td>
<td align="center"><img src="fotos/mike/ej3/ej3_26_importar.png" width="230"><br><sub>ej3_26_importar</sub></td>
<td align="center"><img src="fotos/mike/ej3/ej3_27_nuevo_album.png" width="230"><br><sub>ej3_27_nuevo_album</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej3/ej3_28_album_creado.png" width="230"><br><sub>ej3_28_album_creado</sub></td>
<td align="center"><img src="fotos/mike/ej3/ej3_29_tema_guinda_claro.png" width="230"><br><sub>ej3_29_tema_guinda_claro</sub></td>
<td align="center"><img src="fotos/mike/ej3/ej3_29_tema_guinda_oscuro.png" width="230"><br><sub>ej3_29_tema_guinda_oscuro</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej3/ej3_30_ajustes_azul_claro.png" width="230"><br><sub>ej3_30_ajustes_azul_claro</sub></td>
<td align="center"><img src="fotos/mike/ej3/ej3_30_ajustes_azul_oscuro.png" width="230"><br><sub>ej3_30_ajustes_azul_oscuro</sub></td>
<td align="center"><img src="fotos/mike/ej3/ej3_31_tema_azul_claro.png" width="230"><br><sub>ej3_31_tema_azul_claro</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej3/ej3_31_tema_azul_oscuro.png" width="230"><br><sub>ej3_31_tema_azul_oscuro</sub></td>
</tr>
</table>

<details>
<summary>Capturas del código del Ejercicio 3</summary>

<table>
<tr>
<td align="center"><img src="fotos/mike/ej3_codigo/01_permiso_camara__Info_plist.png" width="230"><br><sub>01_permiso_camara__Info_plist</sub></td>
<td align="center"><img src="fotos/mike/ej3_codigo/02_sin_camara_flash_encendido__VistaCamara.png" width="230"><br><sub>02_sin_camara_flash_encendido__VistaCamara</sub></td>
<td align="center"><img src="fotos/mike/ej3_codigo/03_menu_flash__VistaCamara_Picker.png" width="230"><br><sub>03_menu_flash__VistaCamara_Picker</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej3_codigo/04_cuenta_regresiva__VistaCamara_disparar.png" width="230"><br><sub>04_cuenta_regresiva__VistaCamara_disparar</sub></td>
<td align="center"><img src="fotos/mike/ej3_codigo/05_fototeca_phpicker__PuentesUIKit_SelectorFototeca.png" width="230"><br><sub>05_fototeca_phpicker__PuentesUIKit_SelectorFototeca</sub></td>
<td align="center"><img src="fotos/mike/ej3_codigo/06_filtro_sepia__Filtros_aplicar.png" width="230"><br><sub>06_filtro_sepia__Filtros_aplicar</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej3_codigo/07_galeria__VistaGaleria.png" width="230"><br><sub>07_galeria__VistaGaleria</sub></td>
<td align="center"><img src="fotos/mike/ej3_codigo/08_detalle_metadatos__Persistencia_modelo.png" width="230"><br><sub>08_detalle_metadatos__Persistencia_modelo</sub></td>
<td align="center"><img src="fotos/mike/ej3_codigo/09_editar_foto_noir_girada__DetalleMedio_EditorFoto.png" width="230"><br><sub>09_editar_foto_noir_girada__DetalleMedio_EditorFoto</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej3_codigo/10_reproductor__ServicioAudio_Reproductor.png" width="230"><br><sub>10_reproductor__ServicioAudio_Reproductor</sub></td>
<td align="center"><img src="fotos/mike/ej3_codigo/11_nuevo_album__VistaGaleria_crearAlbum.png" width="230"><br><sub>11_nuevo_album__VistaGaleria_crearAlbum</sub></td>
<td align="center"><img src="fotos/mike/ej3_codigo/12_permiso_microfono__Info_plist.png" width="230"><br><sub>12_permiso_microfono__Info_plist</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej3_codigo/13_grabadora_sensibilidad_alta__ServicioAudio_Sensibilidad.png" width="230"><br><sub>13_grabadora_sensibilidad_alta__ServicioAudio_Sensibilidad</sub></td>
<td align="center"><img src="fotos/mike/ej3_codigo/14_sin_microfono__ServicioAudio_deteccion.png" width="230"><br><sub>14_sin_microfono__ServicioAudio_deteccion</sub></td>
<td align="center"><img src="fotos/mike/ej3_codigo/15_ajustes_tema_azul__Pestanas_VistaAjustes.png" width="230"><br><sub>15_ajustes_tema_azul__Pestanas_VistaAjustes</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej3_codigo/16_exportar__AlmacenMedios.png" width="230"><br><sub>16_exportar__AlmacenMedios</sub></td>
<td align="center"><img src="fotos/mike/ej3_codigo/17_galeria_modo_oscuro__VistaGaleria.png" width="230"><br><sub>17_galeria_modo_oscuro__VistaGaleria</sub></td>
<td align="center"><img src="fotos/mike/ej3_codigo/18_ajustes_modo_oscuro__VistaGaleria.png" width="230"><br><sub>18_ajustes_modo_oscuro__VistaGaleria</sub></td>
</tr>
</table>
<table>
<tr>
<td align="center"><img src="fotos/mike/ej3_codigo/extras/04b_fototeca_tras_cuenta__VistaCamara.png" width="230"><br><sub>04b_fototeca_tras_cuenta__VistaCamara</sub></td>
<td align="center"><img src="fotos/mike/ej3_codigo/extras/05b_nueva_foto_cargando__PuentesUIKit.png" width="230"><br><sub>05b_nueva_foto_cargando__PuentesUIKit</sub></td>
<td align="center"><img src="fotos/mike/ej3_codigo/extras/05c_nueva_foto__PuentesUIKit.png" width="230"><br><sub>05c_nueva_foto__PuentesUIKit</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej3_codigo/extras/07_galeria__Filtros.png" width="230"><br><sub>07_galeria__Filtros</sub></td>
<td align="center"><img src="fotos/mike/ej3_codigo/extras/08b_editar_foto__Persistencia.png" width="230"><br><sub>08b_editar_foto__Persistencia</sub></td>
<td align="center"><img src="fotos/mike/ej3_codigo/extras/08c_editar_foto_noir__Persistencia.png" width="230"><br><sub>08c_editar_foto_noir__Persistencia</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej3_codigo/extras/09b_detalle_noir__DetalleMedio.png" width="230"><br><sub>09b_detalle_noir__DetalleMedio</sub></td>
<td align="center"><img src="fotos/mike/ej3_codigo/extras/10_reproductor__DetalleMedio.png" width="230"><br><sub>10_reproductor__DetalleMedio</sub></td>
<td align="center"><img src="fotos/mike/ej3_codigo/extras/14b_ajustes_guinda__ServicioAudio.png" width="230"><br><sub>14b_ajustes_guinda__ServicioAudio</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/mike/ej3_codigo/extras/16b_exportar__AlmacenMedios.png" width="230"><br><sub>16b_exportar__AlmacenMedios</sub></td>
</tr>
</table>

</details>

### Ejercicio 4 — Flutter para Android e iOS (cámara y micrófono)

Carpeta: [`ej4-flutter/`](ej4-flutter/) · Informe completo (arquitectura, plugins, permisos,
compilación y pruebas): [`ej4-flutter/README.md`](ej4-flutter/README.md) · APK:
[`binarios/ej4-flutter.apk`](binarios/ej4-flutter.apk)

Aplicación de cámara y grabadora con cuatro pestañas (Cámara, Audio, Galería y Ajustes),
organizada por capas (presentación, dominio y datos), con Provider para el estado y sqflite
para los metadatos.

**Cómo compilar:** con Flutter 3.27.4 y JDK 17 o superior, dentro de `ej4-flutter/`:
`flutter pub get` y después `flutter run` (o `flutter build apk --release` para generar el
APK). Para iOS, lo mismo en una Mac con Xcode y un simulador de iPhone abierto.

**Android** (dispositivo físico Samsung SM-S938B):

<table>
<tr>
<td align="center"><img src="fotos/vic/ej4_01_permiso-camara_sistema.jpeg" width="230"><br><sub>ej4_01_permiso-camara_sistema</sub></td>
<td align="center"><img src="fotos/vic/ej4_02_camara-lista_azul-claro.jpeg" width="230"><br><sub>ej4_02_camara-lista_azul-claro</sub></td>
<td align="center"><img src="fotos/vic/ej4_03_flash_azul-claro.jpeg" width="230"><br><sub>ej4_03_flash_azul-claro</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/vic/ej4_04_menu-temporizador_azul-claro.jpeg" width="230"><br><sub>ej4_04_menu-temporizador_azul-claro</sub></td>
<td align="center"><img src="fotos/vic/ej4_05_cuenta-regresiva_azul-claro.jpeg" width="230"><br><sub>ej4_05_cuenta-regresiva_azul-claro</sub></td>
<td align="center"><img src="fotos/vic/ej4_06_menu-filtros_azul-claro.jpeg" width="230"><br><sub>ej4_06_menu-filtros_azul-claro</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/vic/ej4_07_preview-sepia_azul-claro.jpeg" width="230"><br><sub>ej4_07_preview-sepia_azul-claro</sub></td>
<td align="center"><img src="fotos/vic/ej4_08_foto-guardada_azul-claro.jpeg" width="230"><br><sub>ej4_08_foto-guardada_azul-claro</sub></td>
<td align="center"><img src="fotos/vic/ej4_09_permiso-microfono_sistema.jpeg" width="230"><br><sub>ej4_09_permiso-microfono_sistema</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/vic/ej4_10_grabadora_azul-claro.jpeg" width="230"><br><sub>ej4_10_grabadora_azul-claro</sub></td>
<td align="center"><img src="fotos/vic/ej4_11_menu-sensibilidad_azul-claro.jpeg" width="230"><br><sub>ej4_11_menu-sensibilidad_azul-claro</sub></td>
<td align="center"><img src="fotos/vic/ej4_12_menu-temporizador-grabacion_azul-claro.jpeg" width="230"><br><sub>ej4_12_menu-temporizador-grabacion_azul-claro</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/vic/ej4_13_grabando_azul-claro.jpeg" width="230"><br><sub>ej4_13_grabando_azul-claro</sub></td>
<td align="center"><img src="fotos/vic/ej4_14_audio-guardado_azul-claro.jpeg" width="230"><br><sub>ej4_14_audio-guardado_azul-claro</sub></td>
<td align="center"><img src="fotos/vic/ej4_15_galeria_azul-claro.jpeg" width="230"><br><sub>ej4_15_galeria_azul-claro</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/vic/ej4_16_nuevo-album_azul-claro.jpeg" width="230"><br><sub>ej4_16_nuevo-album_azul-claro</sub></td>
<td align="center"><img src="fotos/vic/ej4_17_galeria-filtrada-album_azul-claro.jpeg" width="230"><br><sub>ej4_17_galeria-filtrada-album_azul-claro</sub></td>
<td align="center"><img src="fotos/vic/ej4_18_detalle-foto_azul-claro.jpeg" width="230"><br><sub>ej4_18_detalle-foto_azul-claro</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/vic/ej4_19_foto-rotada_azul-claro.jpeg" width="230"><br><sub>ej4_19_foto-rotada_azul-claro</sub></td>
<td align="center"><img src="fotos/vic/ej4_20_reproductor_azul-claro.jpeg" width="230"><br><sub>ej4_20_reproductor_azul-claro</sub></td>
<td align="center"><img src="fotos/vic/ej4_21_compartir_azul-claro.jpeg" width="230"><br><sub>ej4_21_compartir_azul-claro</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/vic/ej4_22_sin-permiso-camara-alternativa_azul-oscuro.jpeg" width="230"><br><sub>ej4_22_sin-permiso-camara-alternativa_azul-oscuro</sub></td>
<td align="center"><img src="fotos/vic/ej4_23_ajustes-tema_guinda-claro.jpeg" width="230"><br><sub>ej4_23_ajustes-tema_guinda-claro</sub></td>
<td align="center"><img src="fotos/vic/ej4_24_ajustes-tema_azul-claro.jpeg" width="230"><br><sub>ej4_24_ajustes-tema_azul-claro</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/vic/ej4_25_ajustes-tema_guinda-oscuro.jpeg" width="230"><br><sub>ej4_25_ajustes-tema_guinda-oscuro</sub></td>
<td align="center"><img src="fotos/vic/ej4_26_ajustes-tema_azul-oscuro.jpeg" width="230"><br><sub>ej4_26_ajustes-tema_azul-oscuro</sub></td>
</tr>
</table>

**iOS** (simulador de iPhone 15 en la Mac virtual). Como el simulador no tiene cámara, la
app muestra su alternativa de elegir una foto de la galería; las funciones de la cámara en
vivo (flash, temporizador y filtros en la vista previa) se ven en las capturas de Android.

<table>
<tr>
<td align="center"><img src="fotos/vic/ios/ej4_ios_01_info-plist-permisos_guinda-claro.png" width="230"><br><sub>ej4_ios_01_info-plist-permisos_guinda-claro</sub></td>
<td align="center"><img src="fotos/vic/ios/ej4_ios_02_camara-sin-camara-alternativa_guinda-claro.png" width="230"><br><sub>ej4_ios_02_camara-sin-camara-alternativa_guinda-claro</sub></td>
<td align="center"><img src="fotos/vic/ios/ej4_ios_03_selector-de-fotos_guinda-claro.png" width="230"><br><sub>ej4_ios_03_selector-de-fotos_guinda-claro</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/vic/ios/ej4_ios_04_foto-guardada_guinda-claro.png" width="230"><br><sub>ej4_ios_04_foto-guardada_guinda-claro</sub></td>
<td align="center"><img src="fotos/vic/ios/ej4_ios_05_permiso-microfono-sistema_guinda-claro.png" width="230"><br><sub>ej4_ios_05_permiso-microfono-sistema_guinda-claro</sub></td>
<td align="center"><img src="fotos/vic/ios/ej4_ios_06_permiso-microfono-info-plist_guinda-claro.png" width="230"><br><sub>ej4_ios_06_permiso-microfono-info-plist_guinda-claro</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/vic/ios/ej4_ios_07_grabadora-en-reposo_guinda-claro.png" width="230"><br><sub>ej4_ios_07_grabadora-en-reposo_guinda-claro</sub></td>
<td align="center"><img src="fotos/vic/ios/ej4_ios_08_grabando-con-cronometro_guinda-claro.png" width="230"><br><sub>ej4_ios_08_grabando-con-cronometro_guinda-claro</sub></td>
<td align="center"><img src="fotos/vic/ios/ej4_ios_09_audio-guardado_guinda-claro.png" width="230"><br><sub>ej4_ios_09_audio-guardado_guinda-claro</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/vic/ios/ej4_ios_10_galeria-foto-y-audio_guinda-claro.png" width="230"><br><sub>ej4_ios_10_galeria-foto-y-audio_guinda-claro</sub></td>
<td align="center"><img src="fotos/vic/ios/ej4_ios_11_detalle-foto_guinda-claro.png" width="230"><br><sub>ej4_ios_11_detalle-foto_guinda-claro</sub></td>
<td align="center"><img src="fotos/vic/ios/ej4_ios_12_foto-rotada_guinda-claro.png" width="230"><br><sub>ej4_ios_12_foto-rotada_guinda-claro</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/vic/ios/ej4_ios_13_galeria-tras-editar_guinda-claro.png" width="230"><br><sub>ej4_ios_13_galeria-tras-editar_guinda-claro</sub></td>
<td align="center"><img src="fotos/vic/ios/ej4_ios_14_nuevo-album_guinda-claro.png" width="230"><br><sub>ej4_ios_14_nuevo-album_guinda-claro</sub></td>
<td align="center"><img src="fotos/vic/ios/ej4_ios_15_ajustes-tema_guinda-claro.png" width="230"><br><sub>ej4_ios_15_ajustes-tema_guinda-claro</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/vic/ios/ej4_ios_16_ajustes-codigo-radiolisttile_guinda-claro.png" width="230"><br><sub>ej4_ios_16_ajustes-codigo-radiolisttile_guinda-claro</sub></td>
<td align="center"><img src="fotos/vic/ios/ej4_ios_17_ajustes-tema_azul-claro.png" width="230"><br><sub>ej4_ios_17_ajustes-tema_azul-claro</sub></td>
<td align="center"><img src="fotos/vic/ios/ej4_ios_18_ajustes-tema_azul-oscuro.png" width="230"><br><sub>ej4_ios_18_ajustes-tema_azul-oscuro</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/vic/ios/ej4_ios_19_ajustes-tema_guinda-oscuro.png" width="230"><br><sub>ej4_ios_19_ajustes-tema_guinda-oscuro</sub></td>
</tr>
</table>

### Ejercicio 5 — Kotlin Multiplatform para Android e iOS (gestor de archivos)

Carpeta: [`ej5-kmp/`](ej5-kmp/) · Informe completo (estructura, `expect`/`actual`,
librerías, compilación y pruebas): [`ej5-kmp/README.md`](ej5-kmp/README.md) · Tabla
comparativa Flutter vs KMP:
[`ej5-kmp/TABLA_COMPARATIVA_FLUTTER_KMP.md`](ej5-kmp/TABLA_COMPARATIVA_FLUTTER_KMP.md) ·
APK: [`binarios/ej5-kmp.apk`](binarios/ej5-kmp.apk)

La lógica (modelo, sistema de archivos, ordenamiento y preferencias) vive en el módulo
compartido `sharedLogic`; la interfaz es nativa en cada plataforma: Jetpack Compose en Android
y SwiftUI en iOS.

**Cómo compilar:** con JDK 21, dentro de `ej5-kmp/`: `./gradlew :androidApp:assembleDebug`
(en Windows, `gradlew.bat`). Para iOS: en una Mac con Xcode 15 o posterior, abrir
`iosApp/iosApp.xcodeproj` y ejecutar en un simulador de iPhone.

**Android** (emulador de Android Studio):

<table>
<tr>
<td align="center"><img src="fotos/ian/ej5_01_explorar_guinda-claro.png" width="230"><br><sub>ej5_01_explorar_guinda-claro</sub></td>
<td align="center"><img src="fotos/ian/ej5_02_explorar_guinda-oscuro.png" width="230"><br><sub>ej5_02_explorar_guinda-oscuro</sub></td>
<td align="center"><img src="fotos/ian/ej5_03_explorar_azul-claro.png" width="230"><br><sub>ej5_03_explorar_azul-claro</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/ian/ej5_04_explorar_azul-oscuro.png" width="230"><br><sub>ej5_04_explorar_azul-oscuro</sub></td>
<td align="center"><img src="fotos/ian/ej5_05_ruta-actual_guinda-claro.png" width="230"><br><sub>ej5_05_ruta-actual_guinda-claro</sub></td>
<td align="center"><img src="fotos/ian/ej5_07_ver-imagen_guinda-claro.png" width="230"><br><sub>ej5_07_ver-imagen_guinda-claro</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/ian/ej5_08_crear-carpeta_guinda-claro.png" width="230"><br><sub>ej5_08_crear-carpeta_guinda-claro</sub></td>
<td align="center"><img src="fotos/ian/ej5_09_copiar_guinda-claro.png" width="230"><br><sub>ej5_09_copiar_guinda-claro</sub></td>
<td align="center"><img src="fotos/ian/ej5_10_mover_guinda-claro.png" width="230"><br><sub>ej5_10_mover_guinda-claro</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/ian/ej5_11_renombrar_guinda-claro.png" width="230"><br><sub>ej5_11_renombrar_guinda-claro</sub></td>
<td align="center"><img src="fotos/ian/ej5_12_eliminar-confirmacion_guinda-claro.png" width="230"><br><sub>ej5_12_eliminar-confirmacion_guinda-claro</sub></td>
<td align="center"><img src="fotos/ian/ej5_13_busqueda_guinda-claro.png" width="230"><br><sub>ej5_13_busqueda_guinda-claro</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/ian/ej5_14_ordenamiento_guinda-claro.png" width="230"><br><sub>ej5_14_ordenamiento_guinda-claro</sub></td>
<td align="center"><img src="fotos/ian/ej5_15_recientes_guinda-claro.png" width="230"><br><sub>ej5_15_recientes_guinda-claro</sub></td>
<td align="center"><img src="fotos/ian/ej5_16_favoritos_guinda-claro.png" width="230"><br><sub>ej5_16_favoritos_guinda-claro</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/ian/ej5_17_importar_guinda-claro.png" width="230"><br><sub>ej5_17_importar_guinda-claro</sub></td>
<td align="center"><img src="fotos/ian/ej5_18_compartir_guinda-claro.png" width="230"><br><sub>ej5_18_compartir_guinda-claro</sub></td>
</tr>
</table>

**iOS** (simulador de iPhone 15 en la Mac virtual):

<table>
<tr>
<td align="center"><img src="fotos/ian/ios/ej5_ios_01_explorar_guinda-claro.png" width="230"><br><sub>ej5_ios_01_explorar_guinda-claro</sub></td>
<td align="center"><img src="fotos/ian/ios/ej5_ios_02_explorar_guinda-oscuro.png" width="230"><br><sub>ej5_ios_02_explorar_guinda-oscuro</sub></td>
<td align="center"><img src="fotos/ian/ios/ej5_ios_03_explorar_guinda-claro-codigo-apptheme.png" width="230"><br><sub>ej5_ios_03_explorar_guinda-claro-codigo-apptheme</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/ian/ios/ej5_ios_04_explorar_azul-claro.png" width="230"><br><sub>ej5_ios_04_explorar_azul-claro</sub></td>
<td align="center"><img src="fotos/ian/ios/ej5_ios_05_explorar_azul-oscuro.png" width="230"><br><sub>ej5_ios_05_explorar_azul-oscuro</sub></td>
<td align="center"><img src="fotos/ian/ios/ej5_ios_06_explorar_guinda-claro-tras-cambio-de-tema.png" width="230"><br><sub>ej5_ios_06_explorar_guinda-claro-tras-cambio-de-tema</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/ian/ios/ej5_ios_07_ruta-actual-documentos.png" width="230"><br><sub>ej5_ios_07_ruta-actual-documentos</sub></td>
<td align="center"><img src="fotos/ian/ios/ej5_ios_08_visor-texto.png" width="230"><br><sub>ej5_ios_08_visor-texto</sub></td>
<td align="center"><img src="fotos/ian/ios/ej5_ios_09_documentos-tras-visor.png" width="230"><br><sub>ej5_ios_09_documentos-tras-visor</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/ian/ios/ej5_ios_10_visor-imagen.png" width="230"><br><sub>ej5_ios_10_visor-imagen</sub></td>
<td align="center"><img src="fotos/ian/ios/ej5_ios_11_visor-imagen-codigo-error.png" width="230"><br><sub>ej5_ios_11_visor-imagen-codigo-error</sub></td>
<td align="center"><img src="fotos/ian/ios/ej5_ios_12_explorar-tras-imagen.png" width="230"><br><sub>ej5_ios_12_explorar-tras-imagen</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/ian/ios/ej5_ios_13_nueva-carpeta-dialogo.png" width="230"><br><sub>ej5_ios_13_nueva-carpeta-dialogo</sub></td>
<td align="center"><img src="fotos/ian/ios/ej5_ios_14_nueva-carpeta-nombre.png" width="230"><br><sub>ej5_ios_14_nueva-carpeta-nombre</sub></td>
<td align="center"><img src="fotos/ian/ios/ej5_ios_15_carpeta-creada.png" width="230"><br><sub>ej5_ios_15_carpeta-creada</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/ian/ios/ej5_ios_16_copiar-selector-inicio.png" width="230"><br><sub>ej5_ios_16_copiar-selector-inicio</sub></td>
<td align="center"><img src="fotos/ian/ios/ej5_ios_17_copiar-selector-clases.png" width="230"><br><sub>ej5_ios_17_copiar-selector-clases</sub></td>
<td align="center"><img src="fotos/ian/ios/ej5_ios_18_explorar-con-clases.png" width="230"><br><sub>ej5_ios_18_explorar-con-clases</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/ian/ios/ej5_ios_19_menu-contextual-archivo.png" width="230"><br><sub>ej5_ios_19_menu-contextual-archivo</sub></td>
<td align="center"><img src="fotos/ian/ios/ej5_ios_20_mover-selector-documentos.png" width="230"><br><sub>ej5_ios_20_mover-selector-documentos</sub></td>
<td align="center"><img src="fotos/ian/ios/ej5_ios_21_explorar-actualizado.png" width="230"><br><sub>ej5_ios_21_explorar-actualizado</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/ian/ios/ej5_ios_22_menu-contextual-lista.png" width="230"><br><sub>ej5_ios_22_menu-contextual-lista</sub></td>
<td align="center"><img src="fotos/ian/ios/ej5_ios_23_documentos-lista.png" width="230"><br><sub>ej5_ios_23_documentos-lista</sub></td>
<td align="center"><img src="fotos/ian/ios/ej5_ios_24_busqueda.png" width="230"><br><sub>ej5_ios_24_busqueda</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/ian/ios/ej5_ios_25_documentos-tras-busqueda.png" width="230"><br><sub>ej5_ios_25_documentos-tras-busqueda</sub></td>
<td align="center"><img src="fotos/ian/ios/ej5_ios_26_ordenamiento.png" width="230"><br><sub>ej5_ios_26_ordenamiento</sub></td>
<td align="center"><img src="fotos/ian/ios/ej5_ios_27_menu-contextual-carpeta.png" width="230"><br><sub>ej5_ios_27_menu-contextual-carpeta</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/ian/ios/ej5_ios_28_favoritos.png" width="230"><br><sub>ej5_ios_28_favoritos</sub></td>
<td align="center"><img src="fotos/ian/ios/ej5_ios_29_explorar-con-favorito.png" width="230"><br><sub>ej5_ios_29_explorar-con-favorito</sub></td>
<td align="center"><img src="fotos/ian/ios/ej5_ios_30_importar-selector-sistema.png" width="230"><br><sub>ej5_ios_30_importar-selector-sistema</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/ian/ios/ej5_ios_31_menu-contextual-compartir.png" width="230"><br><sub>ej5_ios_31_menu-contextual-compartir</sub></td>
<td align="center"><img src="fotos/ian/ios/ej5_ios_32_hoja-compartir.png" width="230"><br><sub>ej5_ios_32_hoja-compartir</sub></td>
</tr>
</table>

### Pruebas realizadas

| App | Cómo se probó | Resultado |
|---|---|---|
| Ej2 — Gestor de archivos (Swift) | 9 pruebas automáticas de interfaz (XCUITest) en el simulador de iPhone 15: navegación y visores; gestión de archivos; búsqueda, orden y vista; compartir; importar; favoritos, recientes y preferencias; vista horizontal; temas; app Archivos | Correcto |
| Ej3 — Cámara y micrófono (Swift) | 7 pruebas automáticas de interfaz (XCUITest) en el simulador de iPhone 15: cámara y filtros; grabadora; galería; exportar e importar; importar; nuevo álbum; temas | Correcto |
| Ej4 — Flutter | Pruebas manuales en un Samsung SM-S938B y en el simulador de iPhone 15 (detalle en [`ej4-flutter/README.md`](ej4-flutter/README.md)) | Correcto |
| Ej5 — KMP | Pruebas manuales en el emulador de Android y en el simulador de iPhone 15 (detalle en [`ej5-kmp/README.md`](ej5-kmp/README.md)) | Correcto |

### Bitácora de trabajo en equipo

Todas las sesiones fueron remotas, por Discord, con la pantalla de la PC de Miguel compartida.
**Responsable del equipo utilizado:** Miguel Ángel Rodríguez Candelario (PC con macOS en
Docker, la única del equipo con la Mac virtual).

| Fecha | Horario | Presentes | Actividades |
|---|---|---|---|
| 26-sep-2026 | 20:35 – 21:52 | Miguel, Vic e Ian | Revisión de la instalación de macOS y de Xcode, y demostración del Ej2 y del Ej3 en el simulador con Vic e Ian viendo la transmisión desde sus PCs |
<details>
<summary>Evidencias de la sesión del 26-sep-2026</summary>

<table>
<tr>
<td align="center"><img src="fotos/sesiones/llamada2_2026-09-26/1_instalacion_mac/203519_instalando_macos.png" width="230"><br><sub>203519_instalando_macos</sub></td>
<td align="center"><img src="fotos/sesiones/llamada2_2026-09-26/1_instalacion_mac/203527_install_macos_ventura.png" width="230"><br><sub>203527_install_macos_ventura</sub></td>
<td align="center"><img src="fotos/sesiones/llamada2_2026-09-26/1_instalacion_mac/203531_vista_vic_instalando_macos.png" width="230"><br><sub>203531_vista_vic_instalando_macos</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/sesiones/llamada2_2026-09-26/1_instalacion_mac/203537_crear_cuenta.png" width="230"><br><sub>203537_crear_cuenta</sub></td>
<td align="center"><img src="fotos/sesiones/llamada2_2026-09-26/1_instalacion_mac/203558_primer_escritorio.png" width="230"><br><sub>203558_primer_escritorio</sub></td>
<td align="center"><img src="fotos/sesiones/llamada2_2026-09-26/1_instalacion_mac/2036_vista_vic_docker_desktop.jpeg" width="230"><br><sub>2036_vista_vic_docker_desktop</sub></td>
</tr>
</table>
<table>
<tr>
<td align="center"><img src="fotos/sesiones/llamada2_2026-09-26/2_ej2_gestor_archivos/203727_xcode_servicio_archivos_y_documentos.png" width="230"><br><sub>203727_xcode_servicio_archivos_y_documentos</sub></td>
<td align="center"><img src="fotos/sesiones/llamada2_2026-09-26/2_ej2_gestor_archivos/203737_guia_de_uso.png" width="230"><br><sub>203737_guia_de_uso</sub></td>
<td align="center"><img src="fotos/sesiones/llamada2_2026-09-26/2_ej2_gestor_archivos/203751_pestanas_modo_oscuro.png" width="230"><br><sub>203751_pestanas_modo_oscuro</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/sesiones/llamada2_2026-09-26/2_ej2_gestor_archivos/2040_vista_ian_app_corriendo_inicio.jpeg" width="230"><br><sub>2040_vista_ian_app_corriendo_inicio</sub></td>
<td align="center"><img src="fotos/sesiones/llamada2_2026-09-26/2_ej2_gestor_archivos/204036_app_corriendo_inicio.png" width="230"><br><sub>204036_app_corriendo_inicio</sub></td>
</tr>
</table>
<table>
<tr>
<td align="center"><img src="fotos/sesiones/llamada2_2026-09-26/3_ej3_camara_microfono/2038_vista_ian_grabadora_permiso_microfono.jpeg" width="230"><br><sub>2038_vista_ian_grabadora_permiso_microfono</sub></td>
<td align="center"><img src="fotos/sesiones/llamada2_2026-09-26/3_ej3_camara_microfono/203824_info_plist_permiso_camara.png" width="230"><br><sub>203824_info_plist_permiso_camara</sub></td>
<td align="center"><img src="fotos/sesiones/llamada2_2026-09-26/3_ej3_camara_microfono/203831_cuenta_regresiva.png" width="230"><br><sub>203831_cuenta_regresiva</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/sesiones/llamada2_2026-09-26/3_ej3_camara_microfono/203841_grabadora_permiso_microfono.png" width="230"><br><sub>203841_grabadora_permiso_microfono</sub></td>
<td align="center"><img src="fotos/sesiones/llamada2_2026-09-26/3_ej3_camara_microfono/203853_hoja_compartir.png" width="230"><br><sub>203853_hoja_compartir</sub></td>
</tr>
</table>
<table>
<tr>
<td align="center"><img src="fotos/sesiones/llamada2_2026-09-26/4_arranque_mac_xcode/2039_vista_ian_arranque_kernel.jpeg" width="230"><br><sub>2039_vista_ian_arranque_kernel</sub></td>
<td align="center"><img src="fotos/sesiones/llamada2_2026-09-26/4_arranque_mac_xcode/203934_qemu_menu_arranque.png" width="230"><br><sub>203934_qemu_menu_arranque</sub></td>
<td align="center"><img src="fotos/sesiones/llamada2_2026-09-26/4_arranque_mac_xcode/203943_arranque_kernel.png" width="230"><br><sub>203943_arranque_kernel</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/sesiones/llamada2_2026-09-26/4_arranque_mac_xcode/203949_inicio_de_sesion.png" width="230"><br><sub>203949_inicio_de_sesion</sub></td>
<td align="center"><img src="fotos/sesiones/llamada2_2026-09-26/4_arranque_mac_xcode/203955_escritorio.png" width="230"><br><sub>203955_escritorio</sub></td>
<td align="center"><img src="fotos/sesiones/llamada2_2026-09-26/4_arranque_mac_xcode/204001_spotlight_xcode.png" width="230"><br><sub>204001_spotlight_xcode</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/sesiones/llamada2_2026-09-26/4_arranque_mac_xcode/204007_xcode_novedades.png" width="230"><br><sub>204007_xcode_novedades</sub></td>
<td align="center"><img src="fotos/sesiones/llamada2_2026-09-26/4_arranque_mac_xcode/204013_xcode_bienvenida.png" width="230"><br><sub>204013_xcode_bienvenida</sub></td>
<td align="center"><img src="fotos/sesiones/llamada2_2026-09-26/4_arranque_mac_xcode/204020_xcode_proyecto_indexando.png" width="230"><br><sub>204020_xcode_proyecto_indexando</sub></td>
</tr>
<tr>
<td align="center"><img src="fotos/sesiones/llamada2_2026-09-26/4_arranque_mac_xcode/204028_simulador_arrancando.png" width="230"><br><sub>204028_simulador_arrancando</sub></td>
</tr>
</table>

</details>

El 28-sep-2026 se compilaron en la Mac virtual las versiones de iOS del Ejercicio 4 y del
Ejercicio 5 y se recorrió cada app en el simulador de iPhone; las evidencias son las capturas
de iOS de esos dos ejercicios.

## Conclusiones

Lo que más trabajo nos costó no fue programar las apps sino tener dónde compilarlas. Ninguno
de los tres tiene Mac, así que todo lo de iOS dependió de una Mac virtual sin GPU, sin audio y
con un procesador Intel, y cada una de esas carencias se tradujo en un problema distinto: la
versión actual de Flutter no arrancaba en macOS 13, la versión anterior se veía en negro hasta
desactivar Impeller, y la plantilla oficial de Kotlin Multiplatform ni siquiera compilaba para
el simulador. Aprendimos a leer los errores del entorno y no solo los del código, y a elegir
versiones por compatibilidad y no por ser las más nuevas. La memoria fue otro tema: con los
8 GB con los que arrancamos, la Mac iba lentísima y se trababa en cuanto se abrían Xcode y el
simulador juntos, y tuvimos que asignarle 12 GB para poder trabajar con ella; eso solo fue
posible porque la PC elegida tiene 32 GB. También nos quedó claro lo cerrado
que es el ecosistema de Apple: sin macOS no hay Xcode, y sin Xcode no se puede compilar ni
una línea para iPhone, aunque el código se escriba en otra computadora.

Hacer la misma idea con tres enfoques dejó muy clara la diferencia entre ellos. En Swift se
tiene acceso directo a todo lo de iOS (Quick Look, la fototeca, Core Data) y la app se siente
como del sistema, pero ese código no sirve para Android. Flutter permitió tener las dos
plataformas con un solo código y casi la misma interfaz, a cambio de depender de que cada
plugin sea compatible con la versión de Flutter y de Xcode que se tiene. Kotlin Multiplatform
quedó en medio: se comparte la lógica y cada plataforma conserva su interfaz nativa, lo que da
más trabajo en la parte visual pero respeta las convenciones de cada sistema.

También fue la primera práctica en la que coordinamos a tres personas con una sola máquina
capaz de compilar para iOS. Tuvimos que organizarnos en sesiones para compilar y probar las
apps de Vic y de Ian en la Mac con cada uno presente, y corregir en el momento lo que fallaba.
Nos quedamos con que en móvil, antes de escribir la primera pantalla, hay que resolver el
entorno, las versiones y los permisos, porque ahí es donde se va la mayor parte del tiempo.

## Bibliografía

### Ejercicios 2 y 3 (Swift / SwiftUI)

Apple Inc. (s.f.). *AVFoundation*. Apple Developer Documentation. Recuperado el 28 de
septiembre de 2026, de https://developer.apple.com/documentation/avfoundation

Apple Inc. (s.f.). *Core Data*. Apple Developer Documentation. Recuperado el 28 de
septiembre de 2026, de https://developer.apple.com/documentation/coredata

Apple Inc. (s.f.). *FileManager*. Apple Developer Documentation. Recuperado el 28 de
septiembre de 2026, de https://developer.apple.com/documentation/foundation/filemanager

Apple Inc. (s.f.). *NavigationStack*. Apple Developer Documentation. Recuperado el 28 de
septiembre de 2026, de https://developer.apple.com/documentation/swiftui/navigationstack

Apple Inc. (s.f.). *PHPickerViewController*. Apple Developer Documentation. Recuperado el 28
de septiembre de 2026, de
https://developer.apple.com/documentation/photokit/phpickerviewcontroller

Apple Inc. (s.f.). *QLPreviewController*. Apple Developer Documentation. Recuperado el 28 de
septiembre de 2026, de https://developer.apple.com/documentation/quicklook/qlpreviewcontroller

Apple Inc. (s.f.). *UIActivityViewController*. Apple Developer Documentation. Recuperado el
28 de septiembre de 2026, de
https://developer.apple.com/documentation/uikit/uiactivityviewcontroller

Apple Inc. (s.f.). *UIDocumentPickerViewController*. Apple Developer Documentation.
Recuperado el 28 de septiembre de 2026, de
https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller

Apple Inc. (s.f.). *Uniform Type Identifiers*. Apple Developer Documentation. Recuperado el
28 de septiembre de 2026, de https://developer.apple.com/documentation/uniformtypeidentifiers

Apple Inc. (s.f.). *UserDefaults*. Apple Developer Documentation. Recuperado el 28 de
septiembre de 2026, de https://developer.apple.com/documentation/foundation/userdefaults

### Ejercicio 4 (Flutter)

Flutter team. (s.f.). *camera* [Paquete de Dart]. pub.dev. Recuperado el 28 de septiembre de
2026, de https://pub.dev/packages/camera

Flutter team. (s.f.). *image_picker* [Paquete de Dart]. pub.dev. Recuperado el 28 de
septiembre de 2026, de https://pub.dev/packages/image_picker

Flutter team. (s.f.). *path_provider* [Paquete de Dart]. pub.dev. Recuperado el 28 de
septiembre de 2026, de https://pub.dev/packages/path_provider

Flutter team. (s.f.). *sqflite* [Paquete de Dart]. pub.dev. Recuperado el 28 de septiembre de
2026, de https://pub.dev/packages/sqflite

Google. (s.f.). *Dart programming language*. Dart. Recuperado el 28 de septiembre de 2026,
de https://dart.dev

Google. (s.f.). *Flutter documentation*. Flutter. Recuperado el 28 de septiembre de 2026, de
https://docs.flutter.dev

pub.dev. (s.f.). *just_audio* [Paquete de Dart]. Recuperado el 28 de septiembre de 2026, de
https://pub.dev/packages/just_audio

pub.dev. (s.f.). *provider* [Paquete de Dart]. Recuperado el 28 de septiembre de 2026, de
https://pub.dev/packages/provider

pub.dev. (s.f.). *record* [Paquete de Dart]. Recuperado el 28 de septiembre de 2026, de
https://pub.dev/packages/record

pub.dev. (s.f.). *share_plus* [Paquete de Dart]. Recuperado el 28 de septiembre de 2026, de
https://pub.dev/packages/share_plus

### Ejercicio 5 (Kotlin Multiplatform)

Apple Inc. (s.f.). *SwiftUI*. Apple Developer Documentation. Recuperado el 28 de septiembre
de 2026, de https://developer.apple.com/documentation/swiftui

Google. (s.f.). *Jetpack Compose*. Android Developers. Recuperado el 28 de septiembre de
2026, de https://developer.android.com/jetpack/compose

Google. (s.f.). *Material Design 3*. Material Design. Recuperado el 28 de septiembre de
2026, de https://m3.material.io/

Google. (s.f.). *Open files using storage access framework*. Android Developers. Recuperado
el 28 de septiembre de 2026, de
https://developer.android.com/guide/topics/providers/document-provider

Google. (s.f.). *Preferences DataStore*. Android Developers. Recuperado el 28 de septiembre
de 2026, de https://developer.android.com/topic/libraries/architecture/datastore

JetBrains. (s.f.). *Expect and actual declarations*. Kotlin Help. Recuperado el 28 de
septiembre de 2026, de https://kotlinlang.org/docs/multiplatform-expect-actual.html

JetBrains. (s.f.). *Interoperability with Swift/Objective-C*. Kotlin Help. Recuperado el 28
de septiembre de 2026, de https://kotlinlang.org/docs/native-objc-interop.html

JetBrains. (s.f.). *Kotlin Multiplatform*. Kotlin Help. Recuperado el 28 de septiembre de
2026, de https://kotlinlang.org/docs/multiplatform.html
