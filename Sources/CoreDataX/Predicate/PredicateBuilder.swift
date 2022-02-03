//
//  Copyright © 2022 msyk. All rights reserved.
//

import Foundation

@resultBuilder
public struct AndPredicateBuilder<Entity> {
    public static func buildBlock(_ components: Predicate<Entity>...) -> Predicate<Entity> {
        CompoundPredicate(and: components)
    }

    public static func buildOptional(_ component: Predicate<Entity>?) -> Predicate<Entity> {
        CompoundPredicate(and: [component].compactMap { $0 })
    }

    public static func buildEither(first component: Predicate<Entity>) -> Predicate<Entity> {
        component
    }

    public static func buildEither(second component: Predicate<Entity>) -> Predicate<Entity> {
        component
    }
}

@resultBuilder
public struct OrPredicateBuilder<Entity> {
    static func buildBlock(_ components: Predicate<Entity>...) -> Predicate<Entity> {
        CompoundPredicate(or: components)
    }

    static func buildOptional(_ component: Predicate<Entity>?) -> Predicate<Entity> {
        CompoundPredicate(or: [component].compactMap { $0 })
    }

    public static func buildEither(first component: Predicate<Entity>) -> Predicate<Entity> {
        component
    }

    public static func buildEither(second component: Predicate<Entity>) -> Predicate<Entity> {
        component
    }
}
