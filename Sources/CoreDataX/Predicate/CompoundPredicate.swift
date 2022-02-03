//
//  Copyright © 2022 msyk. All rights reserved.
//

import Foundation

public final class CompoundPredicate<Entity>: Predicate<Entity> {
    public typealias LogicalType = NSCompoundPredicate.LogicalType

    public let type: LogicalType
    public let subpredicates: [Predicate<Entity>]

    public init(type: LogicalType, subpredicates: [Predicate<Entity>]) {
        self.type = type
        self.subpredicates = subpredicates

        let predicate = NSCompoundPredicate(type: self.type, subpredicates: self.subpredicates.map { $0.rawValue })

        super.init(rawValue: predicate)
    }

    public convenience init(and subpredicates: [Predicate<Entity>]) {
        self.init(type: .and, subpredicates: subpredicates)
    }

    public convenience init(or subpredicates: [Predicate<Entity>]) {
        self.init(type: .or, subpredicates: subpredicates)
    }

    public convenience init(not predicate: Predicate<Entity>) {
        self.init(type: .not, subpredicates: [predicate])
    }
}

// MARK: -

public func && <Entity>(left: Predicate<Entity>, right: Predicate<Entity>) -> Predicate<Entity> {
    CompoundPredicate<Entity>(type: .and, subpredicates: [left, right])
}

public func || <Entity>(left: Predicate<Entity>, right: Predicate<Entity>) -> Predicate<Entity> {
    CompoundPredicate<Entity>(type: .or, subpredicates: [left, right])
}

prefix public func ! <Entity>(left: Predicate<Entity>) -> Predicate<Entity> {
    CompoundPredicate<Entity>(type: .not, subpredicates: [left])
}

