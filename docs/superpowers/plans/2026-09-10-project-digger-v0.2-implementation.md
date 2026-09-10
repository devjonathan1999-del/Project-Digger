# Project Digger v0.2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the validated v0.1 technical vertical slice into the first game-like Project Digger cave with organic terrain presentation, contextual tactical readability, a compact HUD, and concise audiovisual collapse feedback.

**Architecture:** Keep `TerrainModel`, `TerrainActions`, `StabilitySystem`, `SimulationController`, `AncientNetwork`, and `SaveSystem` authoritative. Add presentation-only helpers around them: deterministic terrain visual profiling, cave backdrop/ancient overlays, contextual HUD/hover flow, and a feedback controller that consumes resolved movement events without changing simulation outcomes. Preserve the 64×72 logical grid and the synchronous deterministic resolution API while delaying the UI call by 0.12 s for presentation.

**Tech Stack:** Godot 4.7.2 stable, GDScript, CanvasItem/Node2D drawing, `AudioStreamWAV` procedural placeholder cues, custom headless test runner, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-09-10-project-digger-v0.2-design.md`

## Global Constraints

- Godot target is exactly 4.7.2 stable in CI.
- Keep the authoritative terrain grid at 64×72 cells with `TerrainRenderer.CELL_SIZE == 16` for v0.2.
- Observer mode must not display a global grid.
- Prepare mode may reveal logical boundaries only for hovered, selected, targeted, or analyzed cells.
- Rendering and feedback must never modify `TerrainModel` or decide simulation outcomes.
- `SimulationController.trigger_resolution()` remains synchronous and deterministic.
- Raw mouse hover emits no audio cue.
- Existing keyboard controls remain supported.
- v0.1 saves without a content identifier are incompatible with the new cave and start fresh; no migration is required.
- The v0.2 content identifier is `cave_v02_helix_01`.
- No minimap, colony system, economy, timers, advanced fluids/heat/gas, adaptive music, procedural cave generation, mobile controls, or new biome is added in this plan.
- Every implementation task ends with the full headless command: `godot --headless --path . -s res://tests/test_runner.gd` or the equivalent Godot 4.7.2 executable in CI.

---

## File Structure Locked by This Plan

### Existing files modified

- `.github/workflows/godot-tests.yml` — CI branch coverage.
- `src/content/vertical_slice_layout.gd` — v0.2 cave content and metadata.
- `src/save/save_system.gd` — content-aware save loading.
- `src/view/terrain_renderer.gd` — organic foreground, local hover/selection/analysis rendering.
- `src/view/game_camera.gd` — presentation-only camera impulse.
- `src/input/game_input.gd` — hover events.
- `src/ui/hud.gd` — status strip, tool/action bar, contextual cell panel.
- `src/terrain/stability_system.gd` — resolved movement metadata gains `material_id`.
- `src/vertical_slice.gd` — orchestration only: hover context, cave presentation, feedback timing, save content ID.
- `scenes/vertical_slice.tscn` — presentation/feedback nodes.
- `tests/test_runner.gd` — registers new deterministic suites.
- `tests/test_save_system.gd` — content compatibility cases.
- `tests/test_vertical_slice_acceptance.gd` — new cave acceptance contract.
- `README.md` — v0.2 behavior and controls.

### New files created

- `src/view/terrain_visual_profile.gd` — deterministic colors, display names, edge/detail variation.
- `src/view/cave_backdrop.gd` — non-authoritative cavern depth layer.
- `src/view/ancient_overlay.gd` — visual ancient conductor/relay layer.
- `src/feedback/feedback_classifier.gd` — pure movement-to-intensity classification.
- `src/feedback/resolution_fx.gd` — dust/debris and impact flashes.
- `src/feedback/procedural_audio.gd` — original runtime-generated placeholder tones.
- `src/feedback/feedback_controller.gd` — coordinates camera, FX, relay pulse, and audio.
- `tests/test_terrain_visual_profile.gd` — deterministic presentation helper tests.
- `tests/test_feedback_classifier.gd` — feedback intensity tests.
- `tests/test_procedural_audio.gd` — generated cue validity tests.
- `tests/test_scene_contract.gd` — scene composition smoke contract.

---

### Task 1: Enable v0.2 CI and make saves content-aware

**Files:**
- Modify: `.github/workflows/godot-tests.yml`
- Modify: `src/content/vertical_slice_layout.gd`
- Modify: `src/save/save_system.gd`
- Modify: `src/vertical_slice.gd`
- Modify: `tests/test_save_system.gd`

**Interfaces:**
- Produces: `VerticalSliceLayout.CONTENT_ID: String = "cave_v02_helix_01"`
- Produces: `SaveSystem.load_default_for_content(content_id: String) -> Dictionary`
- Produces: `SaveSystem.load_from_path_for_content(path: String, content_id: String) -> Dictionary`
- Save payload gains optional string key `content_id`; schema version remains `1`.

- [ ] **Step 1: Write failing save compatibility tests**

Add three cases to `tests/test_save_system.gd` using a temporary path:

```gdscript
func test_content_compatibility(t: TestSupport) -> void:
    var path := "user://test_save_content.json"
    var model := TerrainModel.new(2, 2)
    model.set_cell(Vector2i(0, 0), TerrainCell.new(&"rock_common"))
    var save := SaveSystem.new()

    t.equal(save.save_to_path(path, model, {
        "cycle_state": SimulationController.OBSERVER,
        "content_id": "cave_v02_helix_01",
    }), true, "sauvegarde avec identifiant de contenu")

    var compatible := save.load_from_path_for_content(path, "cave_v02_helix_01")
    t.equal(String(compatible.get("content_id", "")), "cave_v02_helix_01", "contenu compatible restauré")

    var different := save.load_from_path_for_content(path, "another_cave")
    t.equal(different.is_empty(), true, "autre contenu rejeté")

    var old_path := "user://test_save_v01_without_content.json"
    var old_payload := {
        "version": SaveSystem.SAVE_VERSION,
        "terrain": model.snapshot(),
        "relay_connected": true,
        "cycle_state": SimulationController.OBSERVER,
        "objective_reached": false,
    }
    var old_file := FileAccess.open(old_path, FileAccess.WRITE)
    old_file.store_string(JSON.stringify(old_payload))
    old_file.close()
    t.equal(save.load_from_path_for_content(old_path, "cave_v02_helix_01").is_empty(), true, "save v0.1 sans content_id rejetée")

    DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    DirAccess.remove_absolute(ProjectSettings.globalize_path(old_path))
```

- [ ] **Step 2: Run the suite and verify the new API is missing**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected: FAIL/parser failure because `load_from_path_for_content` does not exist yet.

- [ ] **Step 3: Add the stable cave content identifier**

At the top of `src/content/vertical_slice_layout.gd`:

```gdscript
const CONTENT_ID := "cave_v02_helix_01"
```

- [ ] **Step 4: Persist and filter by `content_id` without bumping save version**

In `src/save/save_system.gd`, add:

