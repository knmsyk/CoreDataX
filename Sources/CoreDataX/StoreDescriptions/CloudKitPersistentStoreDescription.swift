//
//  Copyright © 2022 msyk. All rights reserved.
//

import Foundation

public final class CloudKitPersistentStoreDescription: SQLitePersistentStoreDescription {
    public init(url: URL, containerIdentifier: String) {
        super.init(url: url)
        rawValue.cloudKitContainerOptions = .init(containerIdentifier: containerIdentifier)
        rawValue.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
    }

    public convenience init(containerIdentifier: String, fileName: String, groupName: String? = nil) {
        let url = FileManager.default.sqliteURL(fileName: fileName, groupName: groupName)
        self.init(url: url, containerIdentifier: containerIdentifier)
    }
}
