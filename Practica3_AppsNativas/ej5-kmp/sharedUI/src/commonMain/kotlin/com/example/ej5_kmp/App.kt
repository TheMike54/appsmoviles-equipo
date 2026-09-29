package com.example.ej5_kmp

import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.ej5_kmp.filesystem.FileEntry
import com.example.ej5_kmp.filesystem.SortOrder
import com.example.ej5_kmp.filesystem.isImage
import com.example.ej5_kmp.filesystem.isTextFile
import com.example.ej5_kmp.theme.AppTheme
import com.example.ej5_kmp.theme.colorSchemeFor

// NOTA: no usamos androidx.compose.material.icons (Icons.Filled...) porque ni la versión
// "core" ni la "extended" de esa librería tienen todavía una versión publicada compatible
// con este Compose Multiplatform (1.12.1; la más reciente publicada es la 1.7.8). Por eso
// los íconos de esta pantalla son texto/emoji simple, sin depender de esa librería.

/** Copiar o mover una entrada: espera a que el usuario elija la carpeta de destino. */
private data class TransferRequest(val entry: FileEntry, val move: Boolean)

@Composable
fun App() {
    val viewModel: FileBrowserViewModel = viewModel()
    val selectedTheme by viewModel.theme.collectAsState()
    val sort by viewModel.sort.collectAsState()
    val colorScheme = colorSchemeFor(selectedTheme, isSystemInDarkTheme())

    MaterialTheme(colorScheme = colorScheme) {
        val state by viewModel.state.collectAsState()
        val viewing = state.viewingEntry
        val atRoot = state.currentPath == viewModel.rootPath

        var showCreateFolderDialog by remember { mutableStateOf(false) }
        var entryPendingRename by remember { mutableStateOf<FileEntry?>(null) }
        var entryPendingDelete by remember { mutableStateOf<FileEntry?>(null) }
        var transferRequest by remember { mutableStateOf<TransferRequest?>(null) }
        var menuExpanded by remember { mutableStateOf(false) }
        var fabMenuExpanded by remember { mutableStateOf(false) }

        val snackbarHostState = remember { SnackbarHostState() }
        LaunchedEffect(state.message) {
            state.message?.let {
                snackbarHostState.showSnackbar(it)
                viewModel.clearMessage()
            }
        }

        // expect/actual: selector de archivos (importar), compartir y botón atrás del sistema.
        val launchImport = rememberFileImporter(
            destinationDir = { viewModel.currentDirectory() },
            onResult = { viewModel.onFileImported(it) }
        )
        val shareFile = rememberFileSharer()

        PlatformBackHandler(
            enabled = viewing != null || state.section != Section.EXPLORAR || !atRoot,
            onBack = {
                when {
                    viewing != null -> viewModel.closeViewer()
                    state.section != Section.EXPLORAR -> viewModel.selectSection(Section.EXPLORAR)
                    else -> viewModel.goUp()
                }
            }
        )

        val onOpen: (FileEntry) -> Unit = { entry ->
            if (entry.isDirectory) viewModel.openDirectory(entry.path) else viewModel.openFile(entry)
        }

        val title = when {
            viewing != null -> viewing.name
            state.section == Section.RECIENTES -> "Recientes"
            state.section == Section.FAVORITOS -> "Favoritos"
            atRoot -> "Gestor de archivos"
            else -> state.currentPath.substringAfterLast('/')
        }

        Scaffold(
            snackbarHost = { SnackbarHost(snackbarHostState) },
            topBar = {
                TopAppBar(
                    title = { Text(title) },
                    navigationIcon = {
                        val showBack = viewing != null ||
                            (state.section == Section.EXPLORAR && !atRoot)
                        if (showBack) {
                            IconButton(onClick = {
                                if (viewing != null) viewModel.closeViewer() else viewModel.goUp()
                            }) {
                                Text("←", style = MaterialTheme.typography.titleLarge)
                            }
                        }
                    },
                    actions = {
                        Box {
                            IconButton(onClick = { menuExpanded = true }) {
                                Text("⋮", style = MaterialTheme.typography.titleLarge)
                            }
                            DropdownMenu(
                                expanded = menuExpanded,
                                onDismissRequest = { menuExpanded = false }
                            ) {
                                if (viewing != null) {
                                    DropdownMenuItem(
                                        text = {
                                            Text(
                                                if (viewing.path in state.favoritePaths) "Quitar de favoritos"
                                                else "Agregar a favoritos"
                                            )
                                        },
                                        onClick = { menuExpanded = false; viewModel.toggleFavorite(viewing) }
                                    )
                                    DropdownMenuItem(
                                        text = { Text("Compartir") },
                                        onClick = { menuExpanded = false; shareFile(viewing.path) }
                                    )
                                }
                                if (viewing == null && state.section == Section.EXPLORAR) {
                                    SortOrder.entries.forEach { order ->
                                        DropdownMenuItem(
                                            text = {
                                                Text(
                                                    (if (sort.order == order) "✓ " else "    ") +
                                                        "Ordenar por ${order.label.lowercase()}"
                                                )
                                            },
                                            onClick = { menuExpanded = false; viewModel.setSortOrder(order) }
                                        )
                                    }
                                    DropdownMenuItem(
                                        text = {
                                            Text(if (sort.ascending) "↑ Ascendente (cambiar)" else "↓ Descendente (cambiar)")
                                        },
                                        onClick = { menuExpanded = false; viewModel.setSortAscending(!sort.ascending) }
                                    )
                                }
                                if (viewing == null && state.section == Section.RECIENTES && state.recents.isNotEmpty()) {
                                    DropdownMenuItem(
                                        text = { Text("Limpiar recientes") },
                                        onClick = { menuExpanded = false; viewModel.clearRecents() }
                                    )
                                }
                                DropdownMenuItem(
                                    text = {
                                        val other = if (selectedTheme == AppTheme.GUINDA) AppTheme.AZUL else AppTheme.GUINDA
                                        Text("🎨 Cambiar a tema ${other.label}")
                                    },
                                    onClick = {
                                        menuExpanded = false
                                        viewModel.setTheme(
                                            if (selectedTheme == AppTheme.GUINDA) AppTheme.AZUL else AppTheme.GUINDA
                                        )
                                    }
                                )
                            }
                        }
                    }
                )
            },
            bottomBar = {
                if (viewing == null) {
                    NavigationBar {
                        Section.entries.forEach { section ->
                            NavigationBarItem(
                                selected = state.section == section,
                                onClick = { viewModel.selectSection(section) },
                                icon = {
                                    Text(
                                        when (section) {
                                            Section.EXPLORAR -> "📁"
                                            Section.RECIENTES -> "🕘"
                                            Section.FAVORITOS -> "⭐"
                                        }
                                    )
                                },
                                label = { Text(section.label) }
                            )
                        }
                    }
                }
            },
            floatingActionButton = {
                if (viewing == null && state.section == Section.EXPLORAR) {
                    Box {
                        FloatingActionButton(onClick = { fabMenuExpanded = true }) {
                            Text("+", style = MaterialTheme.typography.headlineSmall)
                        }
                        DropdownMenu(
                            expanded = fabMenuExpanded,
                            onDismissRequest = { fabMenuExpanded = false }
                        ) {
                            DropdownMenuItem(
                                text = { Text("📁 Nueva carpeta") },
                                onClick = { fabMenuExpanded = false; showCreateFolderDialog = true }
                            )
                            DropdownMenuItem(
                                text = { Text("📥 Importar archivo") },
                                onClick = { fabMenuExpanded = false; launchImport() }
                            )
                        }
                    }
                }
            }
        ) { padding ->
            Box(Modifier.fillMaxSize().padding(padding)) {
                when {
                    viewing != null -> FileViewer(
                        entry = viewing,
                        textContent = state.viewingTextContent,
                        isLoading = state.isLoadingViewer
                    )

                    state.section == Section.RECIENTES -> FileList(
                        entries = state.recents,
                        favoritePaths = state.favoritePaths,
                        emptyText = "Todavía no has abierto ningún archivo",
                        onOpen = onOpen,
                        onToggleFavorite = viewModel::toggleFavorite,
                        onRename = { entryPendingRename = it },
                        onCopy = { transferRequest = TransferRequest(it, move = false) },
                        onMove = { transferRequest = TransferRequest(it, move = true) },
                        onShare = { shareFile(it.path) },
                        onDelete = { entryPendingDelete = it }
                    )

                    state.section == Section.FAVORITOS -> FileList(
                        entries = state.favorites,
                        favoritePaths = state.favoritePaths,
                        emptyText = "Aún no tienes favoritos.\nUsa ⋮ en un archivo para agregarlo.",
                        onOpen = onOpen,
                        onToggleFavorite = viewModel::toggleFavorite,
                        onRename = { entryPendingRename = it },
                        onCopy = { transferRequest = TransferRequest(it, move = false) },
                        onMove = { transferRequest = TransferRequest(it, move = true) },
                        onShare = { shareFile(it.path) },
                        onDelete = { entryPendingDelete = it }
                    )

                    else -> Column(Modifier.fillMaxSize()) {
                        OutlinedTextField(
                            value = state.searchQuery,
                            onValueChange = viewModel::setSearchQuery,
                            placeholder = { Text("Buscar en esta carpeta") },
                            singleLine = true,
                            trailingIcon = {
                                if (state.searchQuery.isNotEmpty()) {
                                    TextButton(onClick = { viewModel.setSearchQuery("") }) { Text("✕") }
                                }
                            },
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp, vertical = 8.dp)
                        )
                        // Ruta actual siempre visible (lo pide el PDF).
                        Text(
                            "📂 Inicio" + state.currentPath.removePrefix(viewModel.rootPath),
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp)
                        )
                        Box(Modifier.weight(1f).fillMaxWidth()) {
                            val visible = state.visibleEntries
                            when {
                                state.isLoading -> CircularProgressIndicator(Modifier.align(Alignment.Center))
                                visible.isEmpty() -> Text(
                                    if (state.searchQuery.isBlank()) "Esta carpeta está vacía"
                                    else "Sin resultados para \"${state.searchQuery.trim()}\"",
                                    modifier = Modifier.align(Alignment.Center).padding(16.dp)
                                )
                                else -> FileList(
                                    entries = visible,
                                    favoritePaths = state.favoritePaths,
                                    emptyText = "",
                                    onOpen = onOpen,
                                    onToggleFavorite = viewModel::toggleFavorite,
                                    onRename = { entryPendingRename = it },
                                    onCopy = { transferRequest = TransferRequest(it, move = false) },
                                    onMove = { transferRequest = TransferRequest(it, move = true) },
                                    onShare = { shareFile(it.path) },
                                    onDelete = { entryPendingDelete = it }
                                )
                            }
                        }
                    }
                }
            }
        }

        if (showCreateFolderDialog) {
            NameDialog(
                title = "Nueva carpeta",
                initialText = "",
                confirmLabel = "Crear",
                onDismiss = { showCreateFolderDialog = false },
                onConfirm = { name ->
                    viewModel.createFolder(name)
                    showCreateFolderDialog = false
                }
            )
        }

        entryPendingRename?.let { entry ->
            NameDialog(
                title = "Renombrar",
                initialText = entry.name,
                confirmLabel = "Renombrar",
                onDismiss = { entryPendingRename = null },
                onConfirm = { newName ->
                    viewModel.renameEntry(entry, newName)
                    entryPendingRename = null
                }
            )
        }

        entryPendingDelete?.let { entry ->
            AlertDialog(
                onDismissRequest = { entryPendingDelete = null },
                title = { Text("Eliminar") },
                text = { Text("¿Seguro que quieres eliminar \"${entry.name}\"? Esta acción no se puede deshacer.") },
                confirmButton = {
                    TextButton(onClick = {
                        viewModel.deleteEntry(entry)
                        entryPendingDelete = null
                    }) { Text("Eliminar") }
                },
                dismissButton = {
                    TextButton(onClick = { entryPendingDelete = null }) { Text("Cancelar") }
                }
            )
        }

        transferRequest?.let { request ->
            FolderPickerDialog(
                title = (if (request.move) "Mover" else "Copiar") + " \"${request.entry.name}\" a…",
                confirmLabel = if (request.move) "Mover aquí" else "Copiar aquí",
                rootPath = viewModel.rootPath,
                startPath = viewModel.rootPath,
                listFolders = { viewModel.listFolders(it) },
                onDismiss = { transferRequest = null },
                onConfirm = { destination ->
                    if (request.move) viewModel.moveEntry(request.entry, destination)
                    else viewModel.copyEntry(request.entry, destination)
                    transferRequest = null
                }
            )
        }
    }
}