```gdscript
func load_default_for_content(content_id: String) -> Dictionary:
    return load_from_path_for_content(DEFAULT_PATH, content_id)

func load_from_path_for_content(path: String, content_id: String) -> Dictionary:
    var data := load_from_path(path)
    if data.is_empty():
        return {}
    if String(data.get("content_id", "")) != content_id:
        return {}
    return data
```

Add the field to the dictionary written by `save_to_path`:

```gdscript
"content_id": String(extra.get("content_id", "")),
```

Do not change `SAVE_VERSION`.

- [ ] **Step 5: Make the vertical slice load/save only its own cave**

Replace the load call in `src/vertical_slice.gd`:

```gdscript
var saved := _save_system.load_default_for_content(VerticalSliceLayout.CONTENT_ID)
```

Add the content ID to `_autosave()`:

```gdscript
"content_id": VerticalSliceLayout.CONTENT_ID,
```

- [ ] **Step 6: Move CI branch coverage from v0.1 to v0.2**

Change `.github/workflows/godot-tests.yml` branch list to:

```yaml
on:
  push:
    branches:
      - feature/digger-v0.2
      - main
  workflow_dispatch:
```

- [ ] **Step 7: Run all tests**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected: PASS, exit code 0.

- [ ] **Step 8: Commit**

```bash
git add .github/workflows/godot-tests.yml src/content/vertical_slice_layout.gd src/save/save_system.gd src/vertical_slice.gd tests/test_save_system.gd
git commit -m "feat: make v0.2 saves content aware"
```

---

### Task 2: Replace the technical bands with the first real cave layout

**Files:**
- Modify: `src/content/vertical_slice_layout.gd`
- Modify: `tests/test_vertical_slice_acceptance.gd`

**Interfaces:**
- `VerticalSliceLayout.build() -> Dictionary` keeps `model`, `relay_source`, `relay_pos`, `exit_rect`, `spawn_focus`.
- Adds `entrance_rect: Rect2i`, `chamber_rect: Rect2i`, `ancient_path: Array[Vector2i]`.
- Keeps `GATE_POS` and `SUPPORT_REMOVAL` as the canonical deterministic collapse solution.

- [ ] **Step 1: Rewrite acceptance expectations first**

Extend `tests/test_vertical_slice_acceptance.gd` with these checks immediately after `data` is built:

```gdscript
var entrance_rect: Rect2i = data["entrance_rect"]
var chamber_rect: Rect2i = data["chamber_rect"]
var ancient_path: Array[Vector2i] = data["ancient_path"]

t.equal(model.width, 64, "largeur cave v0.2")
t.equal(model.height, 72, "hauteur cave v0.2")
t.equal(entrance_rect, Rect2i(6, 5, 20, 12), "zone d'entrée contractuelle")
t.equal(chamber_rect, Rect2i(18, 22, 28, 36), "chambre centrale contractuelle")
t.check(ancient_path.size() >= 12, "réseau ancien visuellement exploitable")
t.equal(ancient_path.front(), data["relay_source"], "chemin ancien commence à la source")
t.equal(ancient_path.back(), data["relay_pos"], "chemin ancien termine au relais")
```

Add a material-presence scan:

```gdscript
var counts := {
    &"rock_common": 0,
    &"rock_fragile": 0,
    &"rock_dense": 0,
    &"stabilizer": 0,
}
for y in range(model.height):
    for x in range(model.width):
        var cell := model.get_cell(Vector2i(x, y))
        if cell != null and counts.has(cell.material_id):
            counts[cell.material_id] += 1
for material_id in counts.keys():
    t.check(int(counts[material_id]) > 0, "matière présente: %s" % material_id)
```

Keep the canonical support-removal, gate-fall, exit-open, and relay-preserved assertions already present.

- [ ] **Step 2: Run tests and verify the new metadata fails**

Run the full headless suite.

Expected: FAIL because `entrance_rect`, `chamber_rect`, and `ancient_path` are absent.

- [ ] **Step 3: Rebuild the cave with irregular stepped masses instead of horizontal test bands**

Keep the existing helper `_fill_rect` and replace `build()` with a composition following this exact macro structure:

```gdscript
func build() -> Dictionary:
    var model := TerrainModel.new(WIDTH, HEIGHT)

    # Anchored outer geology.
    _fill_rect(model, Rect2i(0, 0, 6, HEIGHT), &"rock_dense")
    _fill_rect(model, Rect2i(58, 0, 6, HEIGHT), &"rock_dense")
    _fill_rect(model, Rect2i(6, 0, 52, 4), &"rock_dense")

    # Entrance pocket: stepped common/fragile ledges instead of a flat band.
    _fill_rect(model, Rect2i(6, 8, 12, 3), &"rock_common")
    _fill_rect(model, Rect2i(8, 11, 10, 2), &"rock_common")
    _fill_rect(model, Rect2i(14, 13, 10, 2), &"rock_fragile")
    _fill_rect(model, Rect2i(20, 15, 6, 2), &"rock_common")

    # Left chamber shelves and stabilizer deposit.
    _fill_rect(model, Rect2i(6, 24, 10, 4), &"rock_common")
    _fill_rect(model, Rect2i(10, 28, 9, 3), &"rock_fragile")
    _fill_rect(model, Rect2i(12, 31, 7, 2), &"stabilizer")
    _fill_rect(model, Rect2i(6, 34, 12, 3), &"rock_common")

    # Central chamber framing.
    _fill_rect(model, Rect2i(18, 38, 8, 4), &"rock_common")
    _fill_rect(model, Rect2i(41, 30, 17, 4), &"rock_common")
    _fill_rect(model, Rect2i(44, 34, 14, 3), &"rock_fragile")
    _fill_rect(model, Rect2i(46, 50, 12, 5), &"rock_common")

    # Dense blocking formation and stable side masses.
    _fill_rect(model, Rect2i(26, 40, 5, 32), &"rock_dense")
    _fill_rect(model, Rect2i(34, 40, 7, 32), &"rock_dense")
    _fill_rect(model, Rect2i(29, 39, 7, 3), &"rock_dense")
    model.set_cell(GATE_POS, TerrainCell.new(&"rock_dense"))

    # Canonical removable supports.
    for support_pos in SUPPORT_REMOVAL:
        model.set_cell(support_pos, TerrainCell.new(&"rock_common"))

    # Stable spine and ancient route.
    _fill_rect(model, Rect2i(24, 46, 1, 26), &"rock_dense")
    var relay_source := Vector2i(18, 54)
    var relay_pos := Vector2i(25, 46)
    var ancient_path: Array[Vector2i] = []
    for x in range(18, 26):
        ancient_path.append(Vector2i(x, 54))
    for y in range(53, 45, -1):
        ancient_path.append(Vector2i(25, y))
    for pos in ancient_path:
        model.set_cell(pos, TerrainCell.new(&"stabilizer"))

    # Lower descent framing.
    _fill_rect(model, Rect2i(6, 58, 18, 6), &"rock_common")
    _fill_rect(model, Rect2i(41, 58, 17, 6), &"rock_common")
    _fill_rect(model, Rect2i(8, 64, 16, 8), &"rock_dense")
    _fill_rect(model, Rect2i(41, 64, 17, 8), &"rock_dense")

    return {
        "model": model,
        "relay_source": relay_source,
        "relay_pos": relay_pos,
        "ancient_path": ancient_path,
        "entrance_rect": Rect2i(6, 5, 20, 12),
        "chamber_rect": Rect2i(18, 22, 28, 36),
        "exit_rect": Rect2i(31, 65, 3, 5),
        "spawn_focus": Vector2i(22, 12),
    }
```

