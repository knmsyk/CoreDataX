//
//  Copyright © 2022 msyk. All rights reserved.
//

import CoreData

public class PersistentStoreDescription {
    public let rawValue: NSPersistentStoreDescription

    public init(rawValue: NSPersistentStoreDescription) {
        self.rawValue = rawValue
    }
}

extension PersistentStoreDescription {
    public static func make(_ mode: PersistenceController.Mode) -> PersistentStoreDescription {
        switch mode {
        case .inMemory:
            return MemoryPersistentStoreDescription()
        case .sqlite(let fileName):
            return SQLitePersistentStoreDescription(fileName: fileName)
        case .iCloud(let fileName, let containerIdentifier, let groupName):
            return CloudKitPersistentStoreDescription(containerIdentifier: containerIdentifier, fileName: fileName, groupName: groupName)
        }
    }
}

