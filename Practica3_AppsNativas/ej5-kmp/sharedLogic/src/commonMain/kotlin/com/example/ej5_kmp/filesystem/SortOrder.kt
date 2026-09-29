package com.example.ej5_kmp.filesystem

/** Criterios de ordenamiento de la lista (igual que en la app de Mike: nombre, fecha, tamaño). */
enum class SortOrder(val label: String) {
    NOMBRE("Nombre"),
    FECHA("Fecha"),
    TAMANO("Tamaño")
}

/** Ordena dejando siempre las carpetas primero. */
fun List<FileEntry>.sortedFor(order: SortOrder, ascending: Boolean): List<FileEntry> {
    val byCriteria: Comparator<FileEntry> = when (order) {
        SortOrder.NOMBRE -> compareBy<FileEntry> { it.name.lowercase() }
        SortOrder.FECHA -> compareBy<FileEntry> { it.lastModifiedEpochMillis }
        SortOrder.TAMANO -> compareBy<FileEntry> { it.sizeBytes }
    }
    val directed = if (ascending) byCriteria else byCriteria.reversed()
    return sortedWith(compareByDescending<FileEntry> { it.isDirectory }.then(directed))
}
