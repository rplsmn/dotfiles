---
name: team-review-r
description: Review Guidance: R
---

# Review Guidance: R

Critical review points for assessing R code during planning and code review. Focus on what breaks plans, what hidden assumptions lurk in code, and what makes R tests meaningful. This is a review lens, not an R tutorial.

## Critical Review Points

- **NSE (Non-Standard Evaluation) at API boundaries**: Functions using NSE (e.g., `dplyr::filter()`, `subset()`, `transform()`) may have unclear contracts. Verify: are arguments quoted or evaluated? Does the function accept both bare symbols and strings? Can it handle `.data` pronouns? Plans must be explicit about NSE handling in public interfaces.

- **NULL propagation and empty vectors**: R propagates NULLs and empty vectors silently through many operations. Plans must specify: does a function reject NULL input, coerce it to NA, or pass it through? Does an empty vector return NULL, an empty vector, or a zero-row data.frame? Implicit behavior breaks code.

- **Type coercion in comparisons and joins**: R silently coerces types in `==`, `<`, and join keys. A numeric 1 equals character "1" in some contexts. Plans must specify column types precisely before joins. Reviews must verify type declarations and casting.

- **Vector recycling**: R recycles shorter vectors to match longer ones (sometimes with warnings). `c(1,2,3) + c(10, 20)` succeeds. Plans must be explicit about expected vector lengths at each step. Reviews must check for accidental recycling.

- **S3/S4/R5/S7 method dispatch at function entry**: Objects carry class attributes. A function `f(x)` may dispatch to `f.numeric()`, `f.data.frame()`, or `f.default()` depending on `class(x)`. Plans using existing functions must verify which method applies. New functions must declare their S3/S4/R5 methods explicitly.

- **Copy-on-modify semantics**: R appears to copy when modifying, but shares memory until write. Plans involving large vectors or nested lists may create unexpected copies. Reviews must check: are intermediate variables necessary? Are there unnecessary copies? Repeated `df[i]` assignments can silently trigger full copies.

- **Factor edge cases**: Factors are integers with labels. Arithmetic on factors coerces to integers, losing labels. Comparisons work but may surprise. Converting between ordered/unordered factors requires explicit relevel(). Plans using factors must spell out expected behavior.

- **Missing value semantics**: `NA`, `NULL`, `NaN`, and `.` (data.table) are distinct. `is.na(NULL)` is logical(0). `NA + 1` is NA. Plans must be explicit about which missing value type is expected at each step. Reviews must verify NA handling propagates correctly through pipelines.

- **Function argument matching and partial names**: R matches function arguments by position, then by full name, then by partial name. `mean(x=1:5, t=1)` matches `trim`, not `type`. Plans passing many arguments must use full names. Reviews must verify arguments aren't accidentally matched to the wrong parameter.

- **Scope and lazy evaluation**: Functions don't evaluate arguments until referenced. `f <- function(x) { function() x }` captures the promise, not the value. Deferred evaluation in closures and non-standard evaluation can create hard-to-debug bugs. Plans involving delayed computation must be explicit about when evaluation happens.

## Type System & Dispatch

### S3 Objects and Method Dispatch
- Objects are lists (or vectors) with a `class` attribute
- `method(obj)` looks for `method.<class>(obj)`, then `method.default(obj)`
- Dispatch happens once at function entry — no re-dispatch inside function
- Plan review: if calling an existing function with an object, verify its class and which method will be used
- Implementation review: if writing new S3 methods, verify the class is set correctly and method signatures match the generic

### S4 Objects and Formal Class Definitions
- S4 uses `setClass()`, `setMethod()`, `setGeneric()` with formal slot definitions
- Dispatch is more strict; inheritance via `contains`
- Verify: are slots the exact type expected? Does the method signature match the generic?
- S4 errors are more verbose — reviews should check these error messages carefully

### R5 / Reference Classes
- Mutable objects with methods bound to a single class
- Fields are not copied on assignment (reference semantics)
- Plans involving R5 must be explicit about mutation and shared state
- Reviews must verify: are references being shared accidentally? Are fields modified in place as intended?

### S7 (Emerging)
- Formal type system with explicit type annotations
- Early in adoption; less common in existing code
- If used, reviews must verify: are all properties annotated? Are methods correctly dispatched?

### Type System at API Boundaries
- Input contracts: explicitly state expected class(es), mode (numeric/character/logical), length (scalar/vector/matrix)
- Output contracts: what class is returned? What are possible NA values?
- Reviews must verify: are inputs validated before use? Do outputs match documented class? Can internal type conversions break the contract?

## Common Pitfalls

- **NSE in function arguments without quoting**
  - `df %>% filter(name == "Alice")` works
  - `df %>% filter(!! sym(col_name))` required for dynamic columns
  - Plans must specify when NSE vs. quoting is used
  - Reviews must verify dynamic column handling is correct

- **Forgetting data.frame coercion rules**
  - `df[, "col"]` returns a vector (drops dimensions)
  - `df[, "col", drop=FALSE]` returns a 1-column data.frame
  - `df[["col"]]` always returns a vector
  - `df$col` always returns a vector
  - Plans must specify which extraction method to use and verify the result type matches expectations