If the added decorative masses accidentally alter the canonical collapse, adjust only non-canonical surrounding rectangles; do not change stability rules to make the level pass.

- [ ] **Step 4: Run the acceptance test through the full runner**

Run the full headless suite.

Expected: PASS, including gate fall, exit corridor clear, and relay preserved.

- [ ] **Step 5: Commit**

```bash
git add src/content/vertical_slice_layout.gd tests/test_vertical_slice_acceptance.gd
git commit -m "feat: build first Helix cave layout"
```

---

### Task 3: Add a deterministic visual profile for terrain materials

**Files:**
- Create: `src/view/terrain_visual_profile.gd`
- Create: `tests/test_terrain_visual_profile.gd`
- Modify: `tests/test_runner.gd`

**Interfaces:**
- Produces: `TerrainVisualProfile.base_color(material_id: StringName) -> Color`
- Produces: `TerrainVisualProfile.detail_color(material_id: StringName) -> Color`
- Produces: `TerrainVisualProfile.display_name(material_id: StringName) -> String`
- Produces: `TerrainVisualProfile.edge_inset(pos: Vector2i, edge: int) -> float`
- Produces: `TerrainVisualProfile.detail_variant(pos: Vector2i, material_id: StringName) -> int`

- [ ] **Step 1: Register a failing test suite**

Add to `tests/test_runner.gd` before the vertical-slice acceptance suite:

```gdscript
preload("res://tests/test_terrain_visual_profile.gd"),
```

Create `tests/test_terrain_visual_profile.gd`:

```gdscript
extends RefCounted

func run(t: TestSupport) -> void:
    var pos := Vector2i(12, 31)
    t.equal(TerrainVisualProfile.display_name(&"rock_common"), "Roche commune", "nom roche commune")
    t.equal(TerrainVisualProfile.display_name(&"rock_fragile"), "Roche fragile", "nom roche fragile")
    t.equal(TerrainVisualProfile.display_name(&"rock_dense"), "Roche dense", "nom roche dense")
    t.equal(TerrainVisualProfile.display_name(&"stabilizer"), "Minerai stabilisateur", "nom stabilisant")

    var first := TerrainVisualProfile.edge_inset(pos, 0)
    var second := TerrainVisualProfile.edge_inset(pos, 0)
    t.equal(first, second, "variation d'arête déterministe")
    t.check(first >= 0.0 and first <= 3.0, "inset reste local à la cellule")

    var variant := TerrainVisualProfile.detail_variant(pos, &"rock_fragile")
    t.check(variant >= 0 and variant <= 3, "variante de détail bornée")
```

- [ ] **Step 2: Run tests and verify the class is missing**

Expected: FAIL because `TerrainVisualProfile` does not exist.

- [ ] **Step 3: Implement the pure visual profile**

Create `src/view/terrain_visual_profile.gd`:

```gdscript
class_name TerrainVisualProfile
extends RefCounted

enum Edge { TOP, RIGHT, BOTTOM, LEFT }

static func base_color(material_id: StringName) -> Color:
    match material_id:
        &"rock_common": return Color("#626b75")
        &"rock_fragile": return Color("#8b715c")
        &"rock_dense": return Color("#303944")
        &"stabilizer": return Color("#249b9a")
        _: return Color("#686d73")

static func detail_color(material_id: StringName) -> Color:
    match material_id:
        &"rock_common": return Color("#7a838d")
        &"rock_fragile": return Color("#b28a67")
        &"rock_dense": return Color("#46515d")
        &"stabilizer": return Color("#68e2dc")
        _: return Color("#80858a")

static func display_name(material_id: StringName) -> String:
    match material_id:
        &"rock_common": return "Roche commune"
        &"rock_fragile": return "Roche fragile"
        &"rock_dense": return "Roche dense"
        &"stabilizer": return "Minerai stabilisateur"
        _: return "Matière inconnue"

static func edge_inset(pos: Vector2i, edge: int) -> float:
    return float(_key(pos, edge + 17) % 4)

static func detail_variant(pos: Vector2i, material_id: StringName) -> int:
    return _key(pos, _material_salt(material_id)) % 4

static func _material_salt(material_id: StringName) -> int:
    match material_id:
        &"rock_common": return 11
        &"rock_fragile": return 23
        &"rock_dense": return 37
        &"stabilizer": return 53
        _: return 71

static func _key(pos: Vector2i, salt: int) -> int:
    var value := pos.x * 73856093
    value = value ^ (pos.y * 19349663)
    value = value ^ (salt * 83492791)
    return absi(value)
```

- [ ] **Step 4: Run all tests**

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/view/terrain_visual_profile.gd tests/test_terrain_visual_profile.gd tests/test_runner.gd
git commit -m "feat: add deterministic terrain visual profile"
```

---

### Task 4: Render organic terrain and local tactical precision

**Files:**
- Modify: `src/view/terrain_renderer.gd`
- Modify: `tests/test_terrain_visual_profile.gd`

**Interfaces:**
- Produces: `TerrainRenderer.set_prepare_mode(enabled: bool) -> void`
- Produces: `TerrainRenderer.set_hovered_cell(cell: Vector2i) -> void`
- Produces: `TerrainRenderer.clear_hovered_cell() -> void`
- Produces: `TerrainRenderer.cell_from_local(local_pos: Vector2) -> Vector2i`
- Existing `cell_from_screen`, `set_analysis`, `set_selection`, `animate_movements` remain available.

- [ ] **Step 1: Add a pure coordinate conversion assertion**

Append to `tests/test_terrain_visual_profile.gd`:

```gdscript
var renderer := TerrainRenderer.new()
t.equal(renderer.cell_from_local(Vector2(0.0, 0.0)), Vector2i(0, 0), "origine vers cellule 0,0")
t.equal(renderer.cell_from_local(Vector2(31.9, 48.1)), Vector2i(1, 3), "conversion locale respecte CELL_SIZE")
```

- [ ] **Step 2: Run tests and verify `cell_from_local` is missing**

Expected: FAIL.

- [ ] **Step 3: Add renderer state for mode and hover**

In `src/view/terrain_renderer.gd` add:

```gdscript
var _prepare_mode := false
var _hovered_cell := Vector2i.ZERO
var _has_hover := false

func set_prepare_mode(enabled: bool) -> void:
    _prepare_mode = enabled
    queue_redraw()

func set_hovered_cell(cell: Vector2i) -> void:
    _hovered_cell = cell
    _has_hover = true
    queue_redraw()

