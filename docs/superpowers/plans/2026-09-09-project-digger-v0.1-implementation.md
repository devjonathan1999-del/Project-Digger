# Project Digger v0.1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construire un vertical slice Godot jouable qui permet de creuser, déplacer et fusionner la matière, préparer un effondrement, déclencher une résolution déterministe, préserver un relais ancien et atteindre une sortie en profondeur.

**Architecture:** Le terrain est une grille logique de cellules indépendante du rendu. Les actions modifient un état préparatoire annulable, puis `SimulationController` valide et résout la stabilité. Les matières, la stabilité, le réseau ancien, la sauvegarde, le rendu et le HUD restent séparés pour permettre l’ajout ultérieur de chaleur, eau, gaz et pression sans remplacer le cœur du terrain.

**Tech Stack:** Godot 4.7.2 stable, GDScript 2.0, scènes 2D Godot, tests headless maison sans plugin tiers.

**Spec:** `docs/superpowers/specs/2026-09-09-project-digger-v0.1-design.md`

## Global Constraints

- Godot : **4.7.2 stable**.
- Langage : **GDScript**.
- Vue : **2D latérale en coupe verticale**.
- La grille logique est l’autorité gameplay ; le rendu ne stocke aucune règle.
- La stabilité v0.1 est déterministe.
- Actions v0.1 : **Creuser / Déplacer / Fusionner**.
- Toute action de préparation est annulable avant `Déclencher`.
- Une action invalide ne consomme pas d’énergie.
- Pas de capacité d’urgence en v0.1.
- Pas d’eau, gaz, chaleur, pression avancée, PNJ, timers, colonies ou génération procédurale complexe en v0.1.
- La sauvegarde est versionnée dès la première version.
- Le support tactile n’est pas livré en v0.1, mais l’API d’entrée ne dépend pas d’un clic droit, d’un hover ou du clavier.

---

## File Map

- `project.godot` — configuration projet et scène principale.
- `scenes/main.tscn` — racine du vertical slice.
- `scenes/vertical_slice.tscn` — caverne jouable et points d’intérêt.
- `src/core/material_def.gd` — définition immuable d’une matière.
- `src/core/material_catalog.gd` — catalogue data-driven des 4 matières v0.1.
- `src/terrain/terrain_cell.gd` — état sérialisable d’une cellule.
- `src/terrain/terrain_model.gd` — grille logique, lecture/écriture, snapshot.
- `src/terrain/terrain_actions.gd` — Creuser, Déplacer, Fusionner, énergie et undo.
- `src/terrain/stability_system.gd` — support, états Stable/Fragile/Critique et résolution des chutes.
- `src/simulation/simulation_controller.gd` — Observer/Préparer/Déclencher/Résoudre.
- `src/network/ancient_network.gd` — continuité binaire du relais ancien.
- `src/save/save_system.gd` — sauvegarde JSON versionnée.
- `src/view/terrain_renderer.gd` — rendu visuel de la grille.
- `src/view/game_camera.gd` — déplacement et zoom.
- `src/ui/hud.gd` — état, énergie, outil, relais, objectif.
- `src/input/game_input.gd` — commandes souris/clavier traduites en actions abstraites.
- `tests/test_support.gd` — mini runner/assertions.
- `tests/test_runner.gd` — point d’entrée headless.
- `tests/test_material_catalog.gd`
- `tests/test_terrain_model.gd`
- `tests/test_terrain_actions.gd`
- `tests/test_stability_system.gd`
- `tests/test_ancient_network.gd`
- `tests/test_save_system.gd`
- `tests/test_vertical_slice_acceptance.gd`

---

### Task 1: Bootstrap Godot + test harness

**Files:**
- Create: `project.godot`
- Create: `scenes/main.tscn`
- Create: `tests/test_support.gd`
- Create: `tests/test_runner.gd`

**Interfaces:**
- Produces: `TestSupport.check(condition: bool, message: String)`, `TestSupport.equal(actual, expected, message: String)`, `TestSupport.finish() -> int`.

- [ ] **Step 1: Write the failing smoke test runner**

```gdscript
# tests/test_runner.gd
extends SceneTree

func _initialize() -> void:
    var support = preload("res://tests/test_support.gd").new()
    support.check(ProjectSettings.has_setting("application/config/name"), "project.godot chargé")
    quit(support.finish())
```

