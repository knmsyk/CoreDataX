//
//  Copyright © 2022 msyk. All rights reserved.
//

import CoreData

public class MemoryPersistentStoreDescription: PersistentStoreDescription {
    public init() {
        let persistentStoreDescription = NSPersistentStoreDescription(url: URL(fileURLWithPath: "/dev/null"))
        persistentStoreDescription.type = NSInMemoryStoreType

        super.init(rawValue: persistentStoreDescription)
    }
}
