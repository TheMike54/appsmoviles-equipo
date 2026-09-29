import CoreData

/// Pila de Core Data de la app. El modelo se define en código (sin archivo .xcdatamodeld)
/// para que se pueda leer completo aquí:
///
/// - **Medio**: una foto o una grabación. Guarda el nombre del archivo (el archivo vive en
///   Documents), el tipo, la fecha, la ubicación, las etiquetas, la duración (audio) y el
///   filtro aplicado (foto).
/// - **Album**: categoría para organizar el contenido. Un medio pertenece a cero o un álbum.
final class Persistencia {
    static let compartida = Persistencia()

    let contenedor: NSPersistentContainer
    var contexto: NSManagedObjectContext { contenedor.viewContext }

    init(enMemoria: Bool = false) {
        contenedor = NSPersistentContainer(name: "CamaraMicrofono", managedObjectModel: Persistencia.modelo)
        if enMemoria {
            contenedor.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        contenedor.loadPersistentStores { _, error in
            if let error { print("Error al abrir Core Data: \(error)") }
        }
        contenedor.viewContext.automaticallyMergesChangesFromParent = true
        contenedor.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func guardar() {
        guard contexto.hasChanges else { return }
        do { try contexto.save() } catch { print("Error al guardar: \(error)") }
    }

    /// Borra todos los registros (lo usa el modo de pruebas).
    func borrarTodo() {
        for entidad in ["Medio", "Album"] {
            let peticion = NSBatchDeleteRequest(fetchRequest: NSFetchRequest(entityName: entidad))
            _ = try? contenedor.persistentStoreCoordinator.execute(peticion, with: contexto)
        }
        contexto.reset()
    }

    // MARK: Modelo

    static let modelo: NSManagedObjectModel = {
        func atributo(_ nombre: String, _ tipo: NSAttributeType, opcional: Bool = false, defecto: Any? = nil) -> NSAttributeDescription {
            let a = NSAttributeDescription()
            a.name = nombre
            a.attributeType = tipo
            a.isOptional = opcional
            a.defaultValue = defecto
            return a
        }

        let medio = NSEntityDescription()
        medio.name = "Medio"
        medio.managedObjectClassName = NSStringFromClass(Medio.self)

        let album = NSEntityDescription()
        album.name = "Album"
        album.managedObjectClassName = NSStringFromClass(Album.self)

        let medioAlbum = NSRelationshipDescription()
        medioAlbum.name = "album"
        medioAlbum.destinationEntity = album
        medioAlbum.minCount = 0
        medioAlbum.maxCount = 1
        medioAlbum.isOptional = true
        medioAlbum.deleteRule = .nullifyDeleteRule

        let albumMedios = NSRelationshipDescription()
        albumMedios.name = "medios"
        albumMedios.destinationEntity = medio
        albumMedios.minCount = 0
        albumMedios.maxCount = 0 // a muchos
        albumMedios.isOptional = true
        albumMedios.deleteRule = .nullifyDeleteRule

        medioAlbum.inverseRelationship = albumMedios
        albumMedios.inverseRelationship = medioAlbum

        medio.properties = [
            atributo("id", .UUIDAttributeType),
            atributo("tipo", .stringAttributeType, defecto: "foto"),
            atributo("archivo", .stringAttributeType, defecto: ""),
            atributo("fecha", .dateAttributeType),
            atributo("latitud", .doubleAttributeType, opcional: true),
            atributo("longitud", .doubleAttributeType, opcional: true),
            atributo("etiquetas", .stringAttributeType, defecto: ""),
            atributo("duracion", .doubleAttributeType, defecto: 0.0),
            atributo("filtro", .stringAttributeType, opcional: true),
            medioAlbum
        ]
        album.properties = [
            atributo("id", .UUIDAttributeType),
            atributo("nombre", .stringAttributeType, defecto: ""),
            atributo("fecha", .dateAttributeType),
            albumMedios
        ]

        let modelo = NSManagedObjectModel()
        modelo.entities = [medio, album]
        return modelo
    }()
}

/// Foto o grabación guardada.
@objc(Medio)
final class Medio: NSManagedObject, Identifiable {
    @NSManaged var id: UUID
    @NSManaged var tipo: String
    @NSManaged var archivo: String
    @NSManaged var fecha: Date
    @NSManaged var latitud: NSNumber?
    @NSManaged var longitud: NSNumber?
    @NSManaged var etiquetas: String
    @NSManaged var duracion: Double
    @NSManaged var filtro: String?
    @NSManaged var album: Album?

    var esFoto: Bool { tipo == "foto" }

    /// Ruta del archivo dentro de Documents.
    var url: URL { AlmacenMedios.carpetaDocumentos.appendingPathComponent(archivo) }

    var listaEtiquetas: [String] {
        etiquetas.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    var textoUbicacion: String? {
        guard let latitud, let longitud else { return nil }
        return String(format: "%.4f, %.4f", latitud.doubleValue, longitud.doubleValue)
    }

    static func peticion() -> NSFetchRequest<Medio> { NSFetchRequest<Medio>(entityName: "Medio") }
}

/// Álbum o categoría.
@objc(Album)
final class Album: NSManagedObject, Identifiable {
    @NSManaged var id: UUID
    @NSManaged var nombre: String
    @NSManaged var fecha: Date
    @NSManaged var medios: Set<Medio>

    static func peticion() -> NSFetchRequest<Album> { NSFetchRequest<Album>(entityName: "Album") }
}