func clear_hovered_cell() -> void:
    _has_hover = false
    queue_redraw()

func cell_from_local(local_pos: Vector2) -> Vector2i:
    return Vector2i(
        int(floor(local_pos.x / float(CELL_SIZE))),
        int(floor(local_pos.y / float(CELL_SIZE)))
    )
```

Refactor `cell_from_screen` to end with:

```gdscript
return cell_from_local(to_local(world_pos))
```

- [ ] **Step 4: Replace flat rectangles with neighbor-aware polygons**

Add helpers:

```gdscript
func _has_cell(pos: Vector2i) -> bool:
    return pos.x >= 0 and pos.y >= 0 and pos.x < _model.width and pos.y < _model.height and _model.get_cell(pos) != null

func _cell_polygon(pos: Vector2i) -> PackedVector2Array:
    var origin := Vector2(pos.x * CELL_SIZE, pos.y * CELL_SIZE)
    var top := TerrainVisualProfile.edge_inset(pos, TerrainVisualProfile.Edge.TOP) if not _has_cell(pos + Vector2i.UP) else 0.0
    var right := TerrainVisualProfile.edge_inset(pos, TerrainVisualProfile.Edge.RIGHT) if not _has_cell(pos + Vector2i.RIGHT) else 0.0
    var bottom := TerrainVisualProfile.edge_inset(pos, TerrainVisualProfile.Edge.BOTTOM) if not _has_cell(pos + Vector2i.DOWN) else 0.0
    var left := TerrainVisualProfile.edge_inset(pos, TerrainVisualProfile.Edge.LEFT) if not _has_cell(pos + Vector2i.LEFT) else 0.0
    return PackedVector2Array([
        origin + Vector2(left, top),
        origin + Vector2(CELL_SIZE - right, top),
        origin + Vector2(CELL_SIZE - right, CELL_SIZE - bottom),
        origin + Vector2(left, CELL_SIZE - bottom),
    ])
```

In `_draw`, draw each solid cell with `draw_colored_polygon(_cell_polygon(pos), color)` instead of `draw_rect` for the base terrain. Use `TerrainVisualProfile.base_color` and `detail_color`; add at most one deterministic material detail per cell using `detail_variant`, such as a short crack line for fragile rock and a small diamond for stabilizer. Do not draw cell borders globally.

- [ ] **Step 5: Restrict tactical overlays to Prepare mode and local targets**

Guard analysis rendering:

```gdscript
if _prepare_mode and _analysis.has(pos):
    draw_colored_polygon(_cell_polygon(pos), _analysis_color(int(_analysis[pos])))
```

Draw selection outlines as before but using the cell polygon instead of a full grid rectangle. Draw hover only when `_has_hover` and the hovered position contains terrain:

```gdscript
if _has_hover and _model.get_cell(_hovered_cell) != null:
    var hover_poly := _cell_polygon(_hovered_cell)
    var outline := PackedVector2Array(hover_poly)
    outline.append(hover_poly[0])
    draw_polyline(outline, Color(0.85, 0.95, 1.0, 0.9), 2.0, true)
```

- [ ] **Step 6: Run all headless tests**

Expected: PASS. Visual quality is not proven by this run.

- [ ] **Step 7: Commit**

```bash
git add src/view/terrain_renderer.gd tests/test_terrain_visual_profile.gd
git commit -m "feat: render terrain with organic local edges"
```

---

### Task 5: Add hover flow and redesign the HUD around context

**Files:**
- Modify: `src/input/game_input.gd`
- Modify: `src/ui/hud.gd`
- Modify: `src/vertical_slice.gd`

**Interfaces:**
- `GameInput` produces `signal hover_changed(cell: Vector2i)`.
- `DiggerHUD` produces `signal tool_pressed(tool: StringName)`.
- `DiggerHUD` produces `set_context(material_name: String, action_name: String, cost: int, actionable: bool) -> void`.
- `DiggerHUD` produces `clear_context() -> void` and `set_busy(value: bool) -> void`.
- Existing prepare/trigger/cancel/undo signals remain.

- [ ] **Step 1: Add hover emission to `GameInput`**

Add the signal:

```gdscript
signal hover_changed(cell: Vector2i)
```

At the top of `_unhandled_input`, before action-button handling:

```gdscript
if event is InputEventMouseMotion and _renderer != null:
    hover_changed.emit(_renderer.cell_from_screen(event.position))
```

Do not emit audio here.

- [ ] **Step 2: Rebuild the HUD hierarchy as a top status strip plus bottom tool/action bar**

Keep `DiggerHUD` as a `CanvasLayer`, but replace the single large panel with two `PanelContainer`s. The top strip contains state, energy, relay, objective. The bottom bar contains `Creuser`, `Déplacer`, `Fusionner`, `Préparer`, and in Prepare mode `Déclencher`, `Annuler`, `Undo`.

Add signals and fields:

```gdscript
signal tool_pressed(tool: StringName)

var _tool_buttons: Dictionary = {}
var _context_panel: PanelContainer
var _context_label: Label
var _busy := false
```

Create tool buttons with callbacks:

```gdscript
_tool_buttons[&"dig"] = _make_button(tool_row, "1  Creuser", func() -> void: tool_pressed.emit(&"dig"))
_tool_buttons[&"move"] = _make_button(tool_row, "2  Déplacer", func() -> void: tool_pressed.emit(&"move"))
_tool_buttons[&"fuse"] = _make_button(tool_row, "3  Fusionner", func() -> void: tool_pressed.emit(&"fuse"))
```

Use `StyleBoxFlat` rather than image assets for v0.2 styling. The shared panel style should use a dark translucent fill and small rounded corners:

```gdscript
func _panel_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.035, 0.055, 0.07, 0.90)
    style.border_color = Color(0.18, 0.55, 0.62, 0.45)
    style.set_border_width_all(1)
    style.set_corner_radius_all(6)
    return style
```

- [ ] **Step 3: Add contextual cell information**

Implement:

```gdscript
func set_context(material_name: String, action_name: String, cost: int, actionable: bool) -> void:
    if _context_panel == null or _context_label == null:
        return
    _context_panel.visible = true
    if actionable:
        _context_label.text = "%s\n%s · Énergie %d" % [material_name, action_name, cost]
    else:
        _context_label.text = "%s\nAction indisponible" % material_name

func clear_context() -> void:
    if _context_panel != null:
        _context_panel.visible = false
