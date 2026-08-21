import Bit_Primitives
public import Buffer_Slab_Primitives
public import Index_Primitives
public import Memory_Allocator_Primitive
public import Memory_Heap_Primitives
public import Slab_Primitive
public import Storage_Contiguous_Primitives

extension __Slab where S: ~Copyable {

    @inlinable
    public func peek<E>(at index: Index<E>) -> E?
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded {
        let slot = index.retag(Bit.self)
        guard column.isOccupied(at: slot) else { return nil }
        return column.peek(at: slot)
    }
}
