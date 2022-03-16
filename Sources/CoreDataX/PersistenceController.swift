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

    public convenience init(modelName: String, managedObjectModel: NSManagedObjectModel? = nil, inMemory: Bool = false) {
        self.init(
            modelName: modelName,
            managedObjectModel: managedObjectModel,
            persistentStoreDescriptions: inMemory ? [MemoryPersistentStoreDescription()] : [SQLitePersistentStoreDescription(fileName: modelName)]
        )
    }

    public init(modelName: String, managedObjectModel: NSManagedObjectModel? = nil, persistentStoreDescriptions: [PersistentStoreDescription]) {
        if let managedObjectModel = managedObjectModel {
            container = NSPersistentCloudKitContainer(name: modelName, managedObjectModel: managedObjectModel)
        } else {
            container = NSPersistentCloudKitContainer(name: modelName)
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.persistentStoreDescriptions = persistentStoreDescriptions.map(\.rawValue)
        container.loadPersistentStores { [unowned self] _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }

            Task { [unowned self] in
                for await notification in NotificationCenter.default.notifications(named: .NSManagedObjectContextDidSave, object: self.backgroundContext.rawValue) {
                    await self.viewContext.rawValue.perform { [unowned self] in
                        self.viewContext.rawValue.mergeChanges(fromContextDidSave: notification)
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
        try await viewContext.rawValue.perform { [unowned self] in
            if backgroundContext.rawValue.hasChanges {
                try backgroundContext.rawValue.save()
            }
            if viewContext.rawValue.hasChanges {
                try viewContext.rawValue.save()
            }
        }
    }
}
