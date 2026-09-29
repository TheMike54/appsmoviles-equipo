package com.example.ej5_kmp

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.ej5_kmp.filesystem.FileEntry
import com.example.ej5_kmp.filesystem.PlatformFileSystem
import com.example.ej5_kmp.filesystem.SampleContent
import com.example.ej5_kmp.filesystem.SortOrder
import com.example.ej5_kmp.filesystem.isTextFile
import com.example.ej5_kmp.filesystem.sortedFor
import com.example.ej5_kmp.settings.AppSettings
import com.example.ej5_kmp.theme.AppTheme
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/** Las tres pestañas de la app. */
enum class Section(val label: String) {
    EXPLORAR("Explorar"),
    RECIENTES("Recientes"),
    FAVORITOS("Favoritos")
}

data class FileBrowserState(
    val section: Section = Section.EXPLORAR,
    val currentPath: String = "",
    val entries: List<FileEntry> = emptyList(),
    val isLoading: Boolean = true,
    val searchQuery: String = "",
    val recents: List<FileEntry> = emptyList(),
    val favorites: List<FileEntry> = emptyList(),
    val favoritePaths: Set<String> = emptySet(),
    val viewingEntry: FileEntry? = null,
    val viewingTextContent: String? = null,
    val isLoadingViewer: Boolean = false,
    val message: String? = null
) {
    /** Entradas de la carpeta actual ya filtradas por la búsqueda (por nombre). */
    val visibleEntries: List<FileEntry>
        get() = if (searchQuery.isBlank()) entries
        else entries.filter { it.name.contains(searchQuery.trim(), ignoreCase = true) }
}

data class SortSettings(
    val order: SortOrder = SortOrder.NOMBRE,
    val ascending: Boolean = true
)

/**
 * Estado de la app: explorar carpetas, ver un archivo, búsqueda, ordenamiento, favoritos,
 * recientes, tema y última carpeta. Lo que debe recordarse entre sesiones (tema, orden,
 * última carpeta, favoritos y recientes) se guarda con DataStore. Usa Flow (StateFlow) y
 * coroutines, como pide el checklist.
 */
class FileBrowserViewModel : ViewModel() {

    val rootPath: String = PlatformFileSystem.defaultRootPath()

    private val _state = MutableStateFlow(FileBrowserState(currentPath = rootPath))
    val state: StateFlow<FileBrowserState> = _state.asStateFlow()

    private val _theme = MutableStateFlow(AppTheme.GUINDA)
    val theme: StateFlow<AppTheme> = _theme.asStateFlow()

    private val _sort = MutableStateFlow(SortSettings())
    val sort: StateFlow<SortSettings> = _sort.asStateFlow()

    // Rutas guardadas (las entradas completas se resuelven contra el disco al mostrarlas).
    private var favoritePaths: List<String> = emptyList()
    private var recentPaths: List<String> = emptyList()

    init {
        viewModelScope.launch {
            // Carga lo que el usuario dejó la última vez (si hay algo guardado).
            val savedTheme = AppSettings.getString(THEME_KEY)
            AppTheme.entries.firstOrNull { it.name == savedTheme }?.let { _theme.value = it }

            val savedOrder = AppSettings.getString(SORT_ORDER_KEY)
            val savedAscending = AppSettings.getString(SORT_ASCENDING_KEY)
            _sort.value = SortSettings(
                order = SortOrder.entries.firstOrNull { it.name == savedOrder } ?: SortOrder.NOMBRE,
                ascending = savedAscending != "false"
            )

            favoritePaths = AppSettings.getList(FAVORITES_KEY)
            recentPaths = AppSettings.getList(RECENTS_KEY)

            // Primera vez: crea archivos de ejemplo para que el explorador no arranque vacío.
            withContext(Dispatchers.Default) { SampleContent.seedIfNeeded() }

            // Última carpeta visitada: solo si sigue existiendo y está dentro de la raíz.
            val savedPath = AppSettings.getString(LAST_PATH_KEY)
            val startPath = if (
                savedPath != null &&
                savedPath.startsWith("$rootPath/") &&
                isDirectory(savedPath)
            ) savedPath else rootPath

            load(startPath, keepSearch = false)
            refreshCollections()
        }
    }

    private companion object {
        const val THEME_KEY = "theme"
        const val SORT_ORDER_KEY = "sortOrder"
        const val SORT_ASCENDING_KEY = "sortAscending"
        const val LAST_PATH_KEY = "lastPath"
        const val FAVORITES_KEY = "favorites"
        const val RECENTS_KEY = "recents"
        const val MAX_RECENTS = 20
    }

    // ---------------------------------------------------------------- tema y orden

    fun setTheme(newTheme: AppTheme) {
        _theme.value = newTheme
        viewModelScope.launch { AppSettings.putString(THEME_KEY, newTheme.name) }
    }

    fun setSortOrder(order: SortOrder) {
        _sort.value = _sort.value.copy(order = order)
        resort()
        viewModelScope.launch { AppSettings.putString(SORT_ORDER_KEY, order.name) }
    }