- **Implicit type conversions in data.table**
  - data.table has different (and faster) coercion rules than data.frame
  - `:=` modifies in place; `<-` on a filtered view may not update the original
  - Reviews must verify: is the intent to modify by reference or create a copy? Are the correct assignment operators used?

- **Ignoring attributes during assignment**
  - `x <- c(1,2,3); names(x) <- c("a","b","c"); x[2]` returns named value
  - `x <- x[2]` preserves names; may surprise when you expect just the value
  - Plans using attributes must be explicit: are attributes preserved or dropped?

- **Vectorized function returning wrong shape**
  - `lapply()` returns a list; `sapply()` simplifies (may drop dimensions); `mapply()` recycles arguments
  - Plans must specify which *apply variant is needed and what the output shape is
  - Reviews must verify the simplification rules are correct

- **Recycling with length mismatch**
  - `c(1,2,3) + c(10,20)` succeeds with a warning, recycling `c(10,20,10)`
  - Plans must check: are lengths aligned? Should a mismatch be an error?

- **NULL vs. logical(0) vs. NA**
  - `c(NULL, 1, 2)` produces `c(1,2)` (NULL is dropped)
  - `if (NULL) { }` evaluates as FALSE
  - `is.na(NULL)` is `logical(0)`, not FALSE
  - Plans must be explicit about which "no value" semantics apply

- **Ordered factors and relevel**
  - `factor()` creates unordered; `ordered()` creates ordered
  - Mixing ordered and unordered in operations can fail or produce unexpected results
  - Plans involving factors must specify ordered vs. unordered and verify relevel() is used when combining

- **Partial argument matching**
  - `mean(x=1:5, t=0.2)` matches `trim` parameter, not `type`
  - Confusing parameter names can cause silent matches
  - Reviews must verify: is partial matching intended or a bug?

- **Copy-on-modify in loops**
  - `for (i in 1:n) df <- rbind(df, new_row)` creates n copies
  - Even `df[i,] <- row` may trigger a full copy
  - Plans with growing vectors/dataframes must pre-allocate or use `data.table` for efficiency

- **Class attribute lost during subsetting**
  - `x <- ts(1:10); x[1:5]` may lose the `ts` class
  - Custom S3 objects may lose their class if not handled carefully in `[` or `[[` methods
  - Reviews must verify: is custom class preserved through subsetting?

## Testing Considerations

### testthat Patterns
- Use `expect_equal()` for values, `expect_true()` for logical, `expect_error()` for exceptions
- `expect_identical()` is stricter (includes class and attributes); use when exact match is required
- `snapshot_test()` captures output (useful for complex structures); verify snapshots match intent before committing

### Meaningful vs. Superficial Tests
- **Superficial**: `expect_true(!is.na(result))` — just checks NA-ness, not actual value
- **Meaningful**: `expect_equal(result, expected_value, tolerance=1e-6)` with explicit expected values from first-principles calculation
- Reviews must check: does the test verify the actual computation, or just that the function runs?

### Mocking and Side Effects
- `testthat::with_mock()` allows mocking external functions (less common now; more often use dependency injection)
- Data access (DB, API calls) should be mocked or use test fixtures, not live external systems
- Plans involving external dependencies must specify test strategy: mocking, fixtures, or test data

### Edge Cases in Tests
- Empty vectors/data.frames: `data.frame()`, `numeric(0)`, `NULL`
- Single-row inputs: verify code doesn't assume multiple rows
- All-NA inputs: verify NA propagation is correct
- Type mismatches: intentional type errors (should fail or coerce?)
- Extremely large inputs: verify no unexpected copying or performance degradation

### Test Isolation
- Each test should be independent; clean up side effects (files, connections, global variables)
- Use `teardown()` or test-local temporary directories (`tempdir()`)
- Reviews must verify: can tests run in any order? Do they leave artifacts?

## Performance Gotchas

- **Growing vectors in loops**: `for (i in 1:n) x <- c(x, new_val)` is O(n²); pre-allocate or use list + `unlist()`
- **Repeated subsetting of large objects**: `df[df$col > 5]` is efficient; `df[i]` in a loop is not if i changes per iteration
- **Unnecessary copies in function calls**: passing large data.frames/matrices creates temporary copies; consider using data.table for pass-by-reference semantics
- **rowwise operations on data.frames**: `apply(df, 1, f)` is slow; vectorize the function or use data.table's `:=` with rowwise operations
- **Stringsearch and regex without fixed=TRUE**: regex is slow; use `fixed=TRUE` or `stringr::fixed()` for literal string matching
- **Large lapply() results**: `lapply()` builds the entire result in memory before returning; use `Map()` with smaller chunks if memory-bound
- **Factor-related slowdowns**: creating many factors from strings is slow; use `stringAsFactors=FALSE` when loading data, convert to factors once if needed
- **Unnecessary full-data-frame copies**: `df$newcol <- value` may trigger a full copy on older R versions; data.table's `:=` avoids this
- **Checking length with `length() > 0`**: `length(x) > 0` is O(n) for some objects; use `length(x) != 0` or dedicated `!is.empty()` function if available
- **Sorting or ordering large vectors repeatedly**: cache sorted indices if needed multiple times; `order()` is O(n log n)
