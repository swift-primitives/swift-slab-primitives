@_documentation(visibility: public)
@frozen
public struct __Slab<S: ~Copyable>: ~Copyable {

    @usableFromInline
    package var column: S

    @inlinable
    public init(column: consuming S) { self.column = column }
}

extension __Slab where S: ~Copyable {

    @inlinable
    public consuming func take() -> S { column }
}

extension __Slab: Copyable where S: Copyable {}
extension __Slab: Sendable where S: Sendable & ~Copyable {}