```

Implement `set_busy` and include `_busy` in `_refresh_buttons()` so all action buttons are disabled during the 0.12 s trigger anticipation.

- [ ] **Step 4: Keep selected-tool state visually explicit**

In `set_tool`, update the active button disabled/pressed appearance in addition to the label state. Use the existing text labels if needed, but only one tool button may appear selected at a time.

- [ ] **Step 5: Wire tool clicks and hover context in `src/vertical_slice.gd`**

Add a catalog:

```gdscript
var _catalog := MaterialCatalog.new()
```

Connect:

```gdscript
game_input.hover_changed.connect(_on_hover_changed)
hud.tool_pressed.connect(game_input.set_active_tool)
```

Implement:

```gdscript
func _on_hover_changed(cell: Vector2i) -> void:
    if cell.x < 0 or cell.y < 0 or cell.x >= model.width or cell.y >= model.height:
        terrain_renderer.clear_hovered_cell()
        hud.clear_context()
        return

    terrain_renderer.set_hovered_cell(cell)
    if controller.state != SimulationController.PREPARE:
        hud.clear_context()
        return

    var terrain_cell := model.get_cell(cell)
    if terrain_cell == null:
        hud.clear_context()
        return

    var material := _catalog.get_def(terrain_cell.material_id)
    var actionable := false
    var cost := 0
    var action_name := ""
    match game_input.active_tool:
        &"dig":
            action_name = "Creuser"
            cost = TerrainActions.DIG_COST
            actionable = material != null and material.diggable and controller.terrain_actions.energy_remaining >= cost
        &"move":
            action_name = "Déplacer"
            cost = TerrainActions.MOVE_COST
            actionable = controller.terrain_actions.energy_remaining >= cost
        &"fuse":
            action_name = "Fusionner"
            cost = TerrainActions.FUSE_COST
            actionable = controller.terrain_actions.energy_remaining >= cost

    hud.set_context(TerrainVisualProfile.display_name(terrain_cell.material_id), action_name, cost, actionable)
```

- [ ] **Step 6: Synchronize Prepare/Observer presentation state**

In `_on_state_changed`:

```gdscript
terrain_renderer.set_prepare_mode(value == SimulationController.PREPARE)
if value != SimulationController.PREPARE:
    hud.clear_context()
```

- [ ] **Step 7: Run all tests and launch manually once**

Headless expected: PASS.

Manual check in Godot: Observer shows no analysis grid; Prepare shows local hover/analysis; tool buttons are clickable; keyboard shortcuts still work.

- [ ] **Step 8: Commit**

```bash
git add src/input/game_input.gd src/ui/hud.gd src/vertical_slice.gd
git commit -m "feat: add contextual prepare HUD and hover"
```

---

### Task 6: Add cavern depth and the ancient visual layer

**Files:**
- Create: `src/view/cave_backdrop.gd`
- Create: `src/view/ancient_overlay.gd`
- Modify: `scenes/vertical_slice.tscn`
- Modify: `src/vertical_slice.gd`
- Modify: `tests/test_scene_contract.gd`
- Modify: `tests/test_runner.gd`

**Interfaces:**
- `CaveBackdrop.configure(size_cells: Vector2i, cell_size: int) -> void`
- `AncientOverlay.configure(path: Array[Vector2i], relay_pos: Vector2i, cell_size: int) -> void`
- `AncientOverlay.set_connected(value: bool) -> void`
- `AncientOverlay.pulse() -> void`

- [ ] **Step 1: Create and register a failing scene contract**

Add to `tests/test_runner.gd`:

```gdscript
preload("res://tests/test_scene_contract.gd"),
```

Create `tests/test_scene_contract.gd`:

```gdscript
extends RefCounted

func run(t: TestSupport) -> void:
    var packed := load("res://scenes/vertical_slice.tscn") as PackedScene
    t.check(packed != null, "scene vertical slice chargeable")
    var scene := packed.instantiate()
    t.check(scene.get_node_or_null("CaveBackdrop") != null, "fond de caverne présent")
    t.check(scene.get_node_or_null("TerrainRenderer") != null, "renderer terrain présent")
    t.check(scene.get_node_or_null("AncientOverlay") != null, "overlay ancien présent")
    scene.free()
```

- [ ] **Step 2: Run tests and verify the scene nodes are missing**

Expected: FAIL on `CaveBackdrop` and `AncientOverlay`.

- [ ] **Step 3: Implement a non-interactive cave backdrop**

Create `src/view/cave_backdrop.gd`:

```gdscript
class_name CaveBackdrop
extends Node2D

var _size_px := Vector2(1024, 1152)

func configure(size_cells: Vector2i, cell_size: int) -> void:
    _size_px = Vector2(size_cells.x * cell_size, size_cells.y * cell_size)
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, _size_px), Color("#09131c"), true)
    draw_rect(Rect2(Vector2(0, _size_px.y * 0.35), Vector2(_size_px.x, _size_px.y * 0.65)), Color("#0d1820"), true)

    var far_arches := PackedVector2Array([
        Vector2(80, _size_px.y * 0.58),
        Vector2(190, _size_px.y * 0.42),
        Vector2(300, _size_px.y * 0.56),
        Vector2(430, _size_px.y * 0.38),
        Vector2(570, _size_px.y * 0.57),
        Vector2(720, _size_px.y * 0.43),
        Vector2(900, _size_px.y * 0.60),
        Vector2(900, _size_px.y),
        Vector2(80, _size_px.y),
    ])
    draw_colored_polygon(far_arches, Color("#111f29"))

    for x in range(90, int(_size_px.x), 180):
        draw_circle(Vector2(x, _size_px.y * 0.72), 28.0, Color(0.42, 0.29, 0.17, 0.08))
```

This layer is purely decorative and never receives `TerrainModel`.

- [ ] **Step 4: Implement the ancient conductor/relay overlay**

Create `src/view/ancient_overlay.gd`:

```gdscript
class_name AncientOverlay
extends Node2D

var _path: Array[Vector2i] = []
var _relay_pos := Vector2i.ZERO
var _cell_size := 16
var _connected := false
var _pulse_alpha := 0.0

func configure(path: Array[Vector2i], relay_pos: Vector2i, cell_size: int) -> void:
    _path.assign(path)
    _relay_pos = relay_pos
    _cell_size = cell_size
    queue_redraw()

func set_connected(value: bool) -> void:
    _connected = value
    queue_redraw()

func pulse() -> void:
    _pulse_alpha = 1.0
    var tween := create_tween()
    tween.tween_method(_set_pulse_alpha, 1.0, 0.0, 0.28)

func _set_pulse_alpha(value: float) -> void:
    _pulse_alpha = value
    queue_redraw()

func _center(cell: Vector2i) -> Vector2:
    return Vector2((cell.x + 0.5) * _cell_size, (cell.y + 0.5) * _cell_size)

func _draw() -> void:
    if _path.size() >= 2:
        var points := PackedVector2Array()
        for cell in _path:
            points.append(_center(cell))
        var base := Color(0.20, 0.95, 0.92, 0.85 if _connected else 0.25)
        draw_polyline(points, base, 2.0, true)
        if _pulse_alpha > 0.0:
            draw_polyline(points, Color(0.65, 1.0, 0.98, _pulse_alpha), 5.0, true)
    draw_circle(_center(_relay_pos), 9.0, Color(0.20, 0.95, 0.92, 0.90 if _connected else 0.30))
    draw_circle(_center(_relay_pos), 4.0, Color("#d6fffb"))
