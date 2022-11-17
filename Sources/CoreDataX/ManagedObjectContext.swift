//
//  Copyright © 2021 msyk. All rights reserved.
//

import CoreData

public final actor ManagedObjectContext {
    public nonisolated let rawValue: NSManagedObjectContext

    public init(rawValue: NSManagedObjectContext) {
        self.rawValue = rawValue
    }
}

extension ManagedObjectContext {
    public nonisolated func save() throws {
        try rawValue.save()
    }

    public func commit() async throws {
        try await rawValue.commit()
    }

    public func create<Object: ManagedObject>() async -> Object {
        await rawValue.perform { [unowned self] in
            Object(context: rawValue)
        }
    }

    public func fetch<Object: ManagedObject>(
        request: NSFetchRequest<Object>
    ) async throws -> [Object] {
        try await rawValue.perform { [unowned self] in
            try rawValue.fetch(request)
        }
    }

    public func fetch<Object: ManagedObject>(
        predicate: Predicate<Object>? = nil,
        sortDescriptors: [SortDescriptor<Object>] = [],
        offset: Int? = nil,
        limit: Int? = nil,
        size: Int? = nil
    ) async throws -> [Object] {
        try await fetch(
            request: Object.fetchRequest(
                predicate: predicate,
                sortDescriptors: sortDescriptors,
                offset: offset,
                limit: limit,
                size: size
            )
        )
    }

    public func count<Object: ManagedObject>(_ predicate: Predicate<Object>? = nil) async throws -> Int {
        try await rawValue.perform { [unowned self] in
            let request = Object.fetchRequest(predicate: predicate)
            return try rawValue.count(for: request)
        }
    }

    public func distinct<Object: ManagedObject, Value>(_ keyPaths: [KeyPath<Object, Value>], predicate: Predicate<Object>? = nil, sortDescriptors: [SortDescriptor<Object>]) async throws -> [Value] {
        try await rawValue.perform { [unowned self] in
            let request = Object.distinctFetchRequest(keyPaths, predicate: predicate, sortDescriptors: sortDescriptors)
            let result = try rawValue.fetch(request)
            let dic = result as! [[String: Value]]
            return dic.compactMap { $0.values.first }
        }
    }

    public func update<Object: ManagedObject>(_ objects: [Object], updating: @escaping (Object) -> Void) async {
        await rawValue.perform { [unowned self] in
            for object in objects {
                updating(rawValue.object(with: object.objectID) as! Object)
            }
        }
    }

    public func delete<Object: ManagedObject>(_ objects: [Object]) async {
        await rawValue.perform { [unowned self] in
            for object in objects {
                rawValue.delete(rawValue.object(with: object.objectID))
            }
        }
    }

    /// Delete objects in the SQLite persistent store without loading them into memory.
    /// Available only when using a SQLite persistent store
    /// Ref: https://developer.apple.com/documentation/coredata/nsbatchdeleterequest
    public func batchDelete<Object: ManagedObject>(predicate: Predicate<Object>? = nil) async throws {
        let request = Object.fetchRequest()
        request.predicate = predicate?.rawValue
        try await batchDelete(request: request)
    }

    public func batchDelete(request: NSFetchRequest<any NSFetchRequestResult>) async throws {
        try await rawValue.perform { [unowned self] in
            let batchRequest = NSBatchDeleteRequest(fetchRequest: request)
            batchRequest.resultType = .resultTypeObjectIDs
            let deleteResult = try rawValue.execute(batchRequest) as? NSBatchDeleteResult

            if let objectIDs = deleteResult?.result as? [NSManagedObjectID] {
                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs],
                    into: [rawValue]
                )
            }
        }
    }
}

extension ManagedObjectContext {
    public var isInMemory: Bool {
        rawValue.persistentStoreCoordinator?.persistentStores.first?.type == NSPersistentStore.StoreType.inMemory.rawValue
    }

    public func fetch<Object: ManagedObject>(
        _ sortDescriptors: [SortDescriptor<Object>] = [],
        offset: Int? = nil,
        limit: Int? = nil,
        size: Int? = nil,
        @AndPredicateBuilder<Object> predicate: () -> Predicate<Object>
    ) async throws -> [Object] {
        try await fetch(
            predicate: predicate(),
            sortDescriptors: sortDescriptors,
            offset: offset,
            limit: limit,
            size: size
        )
    }

    public func fetchAll<Object: ManagedObject>(
        _ entityType: Object.Type,
        sortDescriptors: [SortDescriptor<Object>] = []
    ) async throws -> [Object] {
        try await fetch(request: entityType.fetchRequest(predicate: nil, sortDescriptors: sortDescriptors))
    }

    public func fetchOrCreate<Object: ManagedObject>(
        _ sortDescriptors: [SortDescriptor<Object>] = [],
        @AndPredicateBuilder<Object> predicate: () -> Predicate<Object>
    ) async throws -> Object {
        let objects = try await fetch(sortDescriptors, predicate: predicate)
        assert(objects.count <= 1)
        if let object = objects.last {
            return object
        }
        return await create()
    }

    public func count<Object: ManagedObject>(
        @AndPredicateBuilder<Object> predicate: () -> Predicate<Object>
    ) async throws -> Int {
        try await count(predicate())
    }

    public func deleteAll<Object: ManagedObject>(
        _ entityType: Object.Type
    ) async throws {
        if isInMemory {
            try await delete(fetchAll(entityType))
        } else {
            try await batchDelete(request: entityType.fetchRequest())
        }
    }
}

extension NSManagedObjectContext {
    @MainActor
    public func commit() throws {
        guard hasChanges else { return }
        try save()
    }
}
