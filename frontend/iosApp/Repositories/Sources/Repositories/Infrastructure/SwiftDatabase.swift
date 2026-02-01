import Foundation
import SwiftData

@ModelActor
public actor SwiftDatabase {

    public static func create(for userId: Int, modelTypes: [any PersistentModel.Type]) throws -> SwiftDatabase {
        let schema = Schema(modelTypes)
        let userDirectory = URL.documentsDirectory.appendingPathComponent("user_\(userId)")

        // Create directory if it doesn't exist
        try FileManager.default.createDirectory(at: userDirectory, withIntermediateDirectories: true)

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: userDirectory.appendingPathComponent("database.sqlite")
        )
        let modelContainer = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
        return SwiftDatabase(modelContainer: modelContainer)
    }

    // MARK: - Insert

    public func insert<Model: PersistentModel & DomainConvertible>(
        _ entity: Model.Entity,
        as modelType: Model.Type
    ) throws {
        let model = Model(from: entity)
        modelContext.insert(model)
        try modelContext.save()
    }

    // MARK: - Fetch

    public func fetch<T: DomainConvertible>(
        _ descriptor: FetchDescriptor<T>
    ) throws -> [T.Entity] {
        let models = try modelContext.fetch(descriptor)
        return models.map { $0.entity() }
    }

    public func fetchCount<T: PersistentModel>(
        _ descriptor: FetchDescriptor<T>
    ) throws -> Int {
        try modelContext.fetchCount(descriptor)
    }

    // MARK: - Upsert

    public func upsert<Model: PersistentModel & DomainConvertible>(
        _ entity: Model.Entity,
        as modelType: Model.Type,
        predicate: Predicate<Model>
    ) throws {
        let descriptor = FetchDescriptor<Model>(predicate: predicate)
        let models = try modelContext.fetch(descriptor)

        if let existingModel = models.first {
            existingModel.update(from: entity)
        } else {
            let newModel = Model(from: entity)
            modelContext.insert(newModel)
        }
        try modelContext.save()
    }

    // MARK: - Delete

    public func delete<T: PersistentModel>(
        where predicate: Predicate<T>?
    ) throws {
        try modelContext.delete(model: T.self, where: predicate)
        try modelContext.save()
    }
}
