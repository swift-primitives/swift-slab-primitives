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
// The package umbrella ([MOD-005]): consumers import `Slab_Primitives` and get the
// sparse stable-index slab ADT — the bound-free carrier `__Slab<S>` + the canonical
// front door `Slab<E>` (the ADT-tower W2 shape) + the `peek` non-destructive read
// (this module).
//
// The inline (in-footprint, fixed-capacity) allocation variant is the `Slab<E>.Inline<n>`
// front door — un-parked at W3 from the former `Slab.Static` (§9.3 W3 row, adt-tower.md:1376).
// Per [DS-027].1 it lives in its OWN lean product (`Slab Inline Primitive`) and is NOT
// re-exported here — inline-free consumers stay lean; consumers pull it explicitly.

@_exported public import Sequence_Primitives
@_exported public import Slab_Primitive
