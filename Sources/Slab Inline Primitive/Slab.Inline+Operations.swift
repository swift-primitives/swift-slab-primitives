import Bit_Primitives
public import Buffer_Primitive
public import Buffer_Slab_Inline_Primitives
public import Finite_Bounded_Primitives
public import Index_Primitives
public import Memory_Allocator_Primitive
public import Memory_Heap_Primitives
public import Slab_Primitive
public import Storage_Contiguous_Primitives

extension __Slab where S: ~Copyable {

    @inlinable
    public init<E: ~Copyable, let n: Int>()
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Inline<n> {
        self.init(
            column: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Inline()
        )
    }
}

extension __Slab where S: ~Copyable {

    @inlinable
    public func isFull<E: ~Copyable, let n: Int>() -> Bool
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Inline<n> {
        column.isFull
    }

    @inlinable
    public func isOccupied<E: ~Copyable, let n: Int>(at index: Index<E>.Bounded<n>) -> Bool
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Inline<n> {
        column.isOccupied(at: index.retag(Bit.self))
    }

    @inlinable
    public func firstVacant<E: ~Copyable, let n: Int>() -> Index<E>.Bounded<n>?
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Inline<n> {
        column.firstVacant()?.retag(E.self)
    }
}

extension __Slab where S: ~Copyable {

    @inlinable
    public mutating func insert<E: ~Copyable, let n: Int>(
        _ element: consuming E,
        at index: Index<E>.Bounded<n>
    ) throws(Error)
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Inline<n> {
        let slot = index.retag(Bit.self)
        guard !column.isOccupied(at: slot) else { throw .occupied }
        column.insert(consume element, at: slot)
    }

    @inlinable
    public mutating func insert<E: ~Copyable, let n: Int>(
        _ element: consuming E,
        __unchecked index: Index<E>.Bounded<n>
    ) where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Inline<n> {
        column.insert(consume element, at: index.retag(Bit.self))
    }

    @inlinable
    public mutating func remove<E: ~Copyable, let n: Int>(
        at index: Index<E>.Bounded<n>
    ) throws(Error) -> E
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Inline<n> {
        let slot = index.retag(Bit.self)
        guard column.isOccupied(at: slot) else { throw .vacant }
        return column.remove(at: slot)
    }

    @inlinable
    public mutating func remove<E: ~Copyable, let n: Int>(
        __unchecked index: Index<E>.Bounded<n>
    ) -> E where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Inline<n> {
        column.remove(at: index.retag(Bit.self))
    }
}

extension __Slab where S: ~Copyable {

    @discardableResult
    @inlinable
    public mutating func insert<E: ~Copyable, let n: Int>(
        _ element: consuming E
    ) throws(Error) -> Index<E>.Bounded<n>
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Inline<n> {
        guard let slot: Index<E>.Bounded<n> = firstVacant() else { throw .full }
        column.insert(consume element, at: slot.retag(Bit.self))
        return slot
    }

    @inlinable
    public mutating func update<E: ~Copyable, let n: Int>(
        at index: Index<E>.Bounded<n>,
        with element: consuming E
    ) throws(Error) -> E
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Inline<n> {
        let slot = index.retag(Bit.self)
        guard column.isOccupied(at: slot) else { throw .vacant }
        return column.update(at: slot, with: consume element)
    }

    @inlinable
    public mutating func removeAll<E: ~Copyable, let n: Int>()
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Inline<n> {
        column.removeAll()
    }
}

extension __Slab where S: ~Copyable {

    @inlinable
    public func peek<E, let n: Int>(at index: Index<E>.Bounded<n>) -> E?
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Inline<n> {
        let slot = index.retag(Bit.self)
        guard column.isOccupied(at: slot) else { return nil }
        return column.peek(at: slot)
    }
}
