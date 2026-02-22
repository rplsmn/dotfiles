---
name: team-review-rust
description: Review Guidance: Rust
---

# Review Guidance: Rust

## Critical Review Points

When assessing a Rust plan or code review, stop and re-examine if any of these apply:

- **Unsafe blocks without documented invariants**: Any `unsafe` must have a comment explaining what invariant is being maintained and why it's safe. Review safety argument, not just syntax.
- **API boundaries without lifetime/trait bounds verification**: Public fn signatures must be checked for missing bounds. Callers should not need to reason about lifetime constraints.
- **Lock ordering dependencies**: Concurrent code holding multiple locks must have documented acquisition order. Deadlock risk is silent until production.
- **Result vs panic decision is wrong**: Library code should return `Result` for recoverable errors, never panic. Panics in dependencies are production crashes.
- **Generic bounds missing or incomplete**: Functions with generics must have all necessary bounds. "Looks right" != "will compile on all intended types."
- **Enum match not exhaustive**: Switch to panic-based handling. Adds field → must update all matches. Exhaustiveness is compile-time safety.
- **Unnecessary clone workaround**: Clone to fix borrow checker errors suggests API over-borrows. Investigate whether callers should own data instead.
- **Implicit drop ordering**: Resource cleanup (locks, file handles) depends on drop order. Spans with multiple guards may not drop in intended order.
- **Send/Sync bound missing in async code**: Spawned tasks must be Send. Shared state across threads must be Send + Sync. Easy to miss in trait objects.
- **Iterator vs for loop performance assumption**: Iterators are zero-cost *only* if compiler can optimize them. Manual loops sometimes win; benchmark.

## Type System & Dispatch

**Ownership at API boundaries:**
- Public functions should minimize borrowing requirements. APIs that require callers to hold references longer than needed are fragile.
- Return ownership when cheap. Borrowing should only be required when there's a structural reason (e.g., accessing fields of a borrowed struct).
- Check for defensive cloning in function signatures — it's a code smell that the API is over-constrained.

**Lifetime annotations in public interfaces:**
- All references in public APIs must have explicit lifetime bounds. Implicit 'static or Elided lifetimes are compilation traps.
- Lifetime bounds should make logical sense. If a returned reference outlives the input, that's not an error — that's the design. Verify intentional.
- Generic lifetime bounds (`T: 'a`) must match the actual constraints. Too narrow and callers can't use it; too wide and safety reasoning fails.

**Trait coherence and orphan rules:**
- Can't implement a foreign trait for a foreign type. This rule exists. Plans assuming they can implement `impl Display for String` will fail.
- Trait bounds in generic code must respect coherence. Two `impl<T>` blocks for the same trait with overlapping bounds can't both exist.
- Blanket impls (`impl<T> MyTrait for T`) prevent any more specific impl. Review what this unlocks vs what it blocks.

**Generic bounds and where clauses:**
- When a generic function calls methods on `T`, add those bounds. Don't assume; verify `T` actually supports what you're doing.
- `where` clauses should clarify intent. `T: Copy` is different from `T: Clone`; both are different from "take ownership." Review carefully.

**Enum exhaustiveness in match:**
- Match expressions are compile-time checked. Relying on `_ => panic!()` defeats the purpose.
- Adding a variant to an enum is a *breaking change* — all matches must be updated. Plans that add enum variants need code review scope expansion.

## Common Pitfalls

**Borrow checker workarounds masking design flaws:**
- Code that clones to satisfy the borrow checker often indicates the function signature is over-constrained. Investigate root cause before accepting the clone.
- Splitting borrows unnecessarily (storing `&self.field` in a local, then re-borrowing) suggests the API should return ownership instead.

**Lock ordering and deadlocks:**
- Concurrent code with multiple locks must acquire in consistent order everywhere. Code review cannot catch deadlocks; they appear under load. Document order and enforce via code inspection.
- Nested lock guards are especially risky. If `lock_a` can be held while acquiring `lock_b`, then all code paths must do it that way.

**Panics in library code:**
- Any `panic!()`, `unwrap()`, or `expect()` in library code is a production crash if inputs are untrusted or streams are long-lived.
- Even `.ok()` chains that assume `None` is impossible should return an error if there's any chance of reaching them unexpectedly.

**Implicit drop ordering in scopes:**
- Resources (file handles, locks, network connections) are freed in reverse order of declaration. Scope spans with multiple guards depend on this.
- Early `drop(x)` is not always safe — if `x` holds a borrow that another variable needs, the drop fails. Trust compiler; don't force drops.

**Send/Sync bound violations in concurrent/async:**
- Spawned tasks (tokio::spawn, thread::spawn) require Send. Shared state requires Send + Sync. Violations are caught at compile time only if bounds are present.
- Trait objects (`dyn MyTrait`) don't inherit Send/Sync. Add bounds: `dyn MyTrait + Send` if the trait is used in concurrent code.
- Futures are not automatically Send. If a spawned future uses `.await` on a !Send future, it won't compile. Check all await points.

**Zero-cost abstraction misses:**
- `String` owns; `&str` borrows. Passing `String` by value defeats optimization. Use `&str` for function arguments.
- `Vec<T>` is a heap allocation. `&[T]` is a slice (borrowed). API should take `&[T]`, not `Vec<T>`.
- Iterators are compiled away if the compiler can see through them. But if you collect intermediate results, cost is real. Check for unnecessary `.collect()`.

## Testing Considerations

**Ownership and borrowing semantics:**
- Unit tests should verify that APIs work as intended with both short-lived and long-lived borrows. Tests that only use owned data miss lifetime edge cases.
- Tests should also verify compile-time safety: if a test-helper function is generic, test it with multiple types to ensure bounds are correct.

**Error paths and Result handling:**
- Tests must verify that all `Err` paths are exercised. Code that unwraps in production has tests that only saw `Ok`.
- For library code, test both success and failure cases. A function that always succeeds or always panics is untestable in production.

**Concurrent code and Send/Sync:**
- Tests don't catch deadlocks unless the test actually hits the race condition. But tests can verify Send/Sync bounds at compile time: pass shared data to `thread::spawn` or `tokio::spawn` in tests.
- Stress tests with multiple threads are more valuable than sequential tests for locking code.

**Unsafe blocks:**
- Any test of unsafe code should document the safety invariant being checked. Tests of unsafe FFI should verify the contract with the C library.
- Tests that only verify the happy path don't catch unsafe violations. Fuzz if possible.

## Performance Gotchas

**Unnecessary allocations:**
- String concatenation in loops allocates for each iteration. Use `String::with_capacity()` or an allocator-aware pattern.
- `Vec::push()` reallocates on capacity overflow. Large vectors should be pre-allocated or grown in batches.

**Lock contention:**
- Fine-grained locks can cause more contention than coarse-grained ones if threads must acquire many locks per operation.
- Lock-free algorithms are not always faster; they trade lock contention for CPU cache coherence cost. Benchmark both.

**Panic unwinding cost:**
- Panic unwinding is not zero-cost. Don't use panics for control flow in hot paths or deeply nested loops.
- Panic vs Result: Result branches are optimized away; panics unwind the stack. If it's recoverable, use Result.

**Missed zero-cost abstractions:**
- Closures are zero-cost *only if inlined*. Passing large closures by value or through trait objects defeats optimization.
- Trait objects with virtual dispatch are not free. If you're in a hot loop, inline trait impl or use generics instead.
- `map().collect()` compiles to efficient code only if the compiler can see the whole pipeline. Breaking it with intermediate variables or branches loses optimization.
