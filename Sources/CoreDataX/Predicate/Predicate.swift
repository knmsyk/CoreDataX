//
//  Copyright © 2021 msyk. All rights reserved.
//

import Foundation

public class Predicate<Entity> {
    public let rawValue: NSPredicate

    public var predicateFormat: String {
        rawValue.predicateFormat
    }

    public convenience init(format predicateFormat: String, argumentArray arguments: [Any]?) {
        self.init(rawValue: NSPredicate(format: predicateFormat, argumentArray: arguments))
    }

    public convenience init(format predicateFormat: String, arguments argList: CVaListPointer) {
        self.init(rawValue: NSPredicate(format: predicateFormat, arguments: argList))
    }

    public convenience init(value: Bool) {
        self.init(rawValue: NSPredicate(value: value))
    }

    public init(rawValue: NSPredicate) {
        self.rawValue = rawValue
    }
}
