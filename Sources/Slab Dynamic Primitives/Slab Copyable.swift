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

public import Slab_Primitives_Core
import Index_Primitives
import Bit_Primitives

// MARK: - Non-Destructive Read

extension Slab where Element: Copyable {
    /// Returns the element at the specified slot without removing it.
    @inlinable
    public func peek(at index: Index<Element>) -> Element? {
        let slot = index.retag(Bit.self)
        guard _buffer.isOccupied(at: slot) else { return nil }
        return _buffer.peek(at: slot)
    }
}
