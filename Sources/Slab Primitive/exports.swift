// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-primitives open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

// exports.swift
// Re-exports for Slab Primitive — the ADT-tower carrier module.
// Declares the bound-free carrier `__Slab<S: ~Copyable>` (Slab.swift) + the canonical
// front-door alias `Slab<E>` (Slab.FrontDoor.swift, [DS-028]) + `Slab.Error`;
// re-exports the `Buffer.Protocol` seam + the default Slab-buffer / heap column
// vocabulary the front door and the column-pinned ops compose.

@_exported public import Buffer_Protocol_Primitives
@_exported public import Buffer_Slab_Primitives
@_exported public import Storage_Contiguous_Primitives
@_exported public import Memory_Heap_Primitives
@_exported public import Memory_Allocator_Primitive
@_exported public import Index_Primitives
