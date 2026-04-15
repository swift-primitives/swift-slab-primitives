# Slab Operations Audit

<!--
---
version: 1.0.0
last_updated: 2026-02-16
status: RECOMMENDATION
tier: 1
---
-->

## Context

Proactive audit of swift-slab-primitives per [RES-012] Discovery.
**Scope**: Package-specific (swift-slab-primitives).

The package provides `Slab<Element: ~Copyable>` — a fixed-capacity, heap-backed typed slot storage with bitmap occupancy tracking. It wraps `Buffer<Element>.Slab.Bounded` (heap) and `Buffer<Element>.Slab.Inline` (stack) from the buffer layer.

Three variants exist:
- **Slab** (Dynamic) — heap-backed, runtime capacity
- **Slab.Static** — stack-allocated, compile-time capacity via `wordCount`
- **Slab.Indexed** — phantom-typed wrapper providing `Index<Tag>` instead of `Index<Element>`

The package is split across four modules:
- `Slab Primitives Core` — type declarations and `~Copyable` operations
- `Slab Dynamic Primitives` — Copyable extensions for Slab and Slab.Indexed
- `Slab Static Primitives` — Copyable extensions for Slab.Static
- `Slab Primitives` — umbrella re-export

## Question

Does swift-slab-primitives provide the canonical operations expected of the Slab Allocator ADT?

---

## Canonical Operations (ADT Reference)

| Operation | Expected Complexity | Description |
|-----------|-------------------|-------------|
| allocate() -> handle | O(1) amortized | Get a free slot, return handle |
| free(handle) | O(1) | Return slot to free list |
| get(handle) | O(1) | Read element at handle |
| get_mut(handle) | O(1) | Mutate element at handle |
| contains(handle) / is_alive(handle) | O(1) | Check if handle is valid |
| iterate_live() | O(n) or O(live) | Visit all occupied slots |
| count/size | O(1) | Number of live elements |
| isEmpty | O(1) | Empty check |
| capacity | O(1) | Total slot count |

---

## Current Operations Inventory

### Core (`Slab<Element: ~Copyable>`)

**File**: `Sources/Slab Primitives Core/Slab.swift` (type declaration)

| Declaration | Kind | Signature |
|-------------|------|-----------|
| `init()` | Initializer | `public init()` |
| `init(minimumCapacity:)` | Initializer | `public init(minimumCapacity: Index<Element>.Count)` |
| `Slab.Static<let wordCount: Int>` | Nested type | `public struct Static<let wordCount: Int>: ~Copyable` |
| `Slab.Indexed<Tag: ~Copyable>` | Nested type | `public struct Indexed<Tag: ~Copyable>: ~Copyable` |
| `Slab.Error` | Nested enum | `public enum Error: Swift.Error, Sendable, Equatable` — cases: `.full`, `.vacant`, `.occupied` |
| `Sendable` | Conditional conformance | `where Element: Sendable` (all three types) |

**File**: `Sources/Slab Primitives Core/Slab ~Copyable.swift` (operations on `Slab where Element: ~Copyable`)

| Declaration | Kind | Signature | ADT Mapping | Complexity |
|-------------|------|-----------|-------------|------------|
| `occupancy` | Property | `public var occupancy: Index<Element>.Count` | count/size | O(1) via bitmap popcount |
| `isEmpty` | Property | `public var isEmpty: Bool` | isEmpty | O(1) |
| `isFull` | Property | `public var isFull: Bool` | (beyond canonical) | O(1) |
| `isOccupied(at:)` | Method | `public func isOccupied(at index: Index<Element>) -> Bool` | contains/is_alive | O(1) |
| `firstVacant()` | Method | `public func firstVacant() -> Index<Element>?` | (internal to allocate) | O(word) |
| `insert(_:at:)` | Method | `public mutating func insert(_ element: consuming Element, at index: Index<Element>) throws(Error)` | (consumer-chosen insert) | O(1) |
| `insert(_:__unchecked:)` | Method | `public mutating func insert(_ element: consuming Element, __unchecked index: Index<Element>)` | (unchecked variant) | O(1) |
| `remove(at:)` | Method | `public mutating func remove(at index: Index<Element>) throws(Error) -> Element` | free(handle) | O(1) |
| `remove(__unchecked:)` | Method | `public mutating func remove(__unchecked index: Index<Element>) -> Element` | (unchecked variant) | O(1) |
| `insert(_:)` | Method | `public mutating func insert(_ element: consuming Element) throws(Error) -> Index<Element>` | allocate() -> handle | O(1) amortized |
| `update(at:with:)` | Method | `public mutating func update(at index: Index<Element>, with element: consuming Element) throws(Error) -> Element` | (replace operation) | O(1) |
| `removeAll()` | Method | `public mutating func removeAll()` | (bulk clear) | O(n) |
| `drain` | Property | `public var drain: Property<Sequence.Drain, Self>.View` | iterate_live (consuming) | O(live) |
| `drain(_:)` | Method (protocol) | `public mutating func drain(_ body: (consuming Element) -> Void)` | iterate_live (consuming) | O(live) |
| `Sequence.Drain.Protocol` | Conformance | `extension Slab: Sequence.Drain.Protocol` | — | — |

