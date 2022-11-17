//
//  Copyright © 2022 msyk. All rights reserved.
//

import SwiftUI

extension FetchRequest where Result: ManagedObject {
   public init(predicate: Predicate<Result>? = nil, sortDescriptors: [SortDescriptor<Result>] = []) {
        self.init(fetchRequest: Result.fetchRequest(predicate: predicate, sortDescriptors: sortDescriptors))
    }
}
