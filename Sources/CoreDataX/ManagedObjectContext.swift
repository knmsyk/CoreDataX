//
//  Copyright © 2021 msyk. All rights reserved.
//

import CoreData

public final class ManagedObjectContext {
    public let rawValue: NSManagedObjectContext

    public init(rawValue: NSManagedObjectContext) {
        self.rawValue = rawValue
    }
}

extension ManagedObjectContext {
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

    public func batchDelete<Object: ManagedObject>(predicate: Predicate<Object>) async throws {
        if isSQLite {
            let request = Object.fetchRequest()
            request.predicate = predicate.rawValue
            try await batchDelete(request: request)
        } else {
            let request = Object.fetchRequest(predicate: predicate)
            let objects = try await fetch(request: request)
            await delete(objects)
        }
    }

    public func batchDelete(request: NSFetchRequest<NSFetchRequestResult>) async throws {
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

    public var isSQLite: Bool {
        rawValue.persistentStoreCoordinator?.persistentStores.first?.type == NSPersistentStore.StoreType.sqlite.rawValue
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
        if isSQLite {
            try await batchDelete(request: entityType.fetchRequest())
        } else {
            try await delete(fetchAll(entityType))
        }
    }
}

extension NSManagedObjectContext {
    public func commit() async throws {
        try await perform { [unowned self] in
            guard hasChanges else { return }
            try save()
        }
    }
}
