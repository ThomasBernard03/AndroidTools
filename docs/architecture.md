# Foundation architecture

## 1. Two languages, one application

Vue/TypeScript handles presentation and user interactions. Rust handles system
operations and business logic. Tauri provides the window and the IPC bridge between
them. Vite builds the frontend; Cargo builds the backend.

An IPC call behaves like an asynchronous service call: the frontend sends
serializable arguments, Rust executes a command and returns a result. Events can
report progress for long-running operations.

The current welcome screen needs no IPC calls. There are no business commands,
simulated services or USB dependencies yet.

## 2. Organizing future features

Each feature will live under `src/features/<feature>/` on the frontend and
`src-tauri/src/features/<feature>/` in Rust. Introduce layers when they have a
concrete responsibility:

| Responsibility             | Frontend                       | Backend                    |
| -------------------------- | ------------------------------ | -------------------------- |
| Presentation / entry point | Vue components and composables | Thin Tauri commands        |
| Application                | Interaction orchestration      | Use cases                  |
| Domain                     | Models and service contracts   | Models, rules and traits   |
| Infrastructure             | IPC adapter                    | USB, files and persistence |

Dependencies point toward contracts rather than external implementations. The
composition root selects and injects concrete implementations. Rust business logic
remains testable independently of the Tauri runtime.

The first feature will define a device-listing contract. A simulated implementation
and a USB implementation will satisfy that contract. On the Vue side, an injectable
service will allow deterministic scenarios to replace IPC. Real and simulated
modes must be selected explicitly; a USB error must never silently turn into demo
data.

Types crossing the IPC boundary need a source of truth. When introducing the first
command, evaluate generating them from Rust. A TypeScript generic on `invoke` does
not validate data at runtime.

## 3. Tests and simulations

- **Rust unit tests**: business rules with injected dependencies.
- **Rust integration tests**: adapters with temporary files and fixtures.
- **Vitest**: composables and services with controlled results and failures.
- **Vue Test Utils**: visible behavior and user interactions.
- **Browser journeys**: introduce these with the first interactive workflows.
- **Hardware checks**: document USB verification separately; it must never be
  required to run the normal test suite.

A fake is a simplified working implementation. A mock verifies an interaction.
Prefer fakes for demo scenarios, and use mocks when the interaction itself matters.

Test empty, loading, success and error states, then relevant concurrency scenarios:
disconnection, stale results and cancellation. Tests should validate behavior
rather than duplicate implementation details.

## 4. Initial decisions

- Vue Composition API and strict TypeScript.
- No global store or router until there is a concrete need.
- Tailwind for styling; shared components for recurring patterns.
- English for all UI text, accessibility labels, documentation and comments.
- No native plugin or permission without a feature that requires it.
- Run blocking operations outside the UI thread when they are introduced.
- Structured business errors translated into understandable UI messages.
- Formatting, lint, builds and tests run in CI without a phone.
- Distribution packaging is deferred to a dedicated milestone; the desktop binary
  build is verified from this foundation onward.

## 5. Feature definition of done

1. Expected behavior and failures are defined.
2. External dependencies are replaceable.
3. Meaningful tests pass without a phone.
4. Simulated scenarios are reproducible.
5. Behavior, limitations and test commands are documented.
6. Quality checks have been run and their results reported.
