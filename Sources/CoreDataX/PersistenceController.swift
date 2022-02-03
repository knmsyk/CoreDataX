//
//  Created by msyk on 2020/10/23.
//

import CoreData

public final class PersistenceController {
    public enum Mode {
        case inMemory
        case sqlite(fileName: String)
        case iCloud(fileName: String, containerIdentifier: String, groupName: String?)
    }

    public private(set) lazy var viewContext: ManagedObjectContext = .init(rawValue: container.viewContext)
    public private(set) lazy var backgroundContext: ManagedObjectContext = makeNewBackgroundContext()
    private let container: NSPersistentContainer

    public convenience init(modelName: String, inMemory: Bool = false) {
        self.init(
            modelName: modelName,
            persistentStoreDescriptions: inMemory ? [MemoryPersistentStoreDescription()] : [SQLitePersistentStoreDescription(fileName: modelName)]
        )
    }

    public init(modelName: String, persistentStoreDescriptions: [PersistentStoreDescription]) {
        container = NSPersistentCloudKitContainer(name: modelName)
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.persistentStoreDescriptions = persistentStoreDescriptions.map(\.rawValue)
        container.loadPersistentStores { [unowned self] _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }

            Task { [unowned self] in
                for await notification in NotificationCenter.default.notifications(named: .NSManagedObjectContextDidSave, object: backgroundContext.rawValue) {
                    await viewContext.rawValue.perform(schedule: .immediate) { [unowned self] in
                        viewContext.rawValue.mergeChanges(fromContextDidSave: notification)
                    }
                }
            }
        }
    }

    public func makeNewBackgroundContext() -> ManagedObjectContext {
        let context = container.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        return .init(rawValue: context)
    }

    public func commit() async throws {
        try await viewContext.rawValue.perform(schedule: .immediate) { [unowned self] in
            if backgroundContext.rawValue.hasChanges {
                try backgroundContext.rawValue.save()
            }
            if viewContext.rawValue.hasChanges {
                try viewContext.rawValue.save()
            }
        }
    }
}

extension ManagedObject {
    public static func fetchRequest<Entity: ManagedObject>(
        predicate: Predicate<Entity>?,
        sortDescriptors: [SortDescriptor<Entity>],
        offset: Int? = nil,
        limit: Int? = nil
    ) -> NSFetchRequest<Entity> {
        let request = Entity.fetchRequest()
        request.predicate = predicate?.rawValue
        request.sortDescriptors = sortDescriptors.map { .init($0) }
        if let offset = offset {
            request.fetchOffset = offset
        }
        if let limit = limit {
            request.fetchLimit = limit
        }
        return request as! NSFetchRequest<Entity>
    }
}