- [ ] **Step 2: Run it before creating `test_support.gd`**

Run: `godot --headless --path . -s res://tests/test_runner.gd`
Expected: FAIL because `tests/test_support.gd` does not exist.

- [ ] **Step 3: Implement the minimal harness**

```gdscript
# tests/test_support.gd
class_name TestSupport
extends RefCounted

var failures := 0

func check(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        push_error(message)

func equal(actual: Variant, expected: Variant, message: String) -> void:
    check(actual == expected, "%s | actual=%s expected=%s" % [message, actual, expected])

func finish() -> int:
    return 0 if failures == 0 else 1
```

Create `project.godot` with project name `Project Digger`, renderer `gl_compatibility`, viewport `1280x720`, and `run/main_scene="res://scenes/main.tscn"`.

- [ ] **Step 4: Run headless smoke test**

Run: `godot --headless --path . -s res://tests/test_runner.gd`
Expected: exit code 0.

- [ ] **Step 5: Commit**

```bash
git add project.godot scenes/main.tscn tests/test_support.gd tests/test_runner.gd
git commit -m "chore: bootstrap Godot project and test harness"
```

---

### Task 2: Material catalog + logical terrain model

**Files:**
- Create: `src/core/material_def.gd`
- Create: `src/core/material_catalog.gd`
- Create: `src/terrain/terrain_cell.gd`
- Create: `src/terrain/terrain_model.gd`
- Create: `tests/test_material_catalog.gd`
- Create: `tests/test_terrain_model.gd`
- Modify: `tests/test_runner.gd`

**Interfaces:**
- Produces: `MaterialCatalog.get_def(id: StringName) -> MaterialDef`
- Produces: `TerrainModel.new(width: int, height: int)`, `get_cell(pos: Vector2i)`, `set_cell(pos: Vector2i, cell: TerrainCell)`, `snapshot() -> Dictionary`, `restore(snapshot: Dictionary)`.

- [ ] **Step 1: Add failing tests for the four materials and grid round-trip**

```gdscript
func test_catalog(t: TestSupport) -> void:
    var catalog = preload("res://src/core/material_catalog.gd").new()
    t.equal(catalog.get_def(&"rock_common").diggable, true, "roche commune creusable")
    t.equal(catalog.get_def(&"rock_dense").diggable, false, "roche dense non creusable")
    t.check(catalog.get_def(&"stabilizer").stability_bonus > 0, "stabilisant ajoute de la stabilité")

func test_snapshot(t: TestSupport) -> void:
    var model = preload("res://src/terrain/terrain_model.gd").new(4, 4)
    var cell = preload("res://src/terrain/terrain_cell.gd").new(&"rock_common")
    model.set_cell(Vector2i(1, 2), cell)
    var copy = model.snapshot()
    model.set_cell(Vector2i(1, 2), null)
    model.restore(copy)
    t.equal(model.get_cell(Vector2i(1, 2)).material_id, &"rock_common", "snapshot restaure la cellule")
```

- [ ] **Step 2: Run tests and verify failure**

Run: `godot --headless --path . -s res://tests/test_runner.gd`
Expected: FAIL on missing catalog/model classes.

- [ ] **Step 3: Implement data classes**

`MaterialDef` exposes exactly: `id`, `diggable`, `mass`, `strength`, `stability_bonus`, `conductive`.

Catalog values v0.1:

```gdscript
rock_common: mass=1.0 strength=2.0 diggable=true  stability_bonus=0 conductive=false
rock_fragile: mass=0.8 strength=0.8 diggable=true stability_bonus=0 conductive=false
rock_dense: mass=2.0 strength=5.0 diggable=false stability_bonus=0 conductive=false
stabilizer: mass=1.0 strength=1.5 diggable=true stability_bonus=3 conductive=true
```

`TerrainCell` stores `material_id: StringName` and `stability_modifier: float = 0.0`.

- [ ] **Step 4: Implement `TerrainModel` bounds checks + snapshot/restore**

Use a flat `Array` indexed by `y * width + x`. `get_cell()` outside bounds returns `null`; `set_cell()` outside bounds returns `false`.

- [ ] **Step 5: Run tests**