### Variant: Dynamic (`Slab` / `Slab.Indexed` — Copyable extensions)

**File**: `Sources/Slab Dynamic Primitives/Slab Copyable.swift`

| Declaration | Kind | Signature | ADT Mapping | Complexity |
|-------------|------|-----------|-------------|------------|
| `peek(at:)` | Method | `public func peek(at index: Index<Element>) -> Element?` | get(handle) | O(1) |

**File**: `Sources/Slab Dynamic Primitives/Slab.Indexed Copyable.swift`

| Declaration | Kind | Signature | ADT Mapping | Complexity |
|-------------|------|-----------|-------------|------------|
| `peek(at:)` | Method | `public func peek(at index: Index<Tag>) -> Element?` | get(handle) | O(1) |
| `drain` | Property | `public var drain: Property<Sequence.Drain, Self>.View` | iterate_live (consuming) | O(live) |
| `drain(_:)` | Method (protocol) | `public mutating func drain(_ body: (consuming Element) -> Void)` | iterate_live (consuming) | O(live) |
| `Sequence.Drain.Protocol` | Conformance | `extension Slab.Indexed: Sequence.Drain.Protocol` | — | — |

### Variant: Static (`Slab.Static<let wordCount: Int>`)

**File**: `Sources/Slab Primitives Core/Slab.Static ~Copyable.swift` (~Copyable operations)

| Declaration | Kind | Signature | ADT Mapping | Complexity |
|-------------|------|-----------|-------------|------------|
| `occupancy` | Property | `public var occupancy: Index<Element>.Count` | count/size | O(1) |
| `isEmpty` | Property | `public var isEmpty: Bool` | isEmpty | O(1) |
| `isFull` | Property | `public var isFull: Bool` | (beyond canonical) | O(1) |
| `isOccupied(at:)` | Method | `public func isOccupied(at index: Index<Element>.Bounded<wordCount>) -> Bool` | contains/is_alive | O(1) |
| `firstVacant()` | Method | `public func firstVacant() -> Index<Element>.Bounded<wordCount>?` | (internal to allocate) | O(word) |
| `insert(_:at:)` | Method | `public mutating func insert(_ element: consuming Element, at index: Index<Element>.Bounded<wordCount>) throws(Error)` | (consumer-chosen insert) | O(1) |
| `insert(_:__unchecked:)` | Method | `public mutating func insert(_ element: consuming Element, __unchecked index: Index<Element>.Bounded<wordCount>)` | (unchecked variant) | O(1) |
| `remove(at:)` | Method | `public mutating func remove(at index: Index<Element>.Bounded<wordCount>) throws(Error) -> Element` | free(handle) | O(1) |
| `remove(__unchecked:)` | Method | `public mutating func remove(__unchecked index: Index<Element>.Bounded<wordCount>) -> Element` | (unchecked variant) | O(1) |
| `insert(_:)` | Method | `public mutating func insert(_ element: consuming Element) throws(Error) -> Index<Element>.Bounded<wordCount>` | allocate() -> handle | O(1) amortized |
| `update(at:with:)` | Method | `public mutating func update(at index: Index<Element>.Bounded<wordCount>, with element: consuming Element) throws(Error) -> Element` | (replace operation) | O(1) |
| `removeAll()` | Method | `public mutating func removeAll()` | (bulk clear) | O(n) |

**File**: `Sources/Slab Static Primitives/Slab.Static Copyable.swift` (Copyable extensions)

