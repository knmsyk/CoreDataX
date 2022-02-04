//
//  Copyright © 2022 msyk. All rights reserved.
//

import Foundation

public final class ComparisonPredicate<Entity>: Predicate<Entity> {
    public typealias Modifier = NSComparisonPredicate.Modifier
    public typealias Operator = NSComparisonPredicate.Operator
    public typealias Options = NSComparisonPredicate.Options

    public let leftExpression: NSExpression
    public let rightExpression: NSExpression

    public let modifier: Modifier
    public let operatorType: Operator

    public let options: Options

    public init(leftExpression left: NSExpression, rightExpression right: NSExpression, modifier: Modifier, type operatorType: Operator, options: Options = []) {
        self.leftExpression = left
        self.rightExpression = right
        self.modifier = modifier
        self.operatorType = operatorType
        self.options = options

        let predicate = NSComparisonPredicate(
            leftExpression: self.leftExpression,
            rightExpression: self.rightExpression,
            modifier: self.modifier,
            type: self.operatorType,
            options: self.options
        )

        super.init(rawValue: predicate)
    }
}

// MARK: -

// .equalTo
public func == <Entity, Value: Equatable>(left: KeyPath<Entity, Value>, right: Value) -> ComparisonPredicate<Entity> {
    ComparisonPredicate<Entity>(
        leftExpression: NSExpression(forKeyPath: left),
        rightExpression: NSExpression(forConstantValue: right),
        modifier: .direct,
        type: .equalTo,
        options: right.comparisonOptions
    )
}

public func == <Entity, Value: Equatable>(left: KeyPath<Entity, Value?>, right: Value?) -> ComparisonPredicate<Entity> {
    ComparisonPredicate<Entity>(
        leftExpression: NSExpression(forKeyPath: left),
        rightExpression: NSExpression(forConstantValue: right),
        modifier: .direct,
        type: .equalTo,
        options: right?.comparisonOptions ?? []
    )
}

// .notEqualTo
public func != <Entity, Value: Equatable>(left: KeyPath<Entity, Value>, right: Value) -> ComparisonPredicate<Entity> {
    ComparisonPredicate<Entity>(
        leftExpression: NSExpression(forKeyPath: left),
        rightExpression: NSExpression(forConstantValue: right),
        modifier: .direct,
        type: .notEqualTo,
        options: right.comparisonOptions
    )
}

public func != <Entity, Value: Equatable>(left: KeyPath<Entity, Value?>, right: Value?) -> ComparisonPredicate<Entity> {
    ComparisonPredicate<Entity>(
        leftExpression: NSExpression(forKeyPath: left),
        rightExpression: NSExpression(forConstantValue: right),
        modifier: .direct,
        type: .notEqualTo,
        options: right?.comparisonOptions ?? []
    )
}

// .lessThan
public func < <Entity, Value: Comparable>(left: KeyPath<Entity, Value>, right: Value) -> ComparisonPredicate<Entity> {
    ComparisonPredicate<Entity>(
        leftExpression: NSExpression(forKeyPath: left),
        rightExpression: NSExpression(forConstantValue: right),
        modifier: .direct,
        type: .lessThan,
        options: right.comparisonOptions
    )
}

public func < <Entity, Value: Comparable>(left: KeyPath<Entity, Value?>, right: Value?) -> ComparisonPredicate<Entity> {
    ComparisonPredicate<Entity>(
        leftExpression: NSExpression(forKeyPath: left),
        rightExpression: NSExpression(forConstantValue: right),
        modifier: .direct,
        type: .lessThan,
        options: right?.comparisonOptions ?? []
    )
}

// .lessThanOrEqualTo
public func <= <Entity, Value: Comparable>(left: KeyPath<Entity, Value>, right: Value) -> ComparisonPredicate<Entity> {
    ComparisonPredicate<Entity>(
        leftExpression: NSExpression(forKeyPath: left),
        rightExpression: NSExpression(forConstantValue: right),
        modifier: .direct,
        type: .lessThanOrEqualTo,
        options: right.comparisonOptions
    )
}

public func <= <Entity, Value: Comparable>(left: KeyPath<Entity, Value?>, right: Value?) -> ComparisonPredicate<Entity> {
    ComparisonPredicate<Entity>(
        leftExpression: NSExpression(forKeyPath: left),
        rightExpression: NSExpression(forConstantValue: right),
        modifier: .direct,
        type: .lessThanOrEqualTo,
        options: right?.comparisonOptions ?? []
    )
}

