package com.example.ej5_kmp.filesystem

import com.example.ej5_kmp.settings.AppSettings

/**
 * Archivos de ejemplo para la primera vez que se abre la app (Android e iOS por igual),
 * de modo que el explorador no arranque vacío y se puedan probar la búsqueda, el orden,
 * el visor de texto, copiar y mover. Se crean una sola vez: si el usuario los borra,
 * no vuelven a aparecer.
 */
object SampleContent {

    private const val SEEDED_KEY = "sampleContentCreated"

    suspend fun seedIfNeeded() {
        if (AppSettings.getString(SEEDED_KEY) == "true") return

        val root = PlatformFileSystem.defaultRootPath()
        // Si ya hay contenido (p. ej. importado antes), no se agrega nada.
        if (PlatformFileSystem.listEntries(root).isEmpty()) {
            PlatformFileSystem.createDirectory(root, "Documentos")
            PlatformFileSystem.createDirectory(root, "Proyectos")
            PlatformFileSystem.createDirectory(root, "Imágenes")

            PlatformFileSystem.writeTextFile(
                "$root/bienvenida.txt",
                "Bienvenido al gestor de archivos.\n\n" +
                    "Explora las carpetas, busca por nombre, cambia el orden desde el menú, " +
                    "marca favoritos y cambia entre los temas Guinda y Azul."
            )
            PlatformFileSystem.writeTextFile(
                "$root/Documentos/notas.txt",
                "Notas de la práctica 3.\n- Kotlin Multiplatform\n- Lógica compartida en commonMain\n- Interfaz nativa en cada plataforma\n"
            )
            PlatformFileSystem.writeTextFile(
                "$root/Documentos/lista.md",
                "# Pendientes\n\n- [x] Explorar carpetas\n- [x] Crear, copiar y mover\n- [ ] Compartir un archivo\n"
            )
            PlatformFileSystem.writeTextFile(
                "$root/Proyectos/config.json",
                "{\n  \"nombre\": \"ej5-kmp\",\n  \"plataformas\": [\"android\", \"ios\"],\n  \"sinInternet\": true\n}\n"
            )
            PlatformFileSystem.writeTextFile(
                "$root/Proyectos/Main.kt",
                "fun main() {\n    println(\"Hola desde Kotlin Multiplatform\")\n}\n"
            )
        }
        AppSettings.putString(SEEDED_KEY, "true")
    }
}
