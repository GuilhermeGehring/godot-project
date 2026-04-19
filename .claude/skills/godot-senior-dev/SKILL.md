---
name: godot-senior-dev
description: Senior-level guidance for Godot 4 development — scene/node architecture, GDScript style and static typing, signal design, resource and autoload use, performance and physics (Jolt) considerations, and project organization. Use this skill whenever the user is writing, reviewing, refactoring, or planning Godot code (.gd, .tscn, .tres, .gdshader, project.godot), mentions nodes/scenes/signals/autoloads/resources, or asks about Godot performance, architecture, or best practices — even if they don't explicitly ask for "best practices".
---

# Godot 4 — Senior Development Practices

Apply these defaults when working in this repo. They are written to be ignored intelligently: if the task or the surrounding code has a good reason to break a rule, break it — but know which rule you're breaking and why.

## 1. Scene and node architecture

**Prefer composition over inheritance.** Godot's node tree is designed to be assembled from small, single-responsibility scenes/nodes, not to grow deep class hierarchies. If you find yourself writing `extends` chains three levels deep, stop — turn the shared behavior into a child node (`HealthComponent`, `HitboxComponent`, `StateMachine`) that any scene can attach.

**One scene = one responsibility.** A `Player.tscn` should be the player, not also the camera controller, HUD, and input remapper. Factor sibling concerns into their own scenes and instance them.

**Data flow: down via direct calls, up via signals.** Parents can call into children freely (they own them). Children should not reach up or sideways with `get_parent()` or absolute `$/Root/...` paths — emit a signal and let the parent or a mediator decide what to do. This keeps child scenes portable to other contexts.

**Script-less scenes are fine.** If a scene only needs to compose other nodes and wire signals in the editor, don't attach a script just to feel productive. Scripts are for behavior, not for structure.

**Avoid deep node nesting when a flat structure works.** Each extra level costs `_process`/`_physics_process` dispatch and transform propagation. Flat is usually faster and easier to read.

## 2. GDScript style and static typing

Follow the official [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html). The essentials this repo expects:

**Static typing is the default.** Type every function signature and every non-trivial variable. The compiler catches errors, the editor autocompletes better, and hot paths get a real speedup from typed locals.

- Prefer `:=` (inferred) when the type is obvious from the right-hand side: `var direction := Vector2.RIGHT`.
- Write the type explicitly when it's ambiguous, when assignment spans multiple lines, or when the declared type is narrower than the inferred one: `var target: Node2D = null`.
- Type function parameters and returns: `func take_damage(amount: int) -> void:`.
- Avoid `Variant` unless you genuinely need dynamism (reading untyped JSON, generic containers).

**Naming (strict).**
- Files, functions, variables, signals: `snake_case`.
- Classes (via `class_name`), nodes in the scene tree: `PascalCase`.
- Constants and enum members: `CONSTANT_CASE`.
- Private members: leading underscore (`_internal_state`). This is a convention, not enforced.

**Script order.** Keep a consistent top-to-bottom layout so readers can scan:
1. `@tool` / `@icon` / `class_name` / `extends`
2. Docstring (`##`)
3. Signals
4. Enums, constants
5. `@export` vars
6. Public vars, then private vars
7. `@onready` vars
8. Built-in virtuals in lifecycle order (`_init`, `_enter_tree`, `_ready`, `_process`, `_physics_process`, `_input`, `_exit_tree`)
9. Public methods
10. Private methods (`_helper`)
11. Signal callbacks last

**Indentation: tabs. Line endings: LF** (enforced by `.gitattributes`). Encoding: UTF-8.

## 3. Signals

**Name signals as past-tense events or intent verbs**, from the emitter's perspective: `died`, `health_changed`, `item_picked_up`. Not `on_died`, not `player_died` (the node providing the signal is already the player).

**Type signal parameters**: `signal health_changed(new_value: int, max_value: int)`. This carries through to callbacks in 4.x and catches mismatches at parse time.

**Callback naming.** Default convention is `_on_<source>_<signal>` (e.g. `_on_player_died`). Drop the source when a node connects to itself: just `_on_died`. Connect in code when the wiring is dynamic; connect in the editor when it's structural — don't mix both for the same signal.

**Don't use signals for tight per-frame coupling.** Signals allocate. For something called every frame on the same object, a direct method call is fine and cheaper.

## 4. Resources and autoloads

**Prefer `Resource` subclasses for shared data.** A `WeaponStats extends Resource` saved as a `.tres` is editable in the inspector, serializable, hot-swappable at runtime, and lives outside the scene tree. Use them for items, stats, dialog lines, level configs — anywhere you'd otherwise be tempted to hardcode a dictionary.

**Autoloads (singletons) are a scalpel, not a hammer.** One or two globals for truly cross-cutting concerns (event bus, save system, audio manager) is fine. A dozen is a smell — it means scenes are reaching around each other instead of talking through their parents. Autoloads make testing individual scenes harder because they're always there.

**Never put gameplay state in an autoload "because it's convenient."** Put it on the owning node and pass it down.

## 5. Node lifecycle and memory

**`_ready` is where hierarchy-dependent setup goes.** `_init` runs before children exist and before `@onready` vars resolve — don't touch the tree there.