// .greaterThan
public func > <Entity, Value: Comparable>(left: KeyPath<Entity, Value>, right: Value) -> ComparisonPredicate<Entity> {
    ComparisonPredicate<Entity>(
        leftExpression: NSExpression(forKeyPath: left),
        rightExpression: NSExpression(forConstantValue: right),
        modifier: .direct,
        type: .greaterThan,
        options: right.comparisonOptions
    )
}

public func > <Entity, Value: Comparable>(left: KeyPath<Entity, Value?>, right: Value?) -> ComparisonPredicate<Entity> {
    ComparisonPredicate<Entity>(
        leftExpression: NSExpression(forKeyPath: left),
        rightExpression: NSExpression(forConstantValue: right),
        modifier: .direct,
        type: .greaterThan,
        options: right?.comparisonOptions ?? []
    )
}

// .greaterThanOrEqualTo
public func >= <Entity, Value: Comparable>(left: KeyPath<Entity, Value>, right: Value) -> ComparisonPredicate<Entity> {
    ComparisonPredicate<Entity>(
        leftExpression: NSExpression(forKeyPath: left),
        rightExpression: NSExpression(forConstantValue: right),
        modifier: .direct,
        type: .greaterThanOrEqualTo,
        options: right.comparisonOptions
    )
}

public func >= <Entity, Value: Comparable>(left: KeyPath<Entity, Value?>, right: Value?) -> ComparisonPredicate<Entity> {
    ComparisonPredicate<Entity>(
        leftExpression: NSExpression(forKeyPath: left),
        rightExpression: NSExpression(forConstantValue: right),
        modifier: .direct,
        type: .greaterThanOrEqualTo,
        options: right?.comparisonOptions ?? []
    )
}

// .like
infix operator ~: ComparisonPrecedence

public func ~ <Entity, Value: Comparable>(left: KeyPath<Entity, Value>, right: Value) -> ComparisonPredicate<Entity> {
    ComparisonPredicate<Entity>(
        leftExpression: NSExpression(forKeyPath: left),
        rightExpression: NSExpression(forConstantValue: right),
        modifier: .direct,
        type: .like,
        options: right.comparisonOptions
    )
}

public func ~ <Entity, Value: Comparable>(left: KeyPath<Entity, Value?>, right: Value?) -> ComparisonPredicate<Entity> {
    ComparisonPredicate<Entity>(
        leftExpression: NSExpression(forKeyPath: left),
        rightExpression: NSExpression(forConstantValue: right),
        modifier: .direct,
        type: .like,
        options: right?.comparisonOptions ?? []
    )
}

// .contains
infix operator ^^: ComparisonPrecedence
infix operator !^ : ComparisonPrecedence

public func ^^ <Entity, Value: Comparable>(left: KeyPath<Entity, Value>, right: Value) -> ComparisonPredicate<Entity> {
    ComparisonPredicate<Entity>(
        leftExpression: NSExpression(forKeyPath: left),
        rightExpression: NSExpression(forConstantValue: right),
        modifier: .direct,
        type: .contains,
        options: right.comparisonOptions
    )
}

public func ^^ <Entity, Value: Comparable>(left: KeyPath<Entity, Value?>, right: Value?) -> ComparisonPredicate<Entity> {
    ComparisonPredicate<Entity>(
        leftExpression: NSExpression(forKeyPath: left),
        rightExpression: NSExpression(forConstantValue: right),
        modifier: .direct,
        type: .contains,
        options: right?.comparisonOptions ?? []
    )
}

public func !^ <Entity, Value: StringProtocol & CVarArg>(left: KeyPath<Entity, Value>, right: Value) -> Predicate<Entity> {
    Predicate<Entity>(format: "NOT \(left.pathString) contains[cd] %@", right)
}

public func !^ <Entity, Value: StringProtocol & CVarArg>(left: KeyPath<Entity, Value?>, right: Value) -> Predicate<Entity> {
    Predicate<Entity>(format: "NOT \(left.pathString) contains[cd] %@", right)
}

// .matches
// .beginsWith
// .endsWith
// .`in`
// .between

// MARK: -

extension Equatable {
    fileprivate var comparisonOptions: NSComparisonPredicate.Options {
        if self is String || self is NSString {
            return [.caseInsensitive, .diacriticInsensitive]
        }
        return []
    }
}
