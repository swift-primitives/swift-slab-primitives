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
// The `Slab.Static` inline variant is PARKED (see "Experiments/Slab Static (parked)/")
// as a future `Slab<E>.Inline<n>` front door for the W3 inline-front-door round
// (§9.3 W3 row, adt-tower.md:1376) — retained in-tree, out of the build graph.

@_exported public import Slab_Primitive
@_exported public import Sequence_Primitives