    fun setSortAscending(ascending: Boolean) {
        _sort.value = _sort.value.copy(ascending = ascending)
        resort()
        viewModelScope.launch { AppSettings.putString(SORT_ASCENDING_KEY, ascending.toString()) }
    }

    private fun resort() {
        val sort = _sort.value
        _state.update { it.copy(entries = it.entries.sortedFor(sort.order, sort.ascending)) }
    }

    // ---------------------------------------------------------------- navegación

    fun selectSection(section: Section) {
        _state.update {
            it.copy(section = section, viewingEntry = null, viewingTextContent = null)
        }
    }

    /** Entra a una carpeta (desde el explorador, recientes o favoritos). */
    fun openDirectory(path: String) {
        _state.update {
            it.copy(section = Section.EXPLORAR, viewingEntry = null, viewingTextContent = null)
        }
        load(path, keepSearch = false)
    }

    /** @return true si sí pudo subir de nivel; false si ya estaba en la raíz. */
    fun goUp(): Boolean {
        val current = _state.value.currentPath
        if (current == rootPath) return false
        val parent = current.substringBeforeLast('/', rootPath)
        openDirectory(parent.ifEmpty { rootPath })
        return true
    }

    fun setSearchQuery(query: String) {
        _state.update { it.copy(searchQuery = query) }
    }

    /** Vuelve a leer la carpeta actual (también lo usa el "deslizar para actualizar"). */
    fun refresh() {
        load(_state.value.currentPath, keepSearch = true)
    }