@Composable
private fun FileViewer(entry: FileEntry, textContent: String?, isLoading: Boolean) {
    Box(Modifier.fillMaxSize()) {
        when {
            entry.isImage -> {
                val bitmap = remember(entry.path) { loadImageBitmap(entry.path) }
                if (bitmap != null) {
                    Image(
                        bitmap = bitmap,
                        contentDescription = entry.name,
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.Fit
                    )
                } else {
                    Text("No se pudo abrir la imagen", modifier = Modifier.align(Alignment.Center))
                }
            }
            entry.isTextFile -> {
                if (isLoading) {
                    CircularProgressIndicator(Modifier.align(Alignment.Center))
                } else {
                    Column(
                        Modifier
                            .fillMaxSize()
                            .verticalScroll(rememberScrollState())
                            .padding(16.dp)
                    ) {
                        Text(textContent ?: "")
                    }
                }
            }
            else -> {
                Text(
                    "Todavía no hay un visor para archivos .${entry.extension}",
                    modifier = Modifier.align(Alignment.Center).padding(16.dp)
                )
            }
        }
    }
}

@Composable
private fun NameDialog(
    title: String,
    initialText: String,
    confirmLabel: String,
    onDismiss: () -> Unit,
    onConfirm: (String) -> Unit
) {
    var text by remember { mutableStateOf(initialText) }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(title) },
        text = {
            OutlinedTextField(
                value = text,
                onValueChange = { text = it },
                singleLine = true
            )
        },
        confirmButton = {
            TextButton(
                onClick = { if (text.isNotBlank()) onConfirm(text.trim()) },
                enabled = text.isNotBlank()
            ) { Text(confirmLabel) }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancelar") }
        }
    )
}

