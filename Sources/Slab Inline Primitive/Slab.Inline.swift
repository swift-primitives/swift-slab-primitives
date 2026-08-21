public import Buffer_Primitive
public import Buffer_Protocol_Primitives
public import Buffer_Slab_Inline_Primitives
public import Memory_Allocator_Primitive
public import Memory_Heap_Primitives
public import Slab_Primitive
public import Storage_Contiguous_Primitives

extension __Slab where S: ~Copyable, S: Buffer.`Protocol` {

    public typealias Inline<let n: Int> =
        __Slab<Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<S.Element>>.Slab.Inline<n>>
}
