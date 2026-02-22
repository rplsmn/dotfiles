# Review Guidance: JavaScript

## Critical Review Points

- **Async propagation not verified**: Does every async operation have a `.catch()` or `try/catch` wrapper, or is it part of an awaited chain? Unhandled promise rejections crash processes
- **Type contracts at API boundaries**: Are input types validated and return types consistent? Dynamic typing means downstream code can receive unexpected types
- **`this` binding in callbacks**: Are methods used as callbacks (timers, event listeners, array methods) properly bound or wrapped? Unbound methods lose context
- **Module system interop**: Does the code mix ESM and CommonJS imports? ESM `import` and CJS `require` have different loading semantics and can cause subtle failures
- **Closure variable capture in loops**: Are loop variables captured correctly in callbacks (use `let`, not `var`)? `var` hoisting captures the last value
- **Object mutation and reference semantics**: Are objects passed to functions mutated unexpectedly? Is deep cloning done where shallow copy occurs?
- **Unhandled promise rejections in event listeners**: Event listeners, timers, and async iterators that return promises can leave rejections hanging
- **Import side effects**: Are imported modules relied upon for initialization order? ESM execution order differs from CJS require() ordering

## Type System & Dispatch

- JavaScript has dynamic typing with implicit coercion. Verify at API boundaries: input type checking (typeof checks and validation libraries are most reliable; instanceof is unsafe across realms/minification) and return type consistency
- No static dispatch. Verify that methods called on objects actually exist (prototype chain traversal can be surprising); use hasOwnProperty or Object.getOwnPropertyNames for introspection
- Prototype chain: properties/methods resolve up the chain. Mutating Object.prototype is a common vulnerability; verify this never happens
- Type coercion traps: `==` vs `===`, falsy values (0, "", null, undefined, NaN), array-to-string coercion in comparisons
- For APIs: validate inputs on entry (check type, null/undefined, range). Return types must be consistent across all code paths
- Null vs undefined: different meanings; verify the code distinguishes them (e.g., `== null` vs `=== null`)

## Common Pitfalls

- **Unhandled promise rejections**: `.catch()` chains are easy to forget; one missing `.catch()` in a Promise chain can crash the event loop if the rejection occurs
- **Async/await not propagating errors**: Throwing in an async function returns a rejected promise; verify callers of async functions have a `.catch()` or are in a `try/catch`
- **`this` binding in callbacks**: Passing a method as a callback (event listener, `array.map(obj.method)`) loses `this`. Use arrow functions or `.bind()` to preserve it
- **Reference equality in loops**: `const` inside loops creates a new binding each iteration; `var` in loops reuses one binding. Callbacks in loops capture the final value
- **Object spreading/deep cloning**: `{...obj}` is a shallow copy; nested objects are shared. Verify this doesn't cause mutation bugs
- **Module system confusion**: ESM `import` is hoisted and synchronous (at parse time); CJS `require()` is synchronous (at runtime). Mixing them can cause circular dependency issues
- **Event listener memory leaks**: Listeners added without removal accumulate; verify cleanup in teardown (e.g., removeEventListener, unsubscribe)
- **Forgotten `await` on async operations**: An async function call without `await` returns a Promise; verify the caller actually waits for it
- **Set/Map mutation during iteration**: Modifying a Set or Map while iterating over it causes undefined behavior; use `.forEach()` or collect mutations separately
- **Hoisting surprises**: `var` declarations are hoisted; function declarations are fully hoisted. Verify order doesn't create undefined references
- **Set/Map mutation during iteration safety**: Using `.forEach()` is safe; using `for...of` or `for` with mutations is undefined behavior. Verify iteration method matches mutation needs

## Testing Considerations

- **Async tests must await promises**: Test assertions run immediately; if a promise is not awaited or the test framework doesn't track it, assertions in the promise run after the test ends
- **Mock modules, not global state**: Use a test isolation library (not manual mocking) to avoid test pollution; verify mocks are cleaned up between tests
- **Error path testing**: Verify `.catch()` blocks and `try/catch` branches are tested, not just happy paths. Promise rejection handling is often untested
- **`this` binding in test doubles**: When mocking methods, verify `this` is bound correctly; arrow functions in test setup don't have `this` context issues
- **Closure variable capture in tests**: If a test sets a variable in a loop or conditional, verify the callback sees the intended value, not the final one
- **Event listener cleanup**: Verify listeners added in setup are removed in teardown; tests that don't clean up listeners pollute subsequent tests
- **Microtask queue awareness**: Promise resolution and `queueMicrotask` run before timers; verify test assertions account for this ordering

## Performance Gotchas

- **Blocking the event loop**: Long-running synchronous code (parsing large objects, crypto, regex on huge strings) blocks all other operations. Move to workers or chunk async work
- **Memory leaks from closures**: Callbacks that capture large objects (DOM nodes, buffers) prevent garbage collection if the callback is never removed
- **Excessive object allocation**: Creating new objects/arrays in hot loops (serialization, formatting) creates GC pressure. Reuse buffers or use string concatenation wisely
- **Inefficient array methods**: `array.includes()` is O(n); use Set for membership checks in loops. `array.find()` and `array.filter()` iterate fully; stop early if possible
- **String concatenation in loops**: Building strings with `+=` creates a new string each time; use array.join() or template literals
- **Unintended global variable creation**: Assignment without `var`, `let`, or `const` in non-strict mode creates globals and pollutes the scope chain. Use `strict mode`
- **Synchronous I/O**: `require()` in modules can block if the module does synchronous I/O. Verify hot-path modules don't do sync file/network operations
- **Regular expression catastrophic backtracking**: Complex regex patterns on untrusted input can hang the event loop (e.g., email validation, URL parsing). Test regex with adversarial input or use library functions for common patterns
