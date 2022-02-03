//
//  Copyright © 2021 msyk. All rights reserved.
//

import CoreData

public final actor ManagedObjectContext {
    public nonisolated let rawValue: NSManagedObjectContext

    internal init(rawValue: NSManagedObjectContext) {
        self.rawValue = rawValue
    }

    public func create<Entity: ManagedObject>() -> Entity {
        Entity(context: rawValue)
    }
}

extension ManagedObjectContext {
    public nonisolated func save() throws {
        try rawValue.save()
    }

    public func fetch<Entity: ManagedObject>(
        predicate: Predicate<Entity>? = nil,
        sortDescriptors: [SortDescriptor<Entity>] = [],
        offset: Int? = nil,
        limit: Int? = nil
    ) throws -> [Entity] {
        try rawValue.fetch(Entity.fetchRequest(predicate: predicate, sortDescriptors: sortDescriptors, offset: offset, limit: limit))
    }

    public func distinct<Entity: ManagedObject, Value>(_ keyPaths: [KeyPath<Entity, Value>], predicate: Predicate<Entity>? = nil, sortDescriptors: [SortDescriptor<Entity>]) throws -> [Value] {
        let request = Entity.fetchRequest(predicate: predicate, sortDescriptors: sortDescriptors)
        request.returnsDistinctResults = true
        request.propertiesToFetch = keyPaths.map(\.pathString)
        request.resultType = .dictionaryResultType
        let result = try rawValue.fetch(request) as! [NSDictionary]
        let dic = result as! [[String: Value]]
        return dic.compactMap { $0.values.first }
    }

    public func update<Entity: ManagedObject>(_ entities: [Entity], updating: @escaping (Entity) -> Void) async throws {
        await rawValue.perform(schedule: .enqueued) { [unowned self] in
            for entity in entities {
                updating(rawValue.object(with: entity.objectID) as! Entity)
            }
        }
    }

    public func delete<Entity: ManagedObject>(_ entities: [Entity]) async throws {
        await rawValue.perform(schedule: .enqueued) { [unowned self] in
            for entity in entities {
                rawValue.delete(rawValue.object(with: entity.objectID))
            }
        }
    }
}

extension ManagedObjectContext {
    public func fetch<Entity: ManagedObject>(_ sortDescriptors: [SortDescriptor<Entity>] = [], offset: Int? = nil, limit: Int? = nil, @AndPredicateBuilder<Entity> predicate: () -> Predicate<Entity>) throws -> [Entity] {
        try fetch(predicate: predicate(), sortDescriptors: sortDescriptors, offset: offset, limit: limit)
    }

    public func fetchOrCreate<Entity: ManagedObject>(_ sortDescriptors: [SortDescriptor<Entity>] = [], @AndPredicateBuilder<Entity> predicate: () -> Predicate<Entity>) throws -> Entity {
        let objects = try fetch(sortDescriptors, predicate: predicate)
        assert(objects.count <= 1)
        return objects.last ?? create()
    }
}

// MARK: -

extension AnyKeyPath {
    fileprivate var pathString: String {
        _kvcKeyPathString!
    }
}
