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

import Index_Primitives
public import Slab_Primitive

// MARK: - Non-Destructive Read

extension Slab.Indexed where Element: Copyable, Tag: ~Copyable {
    /// Returns the element at the specified slot without removing it.
    @inlinable
    public func peek(at index: Index<Tag>) -> Element? {
        _base.peek(at: index.retag(Element.self))
    }
}
