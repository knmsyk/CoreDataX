//
//  Copyright © 2022 msyk. All rights reserved.
//

import CoreData

public class SQLitePersistentStoreDescription: PersistentStoreDescription {
    public init(url: URL) {
        let persistentStoreDescription = NSPersistentStoreDescription(url: url)
        persistentStoreDescription.storeType = .sqlite
        super.init(rawValue: persistentStoreDescription)
        rawValue.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
    }

    public convenience init(fileName: String, groupName: String? = nil) {
        let url = FileManager.default.sqliteURL(fileName: fileName, groupName: groupName)
        self.init(url: url)
    }
}

extension FileManager {
    func sqliteURL(fileName: String, groupName: String?) -> URL {
        directoryURL(groupName: groupName)
            .appendingPathComponent(fileName)
            .appendingPathExtension("sqlite")
    }

    private func directoryURL(groupName: String?) -> URL {
        if let groupName = groupName {
            return containerURL(forSecurityApplicationGroupIdentifier: groupName)!
        } else {
            return NSPersistentContainer.defaultDirectoryURL()
        }
    }
}
