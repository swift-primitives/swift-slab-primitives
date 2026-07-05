# Slab.Static (parked)

**Status:** parked out of the build graph (retained in-tree, not scanned by SwiftPM).
**Parked:** 2026-07-05, as part of the ADT-tower **W2** reshape of `swift-slab-primitives`.
**Re-homes at:** **W3** — as the `Slab<E>.Inline<n>` front door.

## Why parked

The W2 reshape hoists the base `Slab` to the bound-free carrier `__Slab<S>` with the
canonical front door `Slab<E>` pinning the default Slab-buffer column
(`Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded`). Once `Slab`
becomes a generic-instantiation typealias, the old nested `extension Slab { struct Static<…> }`
can no longer be declared (a specialized typealias cannot host a nested type).

`Slab.Static` is the **inline (stack-allocated) allocation variant** — it rides the
`Buffer.Slab.Inline<wordCount>` column. Under the tower, an allocation variant is a
front-door alias over its column (`Slab<E>.Inline<n>`), **not** a hand-written type. But the
inline front doors (`X<E>.Inline<n>`) are an explicit **W3** deliverable:

> §9.3 W3 row (adt-tower.md:1376): "cut the first INLINE front doors (`X<E>.Inline<n>` over
> `Buffer<Store.Inline<E, n>>.D`, bounded ops) once the bounded pins generalize".

So the hoist is **out of scope this wave** (playbook §3: coupled-but-out-of-scope-this-wave →
PARK), mirroring the ratified heap-`MinMax` park. The reusable substrate — the
`Buffer.Slab.Inline` column — already lives in `swift-buffer-slab-primitives`, untouched; at W3
`Slab<E>.Inline<n>` is an alias + a column-pinned op set over it.

## What it was

- `Slab.Static<let wordCount: Int>` — a fixed-capacity, inline (zero-allocation) slab over
  `Buffer.Slab.Inline<wordCount>`, with a `peek` non-destructive read and a drain accessor.
- Its DEBUG-only deinit tests (`Tests/Slab Primitives Tests/Slab.Deinit Tests.swift`) were
  release-guarded against the `Buffer.Slab.Inline` occupancy-bitmap release miscompile
  (swift-issue-inlinearray-class-field-write-elision). Those tests are parked with it.

## Re-home checklist (W3)

1. Delete this parked source (the type is re-derived as an alias, not resurrected).
2. Add `Slab<E>.Inline<n> = __Slab<Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Inline<n>>`
   as a nested front-door alias.
3. Pin the slab op surface (`insert`/`remove`/`firstVacant`/…) for the inline column
   (a second column-pinned op set, or generalize the bounded pins per the W3 op-generalization row).
4. Restore the Static deinit tests (still release-guarded until the occupancy-placement ruling
   lands — see `.handoffs/HANDOFF-sparse-occupancy-placement.md`).