**`@onready` beats `get_node` in `_ready`.** It's declarative, co-located with the variable, and fails loudly at load time rather than silently at runtime.

**Freeing nodes mid-signal or mid-iteration is dangerous.** Use `queue_free()` (deferred, safe) rather than `free()` (immediate). If you're inside a signal emitted by the node itself, `call_deferred("queue_free")` is the safe form.

**Disconnect or use `CONNECT_ONE_SHOT` when appropriate.** Lambda signal connections to a freed target can leak references; typed method connections are cleaner.

## 6. Performance and profiling

**Profile before optimizing.** Godot's Debugger → Profiler tab separates scripting, physics, rendering, and audio frames. Run it, find the actual hot spot, then change code. Assumptions about what's slow in Godot are usually wrong.

**Process budget.**
- `_physics_process` runs at a fixed tick (default 60 Hz) — put physics queries and `move_and_slide` here.
- `_process` runs per frame — put interpolation, visual updates, input polling here.
- Disable processing on nodes that don't need it: `set_process(false)`, `set_physics_process(false)`. Idle nodes still cost dispatch.

**Don't allocate in hot loops.** Reuse arrays, `Vector2`/`Vector3` locals, and temporary objects. `Array.clear()` keeps the backing buffer; `Array.resize()` is cheaper than rebuilding.

**Object pool things you spawn in bursts** — bullets, particles-as-nodes, damage numbers. Instantiating `PackedScene` is not free.

**Rendering:** reduce draw calls via `MultiMeshInstance3D` for crowds of identical meshes; bake static lighting where you can; enable occlusion culling for interior-heavy scenes; keep shadow-casting lights few and small.

**Collision shapes:** simple primitives (`BoxShape3D`, `SphereShape3D`, `CapsuleShape3D`) crush concave/trimesh shapes for dynamic bodies. Reserve `ConcavePolygonShape3D` for static world geometry.

## 7. Jolt Physics (this project)

This project uses **Jolt Physics** (set in `project.godot`). A few things to keep in mind:

- Jolt is stricter about **non-uniform scaled collision shapes** than Godot Physics — prefer setting shape dimensions on the shape resource rather than scaling the CollisionShape3D node.
- Character controllers: Jolt's behavior differs subtly from Godot Physics around `move_and_slide` wall/floor detection. Test movement edge cases (stairs, slopes, tight corners) and don't assume tutorials written for the default physics engine apply unchanged.
- `Area3D` overlap queries behave as expected; `PhysicsDirectSpaceState3D` queries return the same API.
- If a third-party addon assumes Godot Physics internals (constraint names, direct-body-state poking), verify against Jolt before adopting it.

## 8. Project organization

**Scene-local files live with their scene.** `res://entities/player/` contains `player.tscn`, `player.gd`, `player.tres`, `player_icon.png`. Global resources group by type: `res://shaders/`, `res://audio/sfx/`, `res://ui/themes/`.

**Don't scatter assets by type when they're only used by one scene.** `player.png` belongs next to `player.tscn`, not in a global `sprites/` folder where it gets lost.

**`res://` is the project root — use it** instead of relative paths (`../../foo.tscn`) in code. Relative paths break when a scene is moved or instanced elsewhere.

**Keep `.import/` and `.godot/` out of VCS.** Already gitignored here.

## 9. Input

**Define actions in the Input Map** (Project Settings → Input Map) and read them with `Input.is_action_pressed("move_left")` / `event.is_action_pressed("jump")`. Never hardcode `KEY_W` / `KEY_SPACE` in gameplay code — it kills rebindability, controller support, and alternative layouts.

**Consume input at the right layer.** UI scenes should `accept_event()` when they handle input so it doesn't fall through to gameplay. Use `_unhandled_input` for gameplay, `_input` only when you need to see everything.

## 10. Tooling expectations

- **Warnings as errors in CI** (once a CI exists): enable `debug/gdscript/warnings/treat_warnings_as_errors` in project settings or at least address warnings before merging. Unused vars, shadowed names, and untyped declarations are real bugs in disguise.
- **Editor formatter:** Godot's built-in GDScript formatter (Ctrl+Alt+F) enforces most style rules. Run it before committing.
- **Text scene format (`.tscn`/`.tres`) is diff-friendly** — prefer it over binary `.scn`/`.res` for anything under version control.

## Decision heuristics (quick reference)

| Question | Default answer |
| --- | --- |
| Parent-to-child communication? | Direct method call |
| Child-to-parent or sibling-to-sibling? | Signal |
| Shared data between scenes? | `Resource` subclass in a `.tres` |
| Cross-cutting service (save, audio, events)? | Autoload — sparingly |
| Physics query or movement? | `_physics_process` |
| Visual update, tween, input read? | `_process` or `_unhandled_input` |
| Spawn/despawn many of the same thing per second? | Object pool |
| Thing is slow? | Profile first, change code second |

## When to break these rules

These are defaults for a codebase, not laws. Prototypes, game jams, and throwaway tools legitimately skip typing, skip scene splitting, and hardcode keys — the cost of ceremony outweighs the benefit at that scale. Call it out in the PR or the commit when you're consciously skipping a practice, so future-you knows it was a choice and not an accident.
