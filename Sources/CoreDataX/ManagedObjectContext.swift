//
//  Copyright © 2021 msyk. All rights reserved.
//

import CoreData

public final actor ManagedObjectContext {
    public nonisolated let rawValue: NSManagedObjectContext

    internal init(rawValue: NSManagedObjectContext) {
        self.rawValue = rawValue
    }
}

extension ManagedObjectContext {
    public nonisolated func save() throws {
        try rawValue.save()
    }

    public func create<Object: ManagedObject>() -> Object {
        Object(context: rawValue)
    }

    public func fetch<Object: ManagedObject>(
        predicate: Predicate<Object>? = nil,
        sortDescriptors: [SortDescriptor<Object>] = [],
        offset: Int? = nil,
        limit: Int? = nil
    ) throws -> [Object] {
        try rawValue.fetch(Object.fetchRequest(predicate: predicate, sortDescriptors: sortDescriptors, offset: offset, limit: limit))
    }

    public func count<Object: ManagedObject>(_ predicate: Predicate<Object>? = nil) throws -> Int {
        let request = Object.fetchRequest(predicate: predicate)
        return try rawValue.count(for: request)
    }

    public func distinct<Object: ManagedObject, Value>(_ keyPaths: [KeyPath<Object, Value>], predicate: Predicate<Object>? = nil, sortDescriptors: [SortDescriptor<Object>]) throws -> [Value] {
        let request = Object.fetchRequest(predicate: predicate, sortDescriptors: sortDescriptors)
        request.returnsDistinctResults = true
        request.propertiesToFetch = keyPaths.map(\.pathString)
        request.resultType = .dictionaryResultType
        let result = try rawValue.fetch(request) as! [NSDictionary]
        let dic = result as! [[String: Value]]
        return dic.compactMap { $0.values.first }
    }

    public func update<Object: ManagedObject>(_ objects: [Object], updating: @escaping (Object) -> Void) async throws {
        await rawValue.perform { [unowned self] in
            for object in objects {
                updating(rawValue.object(with: object.objectID) as! Object)
            }
        }
    }

    public func delete<Object: ManagedObject>(_ objects: [Object]) async throws {
        await rawValue.perform { [unowned self] in
            for object in objects {
                rawValue.delete(rawValue.object(with: object.objectID))
            }
        }
    }
}

extension ManagedObjectContext {
    public func fetch<Object: ManagedObject>(_ sortDescriptors: [SortDescriptor<Object>] = [], offset: Int? = nil, limit: Int? = nil, @AndPredicateBuilder<Object> predicate: () -> Predicate<Object>) throws -> [Object] {
        try fetch(predicate: predicate(), sortDescriptors: sortDescriptors, offset: offset, limit: limit)
    }

    public func fetchOrCreate<Object: ManagedObject>(_ sortDescriptors: [SortDescriptor<Object>] = [], @AndPredicateBuilder<Object> predicate: () -> Predicate<Object>) throws -> Object {
        let objects = try fetch(sortDescriptors, predicate: predicate)
        assert(objects.count <= 1)
        return objects.last ?? create()
    }
}