| Declaration | Kind | Signature | ADT Mapping | Complexity |
|-------------|------|-----------|-------------|------------|
| `peek(at:)` | Method | `public func peek(at index: Index<Element>.Bounded<wordCount>) -> Element?` | get(handle) | O(1) |
| `drain` | Property | `public var drain: Property<Sequence.Drain, Self>.View` | iterate_live (consuming) | O(live) |
| `drain(_:)` | Method (protocol) | `public mutating func drain(_ body: (consuming Element) -> Void)` | iterate_live (consuming) | O(live) |
| `Sequence.Drain.Protocol` | Conformance | `extension Slab.Static: Sequence.Drain.Protocol` | — | — |

### Variant: Indexed (`Slab.Indexed<Tag: ~Copyable>`)

**File**: `Sources/Slab Primitives Core/Slab.Indexed ~Copyable.swift` (~Copyable operations)

| Declaration | Kind | Signature | ADT Mapping | Complexity |
|-------------|------|-----------|-------------|------------|
| `occupancy` | Property | `public var occupancy: Index<Tag>.Count` | count/size | O(1) |
| `isEmpty` | Property | `public var isEmpty: Bool` | isEmpty | O(1) |
| `isFull` | Property | `public var isFull: Bool` | (beyond canonical) | O(1) |
| `isOccupied(at:)` | Method | `public func isOccupied(at index: Index<Tag>) -> Bool` | contains/is_alive | O(1) |
| `firstVacant()` | Method | `public func firstVacant() -> Index<Tag>?` | (internal to allocate) | O(word) |
| `insert(_:at:)` | Method | `public mutating func insert(_ element: consuming Element, at index: Index<Tag>) throws(Slab<Element>.Error)` | (consumer-chosen insert) | O(1) |
| `insert(_:__unchecked:)` | Method | `public mutating func insert(_ element: consuming Element, __unchecked index: Index<Tag>)` | (unchecked variant) | O(1) |
| `remove(at:)` | Method | `public mutating func remove(at index: Index<Tag>) throws(Slab<Element>.Error) -> Element` | free(handle) | O(1) |
| `remove(__unchecked:)` | Method | `public mutating func remove(__unchecked index: Index<Tag>) -> Element` | (unchecked variant) | O(1) |
| `insert(_:)` | Method | `public mutating func insert(_ element: consuming Element) throws(Slab<Element>.Error) -> Index<Tag>` | allocate() -> handle | O(1) amortized |
| `update(at:with:)` | Method | `public mutating func update(at index: Index<Tag>, with element: consuming Element) throws(Slab<Element>.Error) -> Element` | (replace operation) | O(1) |
| `removeAll()` | Method | `public mutating func removeAll()` | (bulk clear) | O(n) |

(Copyable extensions — `peek(at:)`, `drain`, `Sequence.Drain.Protocol` — listed under Dynamic above.)

### Additional Operations (beyond canonical)

| Operation | Present On | Description |
|-----------|-----------|-------------|
| `isFull` | All variants | Inverse of vacancy check — useful for pre-allocate guard |
| `firstVacant()` | All variants | Exposed publicly, though logically internal to allocate |
| `insert(_:at:)` (consumer-chosen) | All variants | Not in canonical ADT — allows caller to pick slot |
| `insert(_:__unchecked:)` | All variants | Unsafe fast-path skipping occupancy check |
| `remove(__unchecked:)` | All variants | Unsafe fast-path skipping occupancy check |
| `update(at:with:)` | All variants | Atomic swap — not in basic canonical set but common |
| `removeAll()` | All variants | Bulk clear — not in basic canonical set but standard |
| `drain` / `Sequence.Drain.Protocol` | All variants (Copyable-gated for nested types) | Consuming iteration — goes beyond simple iterate_live |

### Module Re-Exports

**File**: `Sources/Slab Primitives Core/exports.swift`
```swift
@_exported public import Index_Primitives
@_exported public import Finite_Primitives
@_exported public import Property_Primitives
@_exported public import Buffer_Slab_Primitives
```

**File**: `Sources/Slab Dynamic Primitives/exports.swift`
```swift
@_exported public import Slab_Primitives_Core
@_exported public import Collection_Primitives
@_exported public import Sequence_Primitives
```

**File**: `Sources/Slab Static Primitives/exports.swift`
```swift
@_exported public import Slab_Primitives_Core
@_exported public import Sequence_Primitives
```

**File**: `Sources/Slab Primitives/exports.swift`
```swift
@_exported public import Slab_Primitives_Core
@_exported public import Slab_Dynamic_Primitives
@_exported public import Slab_Static_Primitives
```

