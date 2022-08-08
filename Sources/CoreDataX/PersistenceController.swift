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
    public private(set) var spotlightDelegates: [NSCoreDataCoreSpotlightDelegate] = []
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
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        container.persistentStoreDescriptions = persistentStoreDescriptions.map(\.rawValue)
        container.persistentStoreDescriptions
            .filter { $0.storeType == .sqlite }
            .forEach { storeDescription in
                let spotlightDelegate = NSCoreDataCoreSpotlightDelegate(forStoreWith: storeDescription, coordinator: container.persistentStoreCoordinator)
                spotlightDelegate.startSpotlightIndexing()
                spotlightDelegates.append(spotlightDelegate)
            }
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
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        return .init(rawValue: context)
    }

    @MainActor
    public func commit() async throws {
        try await backgroundContext.rawValue.perform { [unowned self] in
            if backgroundContext.rawValue.hasChanges {
                try backgroundContext.rawValue.save()
            }
        }
        try await viewContext.rawValue.perform { [unowned self] in
            if viewContext.rawValue.hasChanges {
                try viewContext.rawValue.save()
            }
        }
    }
}
