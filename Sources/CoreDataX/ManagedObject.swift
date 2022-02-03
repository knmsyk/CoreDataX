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
