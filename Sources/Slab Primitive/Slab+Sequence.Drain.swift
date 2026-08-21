public import Buffer_Slab_Primitives
public import Memory_Allocator_Primitive
public import Memory_Heap_Primitives
public import Storage_Contiguous_Primitives

extension __Slab where S: ~Copyable {

    @inlinable
    public mutating func drain<E: ~Copyable>(_ body: (consuming E) -> Void)
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded {
        column.drain(body)
    }
}