Run: `godot --headless --path . -s res://tests/test_runner.gd`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add src/core src/terrain tests
git commit -m "feat: add material catalog and terrain model"
```

---

### Task 3: Terrain actions, energy, staging and undo

**Files:**
- Create: `src/terrain/terrain_actions.gd`
- Create: `tests/test_terrain_actions.gd`
- Modify: `tests/test_runner.gd`

**Interfaces:**
- Consumes: `TerrainModel.snapshot/restore`, `MaterialCatalog.get_def`.
- Produces: `begin_prepare(model, energy: int)`, `dig(pos) -> bool`, `move(from_cells: Array[Vector2i], offset: Vector2i) -> bool`, `fuse(target: Vector2i, stabilizer_source: Vector2i) -> bool`, `undo() -> bool`, `commit()`, `cancel()`, `energy_remaining: int`.

- [ ] **Step 1: Write failing behavior tests**

Cover exactly:
- valid dig removes one creusable cell and consumes 1 energy;
- digging dense rock returns false and consumes 0;
- move requires empty destination and consumes 2;
- fusion consumes a stabilizer cell, increases target `stability_modifier` by 3, consumes 2;
- `undo()` restores terrain and energy;
- `cancel()` restores the initial prepare snapshot.

- [ ] **Step 2: Run and verify failure**

Run: `godot --headless --path . -s res://tests/test_runner.gd`
Expected: FAIL on missing `TerrainActions`.

- [ ] **Step 3: Implement action transaction history**

Before each valid mutation, push:

```gdscript
_history.append({
    "terrain": _model.snapshot(),
    "energy": energy_remaining,
})
```

Only deduct energy after validation succeeds.

- [ ] **Step 4: Implement exact v0.1 costs**

```gdscript
const DIG_COST := 1
const MOVE_COST := 2
const FUSE_COST := 2
```

