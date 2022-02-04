//
//  Copyright © 2022 msyk. All rights reserved.
//

import CoreData

public typealias ManagedObject = NSManagedObject

extension ManagedObject {
    public convenience init(context: ManagedObjectContext) {
        self.init(context: context.rawValue)
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
