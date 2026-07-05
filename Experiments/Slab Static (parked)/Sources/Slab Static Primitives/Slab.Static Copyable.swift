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

import Bit_Primitives
public import Buffer_Slab_Inline_Primitives
public import Finite_Bounded_Primitives
import Index_Primitives
public import Slab_Static_Primitive

// MARK: - Non-Destructive Read

extension Slab.Static where Element: Copyable {
    /// Returns the element at the specified slot without removing it.
    @inlinable
    public func peek(at index: Index<Element>.Bounded<wordCount>) -> Element? {
        let slot = index.retag(Bit.self)
        guard _buffer.isOccupied(at: slot) else { return nil }
        return _buffer.peek(at: slot)
    }
}