---

## Gap Analysis

### Present and Correctly Mapped

| Canonical Operation | Implementation | Notes |
|-------------------|----------------|-------|
| **allocate() -> handle** | `insert(_:) throws(Error) -> Index<Element>` | Composed from `firstVacant()` + `insert(_:at:)`. Returns typed handle. Throws `.full` on exhaustion. Present on all three variants. |
| **free(handle)** | `remove(at:) throws(Error) -> Element` | Returns the freed element (consuming semantics). Throws `.vacant` on double-free. Present on all three variants. |
| **get(handle)** | `peek(at:) -> Element?` | Non-destructive read. Returns `nil` for vacant slots (no throw). **Requires `Element: Copyable`** — necessarily gated because non-copyable elements cannot be read without consuming. Present on all three variants. |
| **contains(handle) / is_alive(handle)** | `isOccupied(at:) -> Bool` | O(1) bitmap test. Works for `~Copyable` elements. Present on all three variants. |
| **iterate_live()** | `drain(_:)` / `Sequence.Drain.Protocol` | Consuming iteration over occupied slots. Note: this is a *consuming* iteration, not a borrowing one. Drain conformance is Copyable-gated for `Slab.Static` and `Slab.Indexed` due to constraint poisoning from `Sequence.Drain.Protocol`'s associated type. |
| **count/size** | `occupancy: Index<Element>.Count` | O(1) via bitmap popcount. Named `occupancy` (domain-appropriate for slab semantics). Present on all three variants. |
| **isEmpty** | `isEmpty: Bool` | O(1). Present on all three variants. |

### Missing — Should Add (Primitives Layer)

| Canonical Operation | Gap | Recommendation | Priority |
|-------------------|------|----------------|----------|
| **capacity** | No `capacity` property on any variant. | Add `public var capacity: Index<Element>.Count` to all three variants. The information exists in the bitmap (`bitmap.capacity.maximum`) but is not surfaced through the slab layer. Sibling packages (Stack, Queue, etc.) all expose `capacity`. | **HIGH** — O(1) query that consumers need to reason about fullness ratios, pre-allocation, and diagnostics. |
| **get_mut(handle)** | No in-place mutation access. `update(at:with:)` does an atomic swap, but there is no way to mutate an element in-place without removing and re-inserting it. | Add a `mutate(at:_:)` or subscript-based access. Two options: (a) `public mutating func withElement<R>(at index: Index<Element>, _ body: (inout Element) throws(E) -> R) throws(E) -> R` or (b) a subscript returning a mutable reference. Option (a) is safer for `~Copyable` elements. | **MEDIUM** — `update(at:with:)` covers the common case, but in-place mutation avoids the temporary for expensive types. |
| **iterate_live() (non-consuming)** | `drain` is consuming — it removes elements during iteration. There is no way to visit all occupied slots without destroying them. For `Copyable` elements, `peek` exists but there is no bulk non-consuming iteration. | For `Copyable` elements: add `forEach(_:)` or `Sequence` conformance. For `~Copyable` elements: add `borrowEach(_:)` using borrowing closures when Swift supports them, or `withElement(at:)` per slot. | **MEDIUM** — Consuming-only iteration is correct for `~Copyable` but limiting for `Copyable` elements. |

### Missing — Intentionally Absent (Higher Layer)

| Canonical Operation | Reason for Absence |
|-------------------|-------------------|
| **Generation counters (ABA protection)** | The canonical slab allocator ADT often includes generation counters to detect use-after-free via stale handles. This is intentionally absent from primitives. Generation-tagged handles are a composed concern belonging to Layer 3 (Foundations) or Layer 4 (Components), where a `Slab.Generational` wrapper could pair `Index<Tag>` with a generation counter. The primitives layer provides the raw slot storage; consumers at higher layers add safety policies. |
| **Growable slab** | `Buffer<Element>.Slab` (the growable variant) exists at the buffer layer but is not exposed through slab-primitives, which only wraps `Bounded` (fixed-capacity) and `Inline` (compile-time capacity). A growable slab would be a composed concern for Foundations. |
| **Iterator / Sequence conformance** | Full `Sequence` conformance requires `Element: Copyable` (due to `associatedtype Element` in the standard library protocol). This is correctly deferred rather than provided with a restrictive constraint. The `drain` pattern is the `~Copyable`-safe alternative. Non-consuming iteration for `Copyable` elements could be added (see above). |
| **Subscript access** | Subscript-based `slab[handle]` access is a convenience that composes `isOccupied` + `peek`/mutation. It belongs at a higher layer where safety semantics (generation checks, bounds validation) can be layered on. |