- [ ] **Step 5: Run tests**

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add src/terrain/terrain_actions.gd tests
git commit -m "feat: add staged terrain actions and undo"
```

---

### Task 4: Deterministic stability preview and collapse resolution

**Files:**
- Create: `src/terrain/stability_system.gd`
- Create: `tests/test_stability_system.gd`
- Modify: `tests/test_runner.gd`

**Interfaces:**
- Produces: `classify(model: TerrainModel) -> Dictionary[Vector2i, int]` using enum `STABLE`, `FRAGILE`, `CRITICAL`.
- Produces: `resolve(model: TerrainModel, max_iterations: int = 128) -> Array[Dictionary]`.

- [ ] **Step 1: Write failing tests for support rules**

Rules v0.1:
- bottom-row solids are supported;
- a solid is supported when a solid directly below it is supported;
- lateral support contributes 0.5 each from left/right supported neighbors;
- effective support score is compared against `mass / max(0.1, strength + stability_modifier)`;
- score >= threshold => STABLE; score >= threshold * 0.5 => FRAGILE; otherwise CRITICAL.

Include a test where adding stabilizer changes a target from CRITICAL to STABLE.

- [ ] **Step 2: Verify tests fail**

Run headless runner; expected FAIL.

- [ ] **Step 3: Implement classification as repeated propagation until no cell changes**

No random values. Same model must always yield the same classification.

- [ ] **Step 4: Implement collapse**

Each iteration processes CRITICAL cells bottom-to-top. A critical cell moves down by one if destination is empty. Stop when no cell moves or `max_iterations` is reached. Return movement records `{from, to}` for animation.

- [ ] **Step 5: Add iteration-limit test**

A tall unsupported column must terminate within `max_iterations` and never loop forever.

- [ ] **Step 6: Run tests + commit**

```bash
git add src/terrain/stability_system.gd tests
git commit -m "feat: add deterministic stability and collapses"
```

---

### Task 5: Ancient network continuity

**Files:**
- Create: `src/network/ancient_network.gd`
- Create: `tests/test_ancient_network.gd`
- Modify: `tests/test_runner.gd`

**Interfaces:**
- Produces: `is_connected(model: TerrainModel, source: Vector2i, relay: Vector2i) -> bool`.

- [ ] **Step 1: Write failing BFS tests**

Test a conductive chain made from `stabilizer` cells. Removing one middle cell must switch connection from true to false.

- [ ] **Step 2: Implement four-neighbor BFS**

Only cells whose `MaterialDef.conductive == true` can propagate the network. Source and relay positions count as endpoints even if visually represented by scene nodes.

- [ ] **Step 3: Run tests + commit**

```bash
git add src/network tests
git commit -m "feat: add ancient network continuity"
```

---

### Task 6: Simulation state machine

**Files:**
- Create: `src/simulation/simulation_controller.gd`
- Create: `tests/test_simulation_controller.gd`
- Modify: `tests/test_runner.gd`

**Interfaces:**
- Produces enum: `OBSERVER`, `PREPARE`, `RESOLVING`.
- Produces signals: `state_changed(state)`, `resolution_finished(movements)`, `energy_changed(value)`.
- Produces: `enter_prepare()`, `trigger_resolution()`, `cancel_prepare()`.

- [ ] **Step 1: Test allowed transitions**

Expected lifecycle:

```text
OBSERVER -> PREPARE -> RESOLVING -> OBSERVER
OBSERVER -> PREPARE -> OBSERVER (cancel)
```

`trigger_resolution()` outside PREPARE returns false.

- [ ] **Step 2: Implement controller orchestration**

`enter_prepare()` calls `TerrainActions.begin_prepare(model, cycle_energy)`.
`trigger_resolution()` commits actions, calls `StabilitySystem.resolve()`, recalculates `AncientNetwork`, then returns to OBSERVER.
`cancel_prepare()` restores initial snapshot.

- [ ] **Step 3: Run tests + commit**

```bash
git add src/simulation tests
git commit -m "feat: add prepare and resolution state machine"
```

---

### Task 7: Save system

**Files:**
- Create: `src/save/save_system.gd`
- Create: `tests/test_save_system.gd`
- Modify: `tests/test_runner.gd`

**Interfaces:**
- Produces: `save_to_path(path: String, model: TerrainModel, extra: Dictionary) -> bool`
- Produces: `load_from_path(path: String) -> Dictionary`
- Save schema version: `1`.

- [ ] **Step 1: Write round-trip test**

Persist:
- terrain snapshot;
- relay connected state;
- cycle state only if OBSERVER/PREPARE;
- objective reached boolean.

- [ ] **Step 2: Implement JSON schema**

```json
{
  "version": 1,
  "terrain": {},
  "relay_connected": true,
  "cycle_state": 0,
  "objective_reached": false
}
```

Reject unsupported future versions with an explicit error and return `{}`.

- [ ] **Step 3: Run tests + commit**

```bash
git add src/save tests
git commit -m "feat: add versioned save system"
```

---

### Task 8: Playable cave data + acceptance path

**Files:**
- Create: `src/content/vertical_slice_layout.gd`
- Create: `tests/test_vertical_slice_acceptance.gd`
- Modify: `tests/test_runner.gd`

**Interfaces:**
- Produces: `VerticalSliceLayout.build() -> Dictionary` with `model`, `relay_source`, `relay_pos`, `exit_rect`, `spawn_focus`.

- [ ] **Step 1: Encode the cave as deterministic data**

Use a logical grid `64 x 72` with zones:
- entrance around rows 4–12;
- friable ceiling around rows 14–24;
- stabilizer vein around columns 12–18, rows 28–35;
- dense blocking mass around columns 26–40, rows 40–49;
- conductive path and relay beside the dense mass;
- exit below row 64.

- [ ] **Step 2: Write acceptance tests**

Verify:
- entrance has at least one diggable path;
- dense obstacle contains non-diggable cells;
- relay begins connected;
- at least one deliberate support-removal sequence causes part of the dense mass to fall;
- after that sequence a traversable empty vertical corridor intersects `exit_rect`;
- relay can remain connected for the canonical solution.

- [ ] **Step 3: Tune data only until acceptance passes**

Do not weaken stability rules to make the level pass. Adjust only layout coordinates/material placement.

- [ ] **Step 4: Commit**

```bash
git add src/content tests
git commit -m "feat: add vertical slice cave layout"
```

---

### Task 9: Renderer, camera, input and HUD

**Files:**
- Create: `src/view/terrain_renderer.gd`
- Create: `src/view/game_camera.gd`
- Create: `src/input/game_input.gd`
- Create: `src/ui/hud.gd`
- Create: `scenes/vertical_slice.tscn`
- Modify: `scenes/main.tscn`

**Interfaces:**
- `TerrainRenderer.set_model(model)`, `set_analysis(classification)`, `cell_from_screen(screen_pos) -> Vector2i`.
- `GameInput` emits `dig_requested(cell)`, `move_requested(cells, offset)`, `fuse_requested(target, source)`, `prepare_requested`, `trigger_requested`, `undo_requested`, `cancel_requested`.

- [ ] **Step 1: Build placeholder material rendering**

Use 16 px logical cells. Draw filled cells with material-specific base appearance and subtle edge variation; do not draw grid lines. Analysis overlay uses translucent Stable/Fragile/Critical masks only in PREPARE.

- [ ] **Step 2: Implement camera controls**

Mouse wheel zoom clamped `0.6..2.0`; pan via middle drag and keyboard arrows/WASD. Input actions are defined in `project.godot`, not hard-coded event keycodes inside gameplay logic.

- [ ] **Step 3: Implement HUD**

Display only:
- `Observer` / `Préparer` / `Résolution`;
- energy remaining;
- active tool;
- `Relais : connecté/coupé`;
- `Objectif : atteindre la sortie`;
- buttons `Préparer`, `Déclencher`, `Annuler`, `Undo` according to state.

- [ ] **Step 4: Wire scene to systems**

`vertical_slice.tscn` owns controller/model instances and delegates visuals to renderer/HUD. No UI node writes directly into terrain arrays.

- [ ] **Step 5: Manual smoke test**

Run: `godot --path .`
Verify: camera, selection, Prepare, dig, undo, cancel, trigger, collapse animation, relay status and objective visibility.

- [ ] **Step 6: Commit**

```bash
git add project.godot scenes src/view src/input src/ui
git commit -m "feat: add playable vertical slice presentation"
```

---

### Task 10: Integration, persistence and v0.1 acceptance

**Files:**
- Modify: `scenes/vertical_slice.tscn`
- Modify: `src/simulation/simulation_controller.gd`
- Modify: `src/save/save_system.gd`
- Modify: `tests/test_vertical_slice_acceptance.gd`
- Create: `README.md`

**Interfaces:**
- Final playable contract: launching project opens the vertical slice and all required v0.1 systems are usable without debug commands.

- [ ] **Step 1: Add autosave after every completed resolution**

Save only after returning to OBSERVER so no half-resolved state is persisted.

- [ ] **Step 2: Add load-on-start**

If `user://save_v1.json` exists and is schema v1, restore it. Otherwise build the deterministic initial cave.