/**
 * Selector de carpeta de destino para copiar/mover: se navega por las subcarpetas de la
 * app (no se sale de la raíz) y se confirma con la carpeta que se está viendo.
 */
@Composable
private fun FolderPickerDialog(
    title: String,
    confirmLabel: String,
    rootPath: String,
    startPath: String,
    listFolders: suspend (String) -> List<FileEntry>,
    onDismiss: () -> Unit,
    onConfirm: (String) -> Unit
) {
    var path by remember { mutableStateOf(startPath) }
    var folders by remember { mutableStateOf(emptyList<FileEntry>()) }
    LaunchedEffect(path) { folders = listFolders(path) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(title) },
        text = {
            Column {
                Text(
                    "📂 Inicio" + path.removePrefix(rootPath),
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                if (path != rootPath) {
                    TextButton(onClick = {
                        path = path.substringBeforeLast('/', rootPath).ifEmpty { rootPath }
                    }) { Text("⬆ Subir") }
                }
                if (folders.isEmpty()) {
                    Text("(sin subcarpetas)", modifier = Modifier.padding(vertical = 12.dp))
                }
                Column(Modifier.heightIn(max = 240.dp).verticalScroll(rememberScrollState())) {
                    folders.forEach { folder ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { path = folder.path }
                                .padding(vertical = 10.dp)
                        ) {
                            Text("📁  ${folder.name}")
                        }
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = { onConfirm(path) }) { Text(confirmLabel) }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancelar") }
        }
    )
}

/** Ícono por tipo de archivo (emoji, ver nota arriba del archivo). */
private fun iconFor(entry: FileEntry): String = when {
    entry.isDirectory -> "📁"
    entry.isImage -> "🖼️"
    entry.isTextFile -> "📝"
    entry.extension.lowercase() in listOf("mp3", "wav", "ogg", "m4a") -> "🎵"
    entry.extension.lowercase() in listOf("mp4", "mov", "avi", "mkv") -> "🎬"
    entry.extension.lowercase() == "pdf" -> "📕"
    else -> "📄"
}

@Composable
private fun FileList(
    entries: List<FileEntry>,
    favoritePaths: Set<String>,
    emptyText: String,
    onOpen: (FileEntry) -> Unit,
    onToggleFavorite: (FileEntry) -> Unit,
    onRename: (FileEntry) -> Unit,
    onCopy: (FileEntry) -> Unit,
    onMove: (FileEntry) -> Unit,
    onShare: (FileEntry) -> Unit,
    onDelete: (FileEntry) -> Unit
) {
    if (entries.isEmpty()) {
        Box(Modifier.fillMaxSize()) {
            Text(emptyText, modifier = Modifier.align(Alignment.Center).padding(16.dp))
        }
    } else {
        LazyColumn(Modifier.fillMaxSize()) {
            items(entries, key = { it.path }) { entry ->
                FileRow(
                    entry = entry,
                    isFavorite = entry.path in favoritePaths,
                    onClick = { onOpen(entry) },
                    onToggleFavorite = { onToggleFavorite(entry) },
                    onRename = { onRename(entry) },
                    onCopy = { onCopy(entry) },
                    onMove = { onMove(entry) },
                    onShare = { onShare(entry) },
                    onDelete = { onDelete(entry) }
                )
            }
        }
    }
}

@Composable
private fun FileRow(
    entry: FileEntry,
    isFavorite: Boolean,
    onClick: () -> Unit,
    onToggleFavorite: () -> Unit,
    onRename: () -> Unit,
    onCopy: () -> Unit,
    onMove: () -> Unit,
    onShare: () -> Unit,
    onDelete: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(iconFor(entry), style = MaterialTheme.typography.titleLarge)
        Spacer(Modifier.width(16.dp))
        Column(Modifier.weight(1f)) {
            Text(entry.name)
            Text(
                entry.detailText(),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        if (isFavorite) Text("⭐")

        var menuExpanded by remember { mutableStateOf(false) }
        Box {
            IconButton(onClick = { menuExpanded = true }) {
                Text("⋮", style = MaterialTheme.typography.titleLarge)
            }
            DropdownMenu(expanded = menuExpanded, onDismissRequest = { menuExpanded = false }) {
                DropdownMenuItem(
                    text = { Text(if (isFavorite) "Quitar de favoritos" else "Agregar a favoritos") },
                    onClick = { menuExpanded = false; onToggleFavorite() }
                )
                DropdownMenuItem(
                    text = { Text("Copiar a…") },
                    onClick = { menuExpanded = false; onCopy() }
                )
                DropdownMenuItem(
                    text = { Text("Mover a…") },
                    onClick = { menuExpanded = false; onMove() }
                )
                DropdownMenuItem(
                    text = { Text("Renombrar") },
                    onClick = { menuExpanded = false; onRename() }
                )
                if (!entry.isDirectory) {
                    DropdownMenuItem(
                        text = { Text("Compartir") },
                        onClick = { menuExpanded = false; onShare() }
                    )
                }
                DropdownMenuItem(
                    text = { Text("Eliminar") },
                    onClick = { menuExpanded = false; onDelete() }
                )
            }
        }
    }
}