```

- [ ] **Step 5: Add the nodes in correct draw order**

Update `scenes/vertical_slice.tscn` ext resources and nodes so the order is:

```text
VerticalSlice
├── CaveBackdrop
├── TerrainRenderer
├── AncientOverlay
├── GameCamera
├── GameInput
└── HUD
```

`CaveBackdrop` must render before terrain; `AncientOverlay` must render after terrain.

- [ ] **Step 6: Configure presentation from layout data**

In `src/vertical_slice.gd` add onready refs and configure them in `_ready()`:

```gdscript
@onready var cave_backdrop: CaveBackdrop = $CaveBackdrop
@onready var ancient_overlay: AncientOverlay = $AncientOverlay
```

```gdscript
cave_backdrop.configure(Vector2i(model.width, model.height), TerrainRenderer.CELL_SIZE)
ancient_overlay.configure(_layout_data["ancient_path"], _layout_data["relay_pos"], TerrainRenderer.CELL_SIZE)
ancient_overlay.set_connected(controller.relay_connected)
```

Update relay state in `_refresh_prepare_state`, `_on_cancel_requested`, and `_on_resolution_finished` by calling `ancient_overlay.set_connected(...)` beside the HUD update.

- [ ] **Step 7: Run all tests and visually inspect once**

Expected headless: PASS.

Manual: background adds depth without obscuring foreground; ancient route reads separately from ordinary stabilizer material.

- [ ] **Step 8: Commit**

```bash
git add src/view/cave_backdrop.gd src/view/ancient_overlay.gd scenes/vertical_slice.tscn src/vertical_slice.gd tests/test_scene_contract.gd tests/test_runner.gd
git commit -m "feat: add cave depth and ancient visual layer"
```

---

### Task 7: Add collapse metadata and pure feedback classification

**Files:**
- Modify: `src/terrain/stability_system.gd`
- Create: `src/feedback/feedback_classifier.gd`
- Create: `tests/test_feedback_classifier.gd`
- Modify: `tests/test_stability_system.gd`
- Modify: `tests/test_runner.gd`

**Interfaces:**
- Each movement returned by `StabilitySystem.resolve()` now contains `from: Vector2i`, `to: Vector2i`, `material_id: StringName`.
- `FeedbackClassifier.classify_movements(movements: Array[Dictionary]) -> int`.
- Intensity constants: `NONE`, `LIGHT`, `HEAVY`.

- [ ] **Step 1: Assert movement material metadata before implementation**

In the existing stability resolution test, add:

```gdscript
t.check(not movements.is_empty(), "effondrement produit des mouvements")
t.check(movements[0].has("material_id"), "mouvement expose la matière pour le feedback")
```

- [ ] **Step 2: Create feedback classifier tests and register them**

Create `tests/test_feedback_classifier.gd`:

```gdscript
extends RefCounted

func run(t: TestSupport) -> void:
    t.equal(FeedbackClassifier.classify_movements([]), FeedbackClassifier.NONE, "aucun mouvement")

    var light: Array[Dictionary] = [
        {"from": Vector2i(1, 1), "to": Vector2i(1, 2), "material_id": &"rock_common"},
    ]
    t.equal(FeedbackClassifier.classify_movements(light), FeedbackClassifier.LIGHT, "petit effondrement")

    var heavy: Array[Dictionary] = [
        {"from": Vector2i(2, 2), "to": Vector2i(2, 3), "material_id": &"rock_dense"},
    ]
    t.equal(FeedbackClassifier.classify_movements(heavy), FeedbackClassifier.HEAVY, "roche dense donne impact lourd")
```

Register in `tests/test_runner.gd`.

- [ ] **Step 3: Run tests and verify both contracts fail**

Expected: FAIL for missing `material_id` and missing `FeedbackClassifier`.

- [ ] **Step 4: Add material ID to deterministic movement records**

In `StabilitySystem.resolve`, change the append to:

```gdscript
movements.append({
    "from": from,
    "to": to,
    "material_id": cell.material_id,
})
```

No stability math changes.

- [ ] **Step 5: Implement feedback classification**

Create `src/feedback/feedback_classifier.gd`:

```gdscript
class_name FeedbackClassifier
extends RefCounted

enum { NONE, LIGHT, HEAVY }

static func classify_movements(movements: Array[Dictionary]) -> int:
    if movements.is_empty():
        return NONE
    for movement in movements:
        if StringName(movement.get("material_id", &"")) == &"rock_dense":
            return HEAVY
    return LIGHT
```

- [ ] **Step 6: Run all tests**

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add src/terrain/stability_system.gd src/feedback/feedback_classifier.gd tests/test_feedback_classifier.gd tests/test_stability_system.gd tests/test_runner.gd
git commit -m "feat: classify collapse feedback intensity"
```

---

### Task 8: Add visual impact FX and proportional camera impulse

**Files:**
- Create: `src/feedback/resolution_fx.gd`
- Modify: `src/view/game_camera.gd`
- Modify: `scenes/vertical_slice.tscn`
- Modify: `tests/test_scene_contract.gd`

**Interfaces:**
- `GameCamera.play_impulse(strength: float) -> void`.
- `ResolutionFx.play_movements(movements: Array[Dictionary], cell_size: int) -> void`.
- `ResolutionFx.play_success(cell: Vector2i, cell_size: int) -> void`.

- [ ] **Step 1: Extend scene smoke contract**

Add to `tests/test_scene_contract.gd`:

```gdscript
t.check(scene.get_node_or_null("ResolutionFx") != null, "FX de résolution présents")
```

- [ ] **Step 2: Run tests and verify the node is missing**

Expected: FAIL.

- [ ] **Step 3: Implement deterministic camera impulse**

Add to `src/view/game_camera.gd`:

```gdscript
func play_impulse(strength: float) -> void:
    var amount := clampf(strength, 0.0, 8.0)
    if amount <= 0.0:
        return
    var tween := create_tween()
    tween.tween_property(self, "offset", Vector2(amount, -amount * 0.5), 0.04)
    tween.tween_property(self, "offset", Vector2(-amount * 0.55, amount * 0.35), 0.05)
    tween.tween_property(self, "offset", Vector2.ZERO, 0.08)
```

No random camera movement is needed.

- [ ] **Step 4: Implement dust/impact drawing**

Create `src/feedback/resolution_fx.gd`:

