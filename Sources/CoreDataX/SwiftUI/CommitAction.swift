//
//  Copyright © 2022 msyk. All rights reserved.
//

import CoreData
import SwiftUI

public struct CommitAction {
    var managedObjectContext: NSManagedObjectContext

    public func callAsFunction() async throws {
        try await managedObjectContext.commit()
    }
}

extension EnvironmentValues {
    public var commit: CommitAction {
        .init(managedObjectContext: managedObjectContext)
    }
}