---

## Summary of Findings

### Coverage Score: 7 of 9 canonical operations present

| Status | Count | Operations |
|--------|-------|------------|
| Present | 7 | allocate, free, get, contains, iterate_live (consuming), count, isEmpty |
| Missing (should add) | 2 | capacity, get_mut |
| Intentionally absent | — | generation counters, growable variant, Sequence conformance |

### Observations

1. **`occupancy` vs `count`**: The package uses `occupancy` rather than `count`. This is correct — `count` implies sequential/contiguous storage (arrays, lists), while `occupancy` reflects bitmap-tracked slot usage. This is a good domain-specific naming choice.

2. **`insert`/`remove` vs `allocate`/`free`**: The package uses `insert`/`remove` rather than `allocate`/`free`. This is also correct — `allocate`/`free` implies raw memory allocation, while `insert`/`remove` reflects typed value semantics. The slab stores *values*, not raw memory. The naming matches sibling data structure packages.

3. **Consumer-chosen insertion**: The `insert(_:at:)` overload (consumer picks the slot) is a deliberate design choice not found in most slab allocator ADT descriptions. This supports use cases where the caller manages slot assignment externally (e.g., ECS entity IDs, connection table indices).

4. **Unchecked variants**: The `__unchecked` parameter label pattern provides unsafe fast-paths. This is appropriate for the primitives layer.

5. **Typed throws**: All fallible operations use typed throws (`throws(Error)` or `throws(Slab<Element>.Error)`), satisfying [API-ERR-001].

6. **Drain constraint poisoning**: The `Sequence.Drain.Protocol` conformance for `Slab.Static` and `Slab.Indexed` must be in the Copyable modules due to associated type constraint poisoning. This is correctly handled.

---

## Recommendations

### R1: Add `capacity` property (HIGH priority)

Add to all three variants:

```swift
// Slab ~Copyable.swift
extension Slab where Element: ~Copyable {
    public var capacity: Index<Element>.Count {
        _buffer.header.bitmap.capacity.maximum.retag(Element.self)
    }
}

// Slab.Static ~Copyable.swift
extension Slab.Static where Element: ~Copyable {
    public var capacity: Index<Element>.Count {
        _buffer.header.bitmap.capacity.maximum.retag(Element.self)
    }
}

// Slab.Indexed ~Copyable.swift
extension Slab.Indexed where Element: ~Copyable, Tag: ~Copyable {
    public var capacity: Index<Tag>.Count {
        _base.capacity.retag(Tag.self)
    }
}
```

The exact path through the buffer header depends on what `Buffer.Slab.Bounded` exposes — if the header's bitmap capacity is not already surfaced, a `capacity` property should be added to the buffer type first.

### R2: Add in-place mutation access (MEDIUM priority)

```swift
// Slab ~Copyable.swift
extension Slab where Element: ~Copyable {
    @inlinable
    public mutating func withElement<E: Error, R: ~Copyable>(
        at index: Index<Element>,
        _ body: (inout Element) throws(E) -> R
    ) throws(E) -> R {
        // ... bounds check + delegate to buffer
    }
}
```

This requires buffer-layer support for in-place access via pointer arithmetic. Verify that `Buffer<Element>.Slab.Bounded` can provide `withUnsafeMutablePointer(at:)` or equivalent.

### R3: Add non-consuming iteration for Copyable elements (MEDIUM priority)

```swift
// Slab Copyable.swift (in Slab Dynamic Primitives module)
extension Slab where Element: Copyable {
    @inlinable
    public func forEach(_ body: (Index<Element>, Element) -> Void) {
        // iterate bitmap ones, peek each
    }
}
```

This provides `iterate_live` semantics without consuming elements. The `(Index<Element>, Element)` tuple gives the caller both the handle and the value, which is the expected slab iteration pattern.

---

## Outcome

**Status**: RECOMMENDATION

Three gaps identified. `capacity` is high priority and straightforward to add. In-place mutation and non-consuming iteration are medium priority and require buffer-layer verification before implementation. All other canonical operations are present with correct naming, complexity, and ownership semantics.
