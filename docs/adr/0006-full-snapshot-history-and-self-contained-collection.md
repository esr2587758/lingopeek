# Full-snapshot history and self-contained collection

## Context

We are separating three concepts: **History** (automatic, full log of every query, expires), **保存/Save** (a retention state on a whole History record so it no longer expires), and **收藏/Collect** (hand-picked fragments curated into an independent, typed library). "Re-invoking Lingobar" from either place should show the user the same panel they saw before.

History previously stored only a compact, bounded summary per record (`visibleText` ≤240, `copyText` ≤2000, `itemType`, `note`), per the Phase 1 decision "persist history as compact user-visible Foundation JSON with bounded fields." That summary cannot rebuild a rich panel (structured grammar blocks, all rewrite variants, full example lists), so re-invoking from history would have required a fresh LLM call every time.

## Decision

Upgrade History to store the **full structured result** for each record — enough to rebuild the panel without an LLM call. This reverses the Phase 1 "compact summary" decision.

To bound the resulting size, cut the default history retention from 200 records to **50**. The `保存` (Save) retention state is the safety valve for anything the user wants to keep beyond that window.

The `收藏` collection stores a **self-contained snapshot** in each card (the whole structured fragment plus a snapshot of the originally selected source sentence). Collection cards do **not** reference history by pointer and do **not** depend on history retention — a collected card survives even after its originating history record expires or is cleared. Re-invoking Lingobar from a collection card uses the card's own snapshot; a fresh LLM call happens only when the user switches to a different action than the one that was collected.

## Considered Options

- **Re-run on every re-invocation** (no reuse): simplest, but pays an LLM call and latency each time and can return a different result than the user saw.
- **Point collection cards back into history**: avoids duplicating data, but makes curated collection items fragile — they would break when history expires or when older records predate the full-snapshot format.

## Consequences

- History JSON grows from a light summary log to a full-result store; the 200→50 cut keeps total size in check.
- History storage schema changes; loading must tolerate older compact records for backward compatibility.
- Collection cards are heavier (they carry a full snapshot), but only for the small number of items the user deliberately collects, and they are fully decoupled from history lifetime.
