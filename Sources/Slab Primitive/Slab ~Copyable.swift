import Bit_Primitives
public import Buffer_Protocol_Primitives
public import Buffer_Slab_Primitives
public import Index_Primitives
public import Memory_Allocator_Primitive
public import Memory_Heap_Primitives
public import Storage_Contiguous_Primitives

extension __Slab where S: ~Copyable, S: Buffer.`Protocol` {

    @inlinable
    public var count: Index<S.Element>.Count { column.count }

    @inlinable
    public var occupancy: Index<S.Element>.Count { column.count }

    @inlinable
    public var isEmpty: Bool { column.isEmpty }
}

extension __Slab where S: ~Copyable {

    @inlinable
    public init<E: ~Copyable>()
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded {
        self.init(
            column: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded(
                minimumCapacity: .zero
            )
        )
    }

    @inlinable
    public init<E: ~Copyable>(minimumCapacity: Index<E>.Count)
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded {
        self.init(
            column: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded(
                minimumCapacity: minimumCapacity
            )
        )
    }
}

extension __Slab where S: ~Copyable {

    @inlinable
    public func isFull<E: ~Copyable>() -> Bool
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded {
        column.isFull
    }

    @inlinable
    public func isOccupied<E: ~Copyable>(at index: Index<E>) -> Bool
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded {
        column.isOccupied(at: index.retag(Bit.self))
    }

    @inlinable
    public func firstVacant<E: ~Copyable>() -> Index<E>?
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded {
        column.firstVacant()?.retag(E.self)
    }
}

extension __Slab where S: ~Copyable {

    @inlinable
    public mutating func insert<E: ~Copyable>(
        _ element: consuming E,
        at index: Index<E>
    ) throws(Error)
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded {
        let slot = index.retag(Bit.self)
        guard !column.isOccupied(at: slot) else {
            throw .occupied
        }
        column.insert(consume element, at: slot)
    }

    @inlinable
    public mutating func insert<E: ~Copyable>(
        _ element: consuming E,
        __unchecked index: Index<E>
    ) where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded {
        column.insert(consume element, at: index.retag(Bit.self))
    }

    @inlinable
    public mutating func remove<E: ~Copyable>(
        at index: Index<E>
    ) throws(Error) -> E
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded {
        let slot = index.retag(Bit.self)
        guard column.isOccupied(at: slot) else {
            throw .vacant
        }
        return column.remove(at: slot)
    }

    @inlinable
    public mutating func remove<E: ~Copyable>(
        __unchecked index: Index<E>
    ) -> E where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded {
        column.remove(at: index.retag(Bit.self))
    }
}

extension __Slab where S: ~Copyable {

    @discardableResult
    @inlinable
    public mutating func insert<E: ~Copyable>(
        _ element: consuming E
    ) throws(Error) -> Index<E>
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded {
        guard let slot: Index<E> = firstVacant() else {
            throw .full
        }
        column.insert(consume element, at: slot.retag(Bit.self))
        return slot
    }

    @inlinable
    public mutating func update<E: ~Copyable>(
        at index: Index<E>,
        with element: consuming E
    ) throws(Error) -> E
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded {
        let slot = index.retag(Bit.self)
        guard column.isOccupied(at: slot) else {
            throw .vacant
        }
        return column.update(at: slot, with: consume element)
    }

    @inlinable
    public mutating func removeAll<E: ~Copyable>()
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded {
        column.removeAll()
    }
}