    private fun load(path: String, keepSearch: Boolean) {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true) }
            val sort = _sort.value
            val entries = withContext(Dispatchers.Default) {
                PlatformFileSystem.listEntries(path).sortedFor(sort.order, sort.ascending)
            }
            _state.update {
                it.copy(
                    currentPath = path,
                    entries = entries,
                    isLoading = false,
                    searchQuery = if (keepSearch) it.searchQuery else ""
                )
            }
            AppSettings.putString(LAST_PATH_KEY, path)
        }
    }

    /** Carpeta actual, para que el selector de archivos sepa dónde copiar lo importado. */
    fun currentDirectory(): String = _state.value.currentPath

    /** Subcarpetas de [path], para el selector de destino de copiar/mover. */
    suspend fun listFolders(path: String): List<FileEntry> = withContext(Dispatchers.Default) {
        PlatformFileSystem.listEntries(path)
            .filter { it.isDirectory }
            .sortedBy { it.name.lowercase() }
    }

    // ---------------------------------------------------------------- gestión de archivos

    fun createFolder(name: String) {
        val parent = _state.value.currentPath
        if (!isValidName(name)) {
            showMessage("Nombre no válido")
            return
        }
        viewModelScope.launch {
            val ok = withContext(Dispatchers.Default) {
                PlatformFileSystem.createDirectory(parent, name)
            }
            if (ok) showMessage("Carpeta \"$name\" creada")
            else showMessage("No se pudo crear \"$name\" (¿ya existe?)")
            load(parent, keepSearch = true)
        }
    }

    fun renameEntry(entry: FileEntry, newName: String) {
        if (!isValidName(newName)) {
            showMessage("Nombre no válido")
            return
        }
        val parent = entry.path.substringBeforeLast('/')
        viewModelScope.launch {
            val error = withContext(Dispatchers.Default) {
                val siblings = PlatformFileSystem.listEntries(parent)
                when {
                    newName == entry.name -> null
                    siblings.any { it.name == newName } -> "Ya existe \"$newName\" en esta carpeta"
                    !PlatformFileSystem.rename(entry.path, newName) -> "No se pudo renombrar"
                    else -> null
                }
            }
            if (error != null) {
                showMessage(error)
            } else if (newName != entry.name) {
                remapPaths(entry.path, "$parent/$newName")
            }
            reloadAll()
        }
    }

    fun deleteEntry(entry: FileEntry) {
        viewModelScope.launch {
            val ok = withContext(Dispatchers.Default) { PlatformFileSystem.delete(entry.path) }
            if (ok) {
                remapPaths(entry.path, null)
                showMessage("\"${entry.name}\" eliminado")
            } else {
                showMessage("No se pudo eliminar \"${entry.name}\"")
            }
            reloadAll()
        }
    }

    fun copyEntry(entry: FileEntry, destinationDir: String) = transfer(entry, destinationDir, move = false)

    fun moveEntry(entry: FileEntry, destinationDir: String) = transfer(entry, destinationDir, move = true)

    private fun transfer(entry: FileEntry, destinationDir: String, move: Boolean) {
        viewModelScope.launch {
            val verb = if (move) "mover" else "copiar"
            val error = withContext(Dispatchers.Default) {
                val insideItself = entry.isDirectory &&
                    (destinationDir == entry.path || destinationDir.startsWith(entry.path + "/"))
                val alreadyThere = PlatformFileSystem.listEntries(destinationDir).any { it.name == entry.name }
                when {
                    insideItself -> "No se puede $verb una carpeta dentro de sí misma"
                    alreadyThere -> "Ya existe \"${entry.name}\" en la carpeta de destino"
                    move && !PlatformFileSystem.move(entry.path, destinationDir) -> "No se pudo mover"
                    !move && !PlatformFileSystem.copy(entry.path, destinationDir) -> "No se pudo copiar"
                    else -> null
                }
            }
            if (error != null) {
                showMessage(error)
            } else {
                if (move) remapPaths(entry.path, "$destinationDir/${entry.name}")
                showMessage(if (move) "\"${entry.name}\" movido" else "\"${entry.name}\" copiado")
            }
            reloadAll()
        }
    }

    /** Lo llama la UI cuando el selector del sistema terminó de copiar un archivo importado. */
    fun onFileImported(importedName: String?) {
        if (importedName != null) showMessage("\"$importedName\" importado")
        load(_state.value.currentPath, keepSearch = true)
    }

    // ---------------------------------------------------------------- visor

    /** Abre un archivo para verlo. Las imágenes se pintan directo desde su ruta (en la UI);
     *  los de texto se leen aquí de forma asíncrona con PlatformFileSystem. También lo
     *  agrega a Recientes. */
    fun openFile(entry: FileEntry) {
        registerRecent(entry)
        if (entry.isTextFile) {
            viewModelScope.launch {
                _state.update { it.copy(viewingEntry = entry, viewingTextContent = null, isLoadingViewer = true) }
                val content = withContext(Dispatchers.Default) {
                    runCatching { PlatformFileSystem.readTextFile(entry.path) }
                        .getOrDefault("(no se pudo leer el archivo)")
                }
                _state.update { it.copy(viewingTextContent = content, isLoadingViewer = false) }
            }
        } else {
            _state.update { it.copy(viewingEntry = entry, viewingTextContent = null) }
        }
    }

    fun closeViewer() {
        _state.update { it.copy(viewingEntry = null, viewingTextContent = null) }
    }

    // ---------------------------------------------------------------- favoritos y recientes

    fun toggleFavorite(entry: FileEntry) {
        viewModelScope.launch {
            favoritePaths = if (entry.path in favoritePaths) favoritePaths - entry.path
            else listOf(entry.path) + favoritePaths
            AppSettings.putList(FAVORITES_KEY, favoritePaths)
            refreshCollections()
        }
    }

    fun clearRecents() {
        viewModelScope.launch {
            recentPaths = emptyList()
            AppSettings.putList(RECENTS_KEY, recentPaths)
            refreshCollections()
        }
    }

    private fun registerRecent(entry: FileEntry) {
        viewModelScope.launch {
            recentPaths = (listOf(entry.path) + recentPaths.filter { it != entry.path }).take(MAX_RECENTS)
            AppSettings.putList(RECENTS_KEY, recentPaths)
            refreshCollections()
        }
    }

    /** Vuelve a construir las listas de Recientes y Favoritos; descarta lo que ya no existe. */
    private suspend fun refreshCollections() {
        val (recents, favorites) = withContext(Dispatchers.Default) {
            recentPaths.mapNotNull { entryFor(it) } to favoritePaths.mapNotNull { entryFor(it) }
        }
        recentPaths = recents.map { it.path }
        favoritePaths = favorites.map { it.path }
        _state.update {
            it.copy(
                recents = recents,
                favorites = favorites,
                favoritePaths = favoritePaths.toSet()
            )
        }
    }

    /** Cuando un archivo cambia de ruta (renombrar/mover) o se borra ([newPath] = null). */
    private suspend fun remapPaths(oldPath: String, newPath: String?) {
        fun map(path: String): String? = when {
            path == oldPath -> newPath
            path.startsWith("$oldPath/") -> newPath?.let { it + path.removePrefix(oldPath) }
            else -> path
        }
        favoritePaths = favoritePaths.mapNotNull { map(it) }
        recentPaths = recentPaths.mapNotNull { map(it) }
        AppSettings.putList(FAVORITES_KEY, favoritePaths)
        AppSettings.putList(RECENTS_KEY, recentPaths)
    }

    /** Recarga la carpeta actual y las listas después de una operación. */
    private suspend fun reloadAll() {
        load(_state.value.currentPath, keepSearch = true)
        refreshCollections()
    }

    // ---------------------------------------------------------------- utilidades

    fun clearMessage() {
        _state.update { it.copy(message = null) }
    }

    private fun showMessage(text: String) {
        _state.update { it.copy(message = text) }
    }

    private fun isValidName(name: String): Boolean =
        name.isNotBlank() && !name.contains('/') && name != "." && name != ".."

    /** Busca la entrada de [path] listando su carpeta padre (null si ya no existe). */
    private fun entryFor(path: String): FileEntry? {
        val parent = path.substringBeforeLast('/', "")
        if (parent.isEmpty()) return null
        return PlatformFileSystem.listEntries(parent).firstOrNull { it.path == path }
    }

    private suspend fun isDirectory(path: String): Boolean =
        withContext(Dispatchers.Default) { entryFor(path)?.isDirectory == true }
}