- [ ] **Step 3: Add exit completion**

When the opened corridor reaches the exit zone, show `Accès aux profondeurs ouvert — Vertical slice terminé` and persist `objective_reached=true`.

- [ ] **Step 4: Run complete automated suite**

Run: `godot --headless --path . -s res://tests/test_runner.gd`
Expected: exit code 0, no assertion failures.

- [ ] **Step 5: Run two manual acceptance passes**

Pass A: canonical controlled collapse while preserving relay.
Pass B: intentionally cut the relay, undo before trigger, restore connection, then finish.

Expected in both: no corrupted terrain, no infinite resolution, energy behaves consistently, save/reload reproduces state.

- [ ] **Step 6: Document controls and v0.1 scope**

README must include Godot 4.7.2, how to run, how to run tests, controls, and explicit v0.1 exclusions from Global Constraints.

- [ ] **Step 7: Final commit**

```bash
git add README.md scenes src tests
git commit -m "feat: complete Project Digger v0.1 vertical slice"
```

---

## Acceptance Checklist

- [ ] Project opens with Godot 4.7.2 stable.
- [ ] All headless tests pass.
- [ ] Creuser, Déplacer and Fusionner work only in PREPARE.
- [ ] Invalid actions consume no energy.
- [ ] Undo and cancel restore deterministic state before trigger.
- [ ] Stability preview uses Stable/Fragile/Critical.
- [ ] Trigger resolves collapses and terminates within iteration limit.
- [ ] Dense rock cannot be dug with initial tool.
- [ ] Stabilizer can materially change stability.
- [ ] Relay starts connected and can be cut by terrain destruction.
- [ ] Canonical solution can preserve relay while opening the exit.
- [ ] Save/reload reproduces modified terrain and relay state.
- [ ] UI never becomes gameplay authority.
- [ ] No out-of-scope v0.1 system is introduced.