```gdscript
class_name ResolutionFx
extends Node2D

var _points: Array[Vector2] = []
var _alpha := 0.0
var _success_point: Variant = null

func play_movements(movements: Array[Dictionary], cell_size: int) -> void:
    _points.clear()
    var seen := {}
    for movement in movements:
        var cell: Vector2i = movement.get("to", Vector2i.ZERO)
        if seen.has(cell):
            continue
        seen[cell] = true
        _points.append(Vector2((cell.x + 0.5) * cell_size, (cell.y + 0.5) * cell_size))
        if _points.size() >= 12:
            break
    _alpha = 0.75 if not _points.is_empty() else 0.0
    queue_redraw()
    if _alpha > 0.0:
        var tween := create_tween()
        tween.tween_method(_set_alpha, _alpha, 0.0, 0.35)

func play_success(cell: Vector2i, cell_size: int) -> void:
    _success_point = Vector2((cell.x + 0.5) * cell_size, (cell.y + 0.5) * cell_size)
    _alpha = 1.0
    queue_redraw()
    var tween := create_tween()
    tween.tween_method(_set_alpha, 1.0, 0.0, 0.45)

func _set_alpha(value: float) -> void:
    _alpha = value
    queue_redraw()

func _draw() -> void:
    for point in _points:
        draw_circle(point, 7.0 + (1.0 - _alpha) * 5.0, Color(0.72, 0.67, 0.58, _alpha * 0.40))
    if _success_point != null and _alpha > 0.0:
        draw_circle(_success_point, 12.0 + (1.0 - _alpha) * 16.0, Color(0.30, 0.95, 0.88, _alpha), false, 2.0)
```

- [ ] **Step 5: Add `ResolutionFx` after `AncientOverlay` in the scene**

`scenes/vertical_slice.tscn` order becomes background → terrain → ancient overlay → resolution FX → camera/input/HUD.

- [ ] **Step 6: Run all tests and manually verify no persistent offset**

Headless expected: PASS.

Manual: after an impulse, `GameCamera.offset` returns to `Vector2.ZERO`; dust fades fully.

- [ ] **Step 7: Commit**

```bash
git add src/feedback/resolution_fx.gd src/view/game_camera.gd scenes/vertical_slice.tscn tests/test_scene_contract.gd
git commit -m "feat: add collapse visual impact feedback"
```

---

### Task 9: Add procedural audio and a feedback controller with trigger anticipation

**Files:**
- Create: `src/feedback/procedural_audio.gd`
- Create: `src/feedback/feedback_controller.gd`
- Create: `tests/test_procedural_audio.gd`
- Modify: `tests/test_runner.gd`
- Modify: `scenes/vertical_slice.tscn`
- Modify: `src/vertical_slice.gd`
- Modify: `tests/test_scene_contract.gd`

**Interfaces:**
- `ProceduralAudio.make_tone(frequency: float, duration: float, volume: float) -> AudioStreamWAV`.
- `FeedbackController.configure(camera: GameCamera, fx: ResolutionFx, ancient_overlay: AncientOverlay) -> void`.
- `FeedbackController.play_action(tool: StringName, material_id: StringName) -> void`.
- `FeedbackController.play_trigger_anticipation() -> void`.
- `FeedbackController.play_resolution(movements: Array[Dictionary], relay_connected: bool, objective_reached: bool, success_cell: Vector2i) -> void`.

- [ ] **Step 1: Create procedural audio tests**

Create `tests/test_procedural_audio.gd`:

```gdscript
extends RefCounted

func run(t: TestSupport) -> void:
    var stream := ProceduralAudio.make_tone(440.0, 0.08, 0.20)
    t.check(stream != null, "cue procédural créé")
    t.equal(stream.mix_rate, 22050, "mix rate stable")
    t.check(stream.data.size() > 100, "cue contient des échantillons")
```

Register it in `tests/test_runner.gd`.

- [ ] **Step 2: Extend scene contract for the feedback controller**

Add:

```gdscript
t.check(scene.get_node_or_null("FeedbackController") != null, "contrôleur de feedback présent")
```

- [ ] **Step 3: Run tests and verify missing classes/nodes**

Expected: FAIL.

- [ ] **Step 4: Implement original procedural placeholder tones**

Create `src/feedback/procedural_audio.gd`:

```gdscript
class_name ProceduralAudio
extends RefCounted

const MIX_RATE := 22050

static func make_tone(frequency: float, duration: float, volume: float) -> AudioStreamWAV:
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_8_BITS
    stream.mix_rate = MIX_RATE
    stream.stereo = false

    var sample_count := maxi(1, int(duration * MIX_RATE))
    var bytes := PackedByteArray()
    bytes.resize(sample_count)
    var amplitude := clampf(volume, 0.0, 1.0) * 127.0
    for i in range(sample_count):
        var envelope := 1.0 - float(i) / float(sample_count)
        var sample := sin(TAU * frequency * float(i) / float(MIX_RATE)) * amplitude * envelope
        bytes[i] = int(clampf(sample + 128.0, 0.0, 255.0))
    stream.data = bytes
    return stream
```

- [ ] **Step 5: Implement the presentation-only feedback controller**

Create `src/feedback/feedback_controller.gd`:

```gdscript
class_name FeedbackController
extends Node

var _camera: GameCamera
var _fx: ResolutionFx
var _ancient_overlay: AncientOverlay
var _audio: AudioStreamPlayer

func _ready() -> void:
    _audio = AudioStreamPlayer.new()
    add_child(_audio)

func configure(camera: GameCamera, fx: ResolutionFx, ancient_overlay: AncientOverlay) -> void:
    _camera = camera
    _fx = fx
    _ancient_overlay = ancient_overlay

func play_action(tool: StringName, material_id: StringName) -> void:
    var frequency := 250.0
    if tool == &"fuse" or material_id == &"stabilizer":
        frequency = 720.0
    elif material_id == &"rock_fragile":
        frequency = 360.0
    elif tool == &"move":
        frequency = 180.0
    _play_tone(frequency, 0.055, 0.12)

func play_trigger_anticipation() -> void:
    if _ancient_overlay != null:
        _ancient_overlay.pulse()
    _play_tone(520.0, 0.09, 0.10)

func play_resolution(movements: Array[Dictionary], relay_connected: bool, objective_reached: bool, success_cell: Vector2i) -> void:
    var intensity := FeedbackClassifier.classify_movements(movements)
    if _ancient_overlay != null:
        _ancient_overlay.set_connected(relay_connected)
    if _fx != null:
        _fx.play_movements(movements, TerrainRenderer.CELL_SIZE)
    if intensity == FeedbackClassifier.HEAVY:
        if _camera != null:
            _camera.play_impulse(6.0)
        _play_tone(105.0, 0.18, 0.22)
    elif intensity == FeedbackClassifier.LIGHT:
        if _camera != null:
            _camera.play_impulse(2.0)
        _play_tone(180.0, 0.11, 0.14)
    if objective_reached:
        if _fx != null:
            _fx.play_success(success_cell, TerrainRenderer.CELL_SIZE)
        _play_tone(760.0, 0.20, 0.15)

func _play_tone(frequency: float, duration: float, volume: float) -> void:
    if _audio == null:
        return
    _audio.stream = ProceduralAudio.make_tone(frequency, duration, volume)
    _audio.play()
```

No call occurs from raw hover events.

- [ ] **Step 6: Add the controller node to the scene**

Add `FeedbackController` as a child of `VerticalSlice` with its script resource. Extend the scene contract accordingly.

- [ ] **Step 7: Add the 0.12 s anticipation gate in `src/vertical_slice.gd`**

Add refs/state:

```gdscript
@onready var resolution_fx: ResolutionFx = $ResolutionFx
@onready var feedback: FeedbackController = $FeedbackController
var _trigger_pending := false
```

