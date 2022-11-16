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
    public private(set) var spotlightDelegates: [NSCoreDataCoreSpotlightDelegate] = []
    private let container: NSPersistentContainer

    public convenience init(modelName: String, managedObjectModel: NSManagedObjectModel? = nil, inMemory: Bool = false) {
        self.init(
            modelName: modelName,
            managedObjectModel: managedObjectModel,
            persistentStoreDescriptions: inMemory ? [MemoryPersistentStoreDescription()] : [SQLitePersistentStoreDescription(fileName: modelName)]
        )
    }

    public convenience init(modelName: String, managedObjectModel: NSManagedObjectModel? = nil, mode: Mode) {
        self.init(modelName: modelName, managedObjectModel: managedObjectModel, persistentStoreDescriptions: [.make(mode)])
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
        container.loadPersistentStores { [unowned self] _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            } else {
                container.persistentStoreDescriptions
                    .filter { $0.storeType == .sqlite }
                    .forEach { [unowned self] storeDescription in
                        let spotlightDelegate = NSCoreDataCoreSpotlightDelegate(
                            forStoreWith: storeDescription,
                            coordinator: self.container.persistentStoreCoordinator
                        )
                        spotlightDelegate.startSpotlightIndexing()
                        self.spotlightDelegates.append(spotlightDelegate)
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
}

// MARK: -

extension PersistenceController {
    public func withBackgroundContext(_ body: @escaping (ManagedObjectContext) throws -> Void) async throws {
        let backgroundContext = makeNewBackgroundContext()
        try await backgroundContext.rawValue.perform {
            try body(backgroundContext)
        }
        try await backgroundContext.commit()
    }
}