Configure in `_ready()`:

```gdscript
feedback.configure(game_camera, resolution_fx, ancient_overlay)
```

Replace `_on_trigger_requested` with:

```gdscript
func _on_trigger_requested() -> void:
    if _trigger_pending or controller.state != SimulationController.PREPARE:
        return
    _trigger_pending = true
    hud.set_busy(true)
    feedback.play_trigger_anticipation()
    await get_tree().create_timer(0.12).timeout
    if controller.state == SimulationController.PREPARE:
        controller.trigger_resolution()
        _clear_selection()
    _trigger_pending = false
    hud.set_busy(false)
```

Guard dig/move/fuse/undo/cancel handlers with:

```gdscript
if _trigger_pending:
    return
```

- [ ] **Step 8: Play confirmed-action cues only after successful actions**

For dig, capture the cell material before removing it:

```gdscript
func _on_dig_requested(cell: Vector2i) -> void:
    if _trigger_pending or controller.state != SimulationController.PREPARE:
        return
    var terrain_cell := model.get_cell(cell)
    var material_id: StringName = terrain_cell.material_id if terrain_cell != null else &""
    if controller.terrain_actions.dig(cell):
        feedback.play_action(&"dig", material_id)
        _refresh_prepare_state()
```

Use `play_action(&"move", material_id)` after a successful move and `play_action(&"fuse", &"stabilizer")` after a successful fuse.

- [ ] **Step 9: Route resolved movement feedback after objective calculation**

In `_on_resolution_finished`, calculate `_objective_reached` first, then call:

```gdscript
var exit_rect: Rect2i = _layout_data["exit_rect"]
var success_cell := Vector2i(exit_rect.position.x + int(exit_rect.size.x / 2), exit_rect.position.y)
feedback.play_resolution(movements, controller.relay_connected, _objective_reached, success_cell)
```

Then continue HUD refresh and autosave.

- [ ] **Step 10: Run all tests and manual audio/feedback check**

Headless expected: PASS.

Manual: no hover sound; confirmed action cues are brief; trigger pauses ~0.12 s; dense gate impact is stronger than light movement; camera settles; success cue occurs once when opening the descent.

- [ ] **Step 11: Commit**

```bash
git add src/feedback/procedural_audio.gd src/feedback/feedback_controller.gd tests/test_procedural_audio.gd tests/test_runner.gd scenes/vertical_slice.tscn src/vertical_slice.gd tests/test_scene_contract.gd
git commit -m "feat: add concise audiovisual resolution feedback"
```

---

### Task 10: Final integration, acceptance, documentation, and CI gate

**Files:**
- Modify: `tests/test_vertical_slice_acceptance.gd`
- Modify: `tests/test_scene_contract.gd`
- Modify: `README.md`

**Interfaces:**
- No new gameplay API. This task proves and documents the v0.2 contract.

- [ ] **Step 1: Strengthen the canonical cave acceptance test**

Ensure `tests/test_vertical_slice_acceptance.gd` verifies all of the following in one deterministic flow:

```gdscript
t.equal(VerticalSliceLayout.CONTENT_ID, "cave_v02_helix_01", "identifiant contenu v0.2 stable")
t.equal(data["spawn_focus"], Vector2i(22, 12), "focus d'entrée v0.2")
t.check((data["ancient_path"] as Array).size() >= 12, "chemin ancien présent")
```

After applying `SUPPORT_REMOVAL` and resolving:

```gdscript
t.equal(gate_fell, true, "formation dense canonique s'effondre")
t.equal(corridor_clear, true, "descente ouverte")
t.equal(network.is_relay_connected(model, data["relay_source"], data["relay_pos"]), true, "relais préservé")
```

Save the solved model with `content_id = VerticalSliceLayout.CONTENT_ID`, reload through `load_from_path_for_content`, restore into a fresh v0.2 model, and assert the exit corridor remains clear.

- [ ] **Step 2: Make the scene smoke test check every presentation boundary**

`tests/test_scene_contract.gd` must check these nodes and then free the scene:

```gdscript
for node_path in [
    "CaveBackdrop",
    "TerrainRenderer",
    "AncientOverlay",
    "ResolutionFx",
    "GameCamera",
    "GameInput",
    "FeedbackController",
    "HUD",
]:
    t.check(scene.get_node_or_null(node_path) != null, "node requis: %s" % node_path)
scene.free()
```

- [ ] **Step 3: Run the complete Godot 4.7.2 headless suite**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected: PASS, exit code 0, no parser/runtime errors and no ObjectDB/resource leak warnings introduced by these tests.

- [ ] **Step 4: Update `README.md` to v0.2 reality**

Document:

```markdown
## v0.2 vertical slice

Project Digger v0.2 keeps the deterministic 64×72 terrain simulation while replacing the technical map presentation with the first Helix cave.

- Observer: organic cave view, no global grid.
- Prepare: local hover/selection and Stable / Fragile / Critical analysis overlays.
- Tools: Creuser, Déplacer, Fusionner.
- Resolution: short anticipation, ancient relay pulse, collapse FX, proportional camera impulse, procedural placeholder audio.
- Saves: content-aware; v0.1 prototype saves without `content_id` start the v0.2 cave fresh.

### Test

`godot --headless --path . -s res://tests/test_runner.gd`
```

Keep the existing control list accurate; do not document minimap or unimplemented systems.

- [ ] **Step 5: Commit integration/docs**

```bash
git add tests/test_vertical_slice_acceptance.gd tests/test_scene_contract.gd README.md
git commit -m "test: lock Project Digger v0.2 acceptance"
```

- [ ] **Step 6: Verify GitHub Actions on the final branch tip**

Push/commit on `feature/digger-v0.2` and confirm the `Godot 4.7.2 headless tests` workflow finishes with `conclusion: success` for the exact final commit SHA.

- [ ] **Step 7: Perform manual acceptance in Godot**

Check this exact sequence:

```text
1. Start with no compatible v0.2 save: new Helix cave appears.
2. Observer: no global grid; materials and route down are readable.
3. Press Préparer: analysis overlays appear and hover shows one local target.
4. Use Creuser on safe entrance/common rock: energy decrements and action cue plays.
5. Undo: terrain and energy restore.
6. Cancel: all staged changes restore.
7. Prepare again; remove the canonical supports.
8. Déclencher: brief anticipation → relay pulse → collapse → dust/impact → camera settles.
9. Dense formation opens the descent and relay remains connected.
10. Completion message appears.
11. Quit and relaunch: solved terrain restores because `content_id` matches.
12. Keyboard tools and mouse interaction still work.
```

Capture at least one Observer screenshot and one Prepare screenshot for review against the approved mockup principles. The screenshots validate direction, not pixel-perfect reproduction.

- [ ] **Step 8: Stop before merge and request integration decision**

Do not merge automatically after the checks. Use the finishing-development-branch workflow: present merge / PR / keep-branch options after the exact final branch tip has green CI and manual acceptance is confirmed.
