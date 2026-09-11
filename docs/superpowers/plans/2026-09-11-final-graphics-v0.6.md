# Final Graphics v0.6 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the Mine screen from a procedural schematic into a near-final industrial-retrofuturist game scene while preserving all gameplay, save, economy, interaction, and navigation behavior.

**Architecture:** Keep `MineSceneRenderer` as the read-only scene coordinator, add a dedicated `MineModuleRenderer` for large recognizable industrial installations, keep `MineInteractionPresenter` above the art for authoritative hitboxes/markers, and extend `MineVisualLayout` only with deterministic presentation profiles. Use local PNG assets where they materially improve fidelity, with procedural fallback drawing so rendering never depends on external services or missing files.

**Tech Stack:** Godot 4.7.2, GDScript, `gl_compatibility`, local PNG assets under `assets/industry/v06/`, GitHub Actions/Xvfb visual tests.

**Spec:** `docs/superpowers/specs/2026-09-11-final-graphics-v0.6-design.md`

## Global Constraints

- Do not change economy, costs, production rates, timers, progression rules, capacity, technologies, events, save schema, or migration.
- `MineSceneRenderer`, `MineModuleRenderer`, and `MineInteractionPresenter` are read-only presentation components.
- No runtime network dependency.
- No static full-screen Mine background replacing state-driven rendering.
- Existing hitboxes remain authoritative for actions.
- Keep top HUD and bottom four-tab navigation structurally unchanged.
- Visual variation must be deterministic; no runtime RNG for layout.
- Godot target is exactly 4.7.2 with `gl_compatibility`.
- Wide target: 1280×800. Narrow target: 720×1000.

---

### Task 1: Final-graphics renderer boundary and visual contract

**Files:**
- Create: `src/industry/ui/mine_module_renderer.gd`
- Create: `tests/test_visual_v06_modules.gd`
- Modify: `tests/test_runner.gd`
- Modify: `.github/workflows/godot-tests.yml`

**Interfaces:**
- Consumes: presentation dictionaries from `MineSceneRenderer.set_scene_state(state: Dictionary)`.
- Produces: `MineModuleRenderer.set_scene_state(state: Dictionary) -> void`, `MineModuleRenderer.metrics() -> Dictionary`, and a read-only module root named `MineModuleRenderer`.

- [ ] **Step 1: Write the failing module-boundary test**

```gdscript
# tests/test_visual_v06_modules.gd
extends SceneTree

const Support = preload("res://tests/test_support.gd")
const Renderer = preload("res://src/industry/ui/mine_module_renderer.gd")

func _initialize() -> void:
    var node := Renderer.new()
    root.add_child(node)
    node.set_scene_state({
        "depth": 60,
        "center_level": 4,
        "animation_phase": 0.0,
        "viewport_size": Vector2(1280, 800),
    })
    var m := node.metrics()
    Support.check(str(node.name) == "MineModuleRenderer", "module renderer named")
    Support.check(int(m.get("surface_module_count", 0)) >= 4, "surface modules counted")
    Support.check(int(m.get("shaft_station_count", 0)) >= 2, "shaft stations counted")
    Support.check(int(m.get("resource_installation_count", 0)) >= 3, "resource installations counted")
    node.queue_free()
    quit(0 if Support.failures == 0 else 1)
```

- [ ] **Step 2: Add the new test to CI and verify RED**

Run in CI:

```bash
xvfb-run -a ./Godot_v4.7.2-stable_linux.x86_64 --path . --audio-driver Dummy --rendering-method gl_compatibility -s res://tests/test_visual_v06_modules.gd
```

Expected: FAIL because `mine_module_renderer.gd` does not exist.

- [ ] **Step 3: Implement the minimal read-only renderer shell**

```gdscript
# src/industry/ui/mine_module_renderer.gd
class_name MineModuleRenderer
extends Control

var _state: Dictionary = {}
var _metrics := {
    "surface_module_count": 0,
    "shaft_station_count": 0,
    "resource_installation_count": 0,
}

func _ready() -> void:
    name = "MineModuleRenderer"
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func set_scene_state(state: Dictionary) -> void:
    _state = state.duplicate(true)
    var center_level := int(_state.get("center_level", 1))
    var depth := int(_state.get("depth", 0))
    _metrics["surface_module_count"] = clampi(center_level + 1, 2, 7)
    _metrics["shaft_station_count"] = maxi(0, depth / 30)
    _metrics["resource_installation_count"] = 3
    queue_redraw()

func metrics() -> Dictionary:
    return _metrics.duplicate(true)
```

- [ ] **Step 4: Run the focused test and the existing renderer tests**

Expected: PASS for `test_visual_v06_modules.gd`, `test_visual_v04_world.gd`, `test_visual_v05_world.gd`.

- [ ] **Step 5: Commit**

```bash
git add src/industry/ui/mine_module_renderer.gd tests/test_visual_v06_modules.gd tests/test_runner.gd .github/workflows/godot-tests.yml
git commit -m "feat: add final graphics module renderer boundary"
```

---

### Task 2: Generate and integrate reusable v0.6 visual assets

**Files:**
- Create binary assets under `assets/industry/v06/`:
  - `surface_workshop.png`
  - `surface_silo.png`
  - `surface_control.png`
  - `surface_ventilation.png`
  - `surface_crane.png`
  - `shaft_station.png`
  - `iron_module.png`
  - `coal_module.png`
  - `copper_module.png`
  - `crystal_module.png`
- Create: `src/industry/ui/mine_v06_assets.gd`
- Extend: `tests/test_visual_v06_modules.gd`

**Interfaces:**
- Consumes: local PNGs only.
- Produces: `MineV06Assets.texture_for(id: String) -> Texture2D` and `MineV06Assets.has_asset(id: String) -> bool`.

- [ ] **Step 1: Add a failing asset-catalog test**

```gdscript
const Assets = preload("res://src/industry/ui/mine_v06_assets.gd")

func _check_assets() -> void:
    for id in ["surface_workshop", "surface_silo", "surface_control", "surface_ventilation", "surface_crane", "shaft_station", "iron_module", "coal_module", "copper_module", "crystal_module"]:
        Support.check(Assets.has_asset(id), "asset exists: %s" % id)
        Support.check(Assets.texture_for(id) != null, "texture loads: %s" % id)
```

Expected RED: catalog and files absent.

- [ ] **Step 2: Generate modular transparent assets from the approved visual target**

Requirements for each asset:
- transparent background;
- no baked gameplay numbers;
- no mandatory language text;
- industrial retro-future palette consistent with the approved mockup;
- readable when scaled to roughly 120–320 px wide;
- no UI frame baked into the image.

- [ ] **Step 3: Add the asset catalog**

```gdscript
# src/industry/ui/mine_v06_assets.gd
class_name MineV06Assets
extends RefCounted

const PATHS := {
    "surface_workshop": "res://assets/industry/v06/surface_workshop.png",
    "surface_silo": "res://assets/industry/v06/surface_silo.png",
    "surface_control": "res://assets/industry/v06/surface_control.png",
    "surface_ventilation": "res://assets/industry/v06/surface_ventilation.png",
    "surface_crane": "res://assets/industry/v06/surface_crane.png",
    "shaft_station": "res://assets/industry/v06/shaft_station.png",
    "iron_module": "res://assets/industry/v06/iron_module.png",
    "coal_module": "res://assets/industry/v06/coal_module.png",
    "copper_module": "res://assets/industry/v06/copper_module.png",
    "crystal_module": "res://assets/industry/v06/crystal_module.png",
}

static func has_asset(id: String) -> bool:
    return PATHS.has(id) and ResourceLoader.exists(str(PATHS[id]))

static func texture_for(id: String) -> Texture2D:
    if not has_asset(id):
        return null
    return load(str(PATHS[id])) as Texture2D
```

- [ ] **Step 4: Run import + asset test**

Expected: all PNGs import under Godot 4.7.2 and all catalog checks PASS.

- [ ] **Step 5: Commit assets and catalog**

```bash
git add assets/industry/v06 src/industry/ui/mine_v06_assets.gd tests/test_visual_v06_modules.gd
git commit -m "art: add final graphics mine modules"
```

---

### Task 3: Rebuild the surface and central shaft as hero modules

**Files:**
- Modify: `src/industry/ui/mine_module_renderer.gd`
- Modify: `src/industry/ui/mine_scene_renderer.gd`
- Modify: `src/industry/ui/mine_visual_layout.gd`
- Extend: `tests/test_visual_v06_modules.gd`

**Interfaces:**
- Consumes: `MineV06Assets.texture_for()` and deterministic layout profiles.
- Produces: module placements and metrics `shaft_width`, `surface_feature_count`, `shaft_station_count`, `elevator_visible`.

- [ ] **Step 1: Add failing hero-composition assertions**

```gdscript
var wide := Renderer.new()
root.add_child(wide)
wide.size = Vector2(1280, 800)
wide.set_scene_state({"depth": 120, "center_level": 6, "animation_phase": 0.0, "viewport_size": wide.size})
var m := wide.metrics()
Support.check(float(m.get("shaft_width", 0.0)) >= 120.0, "shaft widened")
Support.check(int(m.get("surface_feature_count", 0)) >= 6, "surface reads as mine base")
Support.check(bool(m.get("elevator_visible", false)), "elevator cage visible")
Support.check(int(m.get("shaft_station_count", 0)) >= 4, "stations visible")
```

Expected RED on missing metrics.

- [ ] **Step 2: Extend deterministic layout profiles**

Add exact helpers to `mine_visual_layout.gd`:

```gdscript
static func shaft_profile(viewport_width: float, depth: int) -> Dictionary:
    return {
        "width": clampf(viewport_width * 0.115, 110.0, 150.0),
        "station_depths": [d for d in [30, 60, 90, 120, 150] if d <= depth],
    }

static func resource_module_profile(resource_id: String, depth: int) -> Dictionary:
    var side := -1 if resource_id in ["iron", "coal"] else 1
    return {"side": side, "depth": depth}
```

- [ ] **Step 3: Draw/sprite the hero shaft**

`MineModuleRenderer` must draw:
- wider steel frame;
- elevator cage moving only from `animation_phase`;
- twin rails and cables;
- counterweight track;
- utility pipes;
- station sprites/frames at unlocked horizons;
- hazard stripes and amber indicator lights.

Use the asset when available; call procedural fallback drawing if it is null.

- [ ] **Step 4: Draw/sprite the surface base by Centre level**

At Centre 6 show at least:
- workshop;
- silo;
- headframe;
- control center;
- ventilation;
- crane/yard;
- connecting pipes/conveyor silhouettes.

At lower Centre levels, only show modules justified by existing progression.

- [ ] **Step 5: Mount `MineModuleRenderer` inside `MineSceneRenderer` below interactions**

Use one child module renderer and feed it the same state dictionary; do not duplicate gameplay state.

- [ ] **Step 6: Run focused UI/world tests**

Expected PASS: v0.4, v0.5, v0.6 world tests; hitboxes remain clickable.

- [ ] **Step 7: Commit**

```bash
git add src/industry/ui/mine_module_renderer.gd src/industry/ui/mine_scene_renderer.gd src/industry/ui/mine_visual_layout.gd tests/test_visual_v06_modules.gd
git commit -m "feat: rebuild surface and shaft for final graphics"
```

---

### Task 4: Turn iron, coal, copper, and crystal into distinct installations

**Files:**
- Modify: `src/industry/ui/mine_module_renderer.gd`
- Modify: `src/industry/ui/mine_scene_renderer.gd`
- Modify: `src/industry/ui/mine_interaction_presenter.gd`
- Extend: `tests/test_visual_v06_modules.gd`

**Interfaces:**
- Produces metrics: `iron_identity_score`, `coal_identity_score`, `copper_identity_score`, `crystal_identity_score`.
- Hitbox node names and action wiring stay unchanged.

- [ ] **Step 1: Add failing identity assertions**

```gdscript
var m := node.metrics()
Support.check(int(m.get("iron_identity_score", 0)) >= 4, "iron identity")
Support.check(int(m.get("coal_identity_score", 0)) >= 4, "coal identity")
Support.check(int(m.get("copper_identity_score", 0)) >= 4, "copper identity")
```

For a 120 m scene:

```gdscript
Support.check(int(m.get("crystal_identity_score", 0)) >= 3, "deep crystal identity")
```

- [ ] **Step 2: Implement iron installation**

Must visibly include at least four of:
- crusher;
- rusty/brown ore pile;
- heavy conveyor;
- ore cart;
- structural beams;
- amber work lamps.

- [ ] **Step 3: Implement coal installation**

Must visibly include at least four of:
- black coal pile;
- dust/haze overlay;
- ventilation duct/fan;
- conveyor;
- coal carts;
- darker warm light pool.

- [ ] **Step 4: Implement copper installation**

Must visibly include at least four of:
- orange/green mineral seam;
- lateral drill head;
- pipes;
- processing tank/hopper;
- copper accents;
- green/cyan reflections on deeper variants.

- [ ] **Step 5: Implement crystal/deep installation**

At 90 m+ add:
- local cyan clusters;
- scanner/instrumentation;
- deep drill rig;
- cold light pool;
- no whole-screen neon wash.

- [ ] **Step 6: Reduce idle labels further without breaking selected/focused states**

Idle labels should remain readable only as integrated signage; selected markers retain existing emphasis and context-panel behavior.

- [ ] **Step 7: Run real-click tests**

Expected PASS: `test_progression_ui_actions.gd`, `test_visual_v05_markers.gd`, v0.6 module test.

- [ ] **Step 8: Commit**

```bash
git add src/industry/ui/mine_module_renderer.gd src/industry/ui/mine_scene_renderer.gd src/industry/ui/mine_interaction_presenter.gd tests/test_visual_v06_modules.gd
git commit -m "feat: give mine resources distinct final installations"
```

---

### Task 5: Replace flat geology with thick irregular rock mass and atmosphere

**Files:**
- Modify: `src/industry/ui/mine_scene_renderer.gd`
- Modify: `src/industry/ui/mine_visual_layout.gd`
- Create: `tests/test_visual_v06_geology.gd`
- Modify: `.github/workflows/godot-tests.yml`

**Interfaces:**
- Produces metrics: `rock_mass_score`, `large_cavity_count`, `light_pool_count`, `atmosphere_effect_count`, `deep_cyan_strength`.

- [ ] **Step 1: Write failing shallow/deep geology test**

```gdscript
# tests/test_visual_v06_geology.gd
extends SceneTree

const Support = preload("res://tests/test_support.gd")
const Renderer = preload("res://src/industry/ui/mine_scene_renderer.gd")

func _initialize() -> void:
    var renderer := Renderer.new()
    root.add_child(renderer)
    renderer.size = Vector2(1280, 800)
    renderer.set_scene_state({"depth": 30, "center_level": 2, "scroll_depth": 30.0, "zoom": 1.0, "animation_phase": 0.0, "mine_levels": {}, "discoveries": {}, "permanent_sites": {}, "jobs": {}, "viewport_size": renderer.size})
    var shallow_rock := int(renderer.get("rock_mass_score"))
    var shallow_cyan := float(renderer.get("deep_cyan_strength"))
    renderer.set_scene_state({"depth": 150, "center_level": 6, "scroll_depth": 135.0, "zoom": 1.0, "animation_phase": 0.0, "mine_levels": {}, "discoveries": {}, "permanent_sites": {}, "jobs": {}, "viewport_size": renderer.size})
    Support.check(int(renderer.get("rock_mass_score")) > shallow_rock, "deeper rock is richer")
    Support.check(int(renderer.get("large_cavity_count")) >= 2, "deep cavities")
    Support.check(float(renderer.get("deep_cyan_strength")) > shallow_cyan, "cyan increases with depth")
    quit(0 if Support.failures == 0 else 1)
```

- [ ] **Step 2: Implement deterministic irregular ceiling/floor silhouettes**

Use depth-banded deterministic polygon points instead of flat full-width bands as the dominant rock edge.

- [ ] **Step 3: Add larger geology forms**

Add bounded counts of:
- strata chunks;
- boulders;
- broken shelves;
- cavity mouths;
- mineral seams;
- shadow pockets behind infrastructure.

- [ ] **Step 4: Add deterministic atmosphere**

Based only on `animation_phase` and scene state:
- amber light pools;
- subtle dust motes;
- coal haze;
- small steam exhaust;
- conveyor highlights;
- local cyan glow at deep sites.

- [ ] **Step 5: Run non-mutation test**

Advance render frames without calling game actions and compare `IndustryGame.snapshot()` before/after. Expected: exact equality.

- [ ] **Step 6: Commit**

```bash
git add src/industry/ui/mine_scene_renderer.gd src/industry/ui/mine_visual_layout.gd tests/test_visual_v06_geology.gd .github/workflows/godot-tests.yml
git commit -m "feat: add final rock mass lighting and atmosphere"
```

---

### Task 6: Responsive composition and final interaction polish

**Files:**
- Modify: `src/industry/ui/mine_module_renderer.gd`
- Modify: `src/industry/ui/mine_scene_renderer.gd`
- Modify: `src/industry/ui/mine_interaction_presenter.gd`
- Modify: `src/industry/ui/site_panel.gd`
- Create: `tests/test_visual_v06_responsive.gd`

**Interfaces:**
- Wide and narrow scenes use the same state and hitboxes; only visual scale/placement changes.

- [ ] **Step 1: Write failing 1280×800 and 720×1000 bounds test**

Assertions:
- shaft stays centered;
- shaft width is 110–150 px wide desktop and capped on narrow;
- no surface module extends beyond viewport;
- resource modules retain at least 44 px interactive target coverage;
- bottom-sheet context does not cover the entire mine on narrow.

- [ ] **Step 2: Implement module simplification for narrow mode**

For width `< 800`:
- reduce decorative sub-elements, not interaction targets;
- cap shaft width;
- hide tertiary surface clutter;
- keep resource identity elements visible;
- preserve bottom sheet behavior.

- [ ] **Step 3: Verify marker focus/selection/clear behavior**

Explicitly re-run the v0.5 marker test and ensure closing `ContextPanel` returns the selected world marker to idle.

- [ ] **Step 4: Run real-click UI regression**

Expected PASS for mine/discovery/drill/site actions in both wide and narrow sizes.

- [ ] **Step 5: Commit**

```bash
git add src/industry/ui/mine_module_renderer.gd src/industry/ui/mine_scene_renderer.gd src/industry/ui/mine_interaction_presenter.gd src/industry/ui/site_panel.gd tests/test_visual_v06_responsive.gd
git commit -m "feat: polish final graphics responsive interactions"
```

---

### Task 7: Final showcase captures, visual inspection, documentation, and release gate

**Files:**
- Create: `tests/test_visual_v06_captures.gd`
- Modify: `.github/workflows/godot-tests.yml`
- Modify: `README.md`

**Interfaces:**
- CI emits deterministic PNG captures into the existing `industry-ui` artifact.

- [ ] **Step 1: Add deterministic showcase capture script**

Capture exactly:
- `v06-wide-surface.png` at 1280×800, Centre 6, surface focus;
- `v06-wide-60m.png` at 1280×800;
- `v06-wide-150m.png` at 1280×800;
- `v06-wide-selected.png` at 1280×800 with a deep context selection;
- `v06-narrow-90m.png` at 720×1000.

- [ ] **Step 2: Add capture command to CI**

```bash
xvfb-run -a ./Godot_v4.7.2-stable_linux.x86_64 --path . --audio-driver Dummy --rendering-method gl_compatibility -s res://tests/test_visual_v06_captures.gd -- --screenshots /tmp/digger-ui
```

- [ ] **Step 3: Run the full CI gate**

Required green steps:
- import;
- headless suite;
- existing v0.3/v0.4/v0.5 UI/action/event/visual tests;
- v0.6 modules;
- v0.6 geology;
- v0.6 responsive;
- v0.6 captures;
- screenshot artifact upload.

- [ ] **Step 4: Inspect every v0.6 PNG manually**

Reject the release if any capture still primarily reads as:
- thin schematic lines;
- large empty flat rock bands;
- indistinguishable resource zones;
- tiny machinery relative to the scene;
- clipped/overlapping UI;
- unreadable deep scene.

- [ ] **Step 5: Update README**

Document:
- v0.6 hybrid final-graphics renderer;
- asset directory;
- unchanged gameplay/save/economy scope;
- CI visual capture coverage.

- [ ] **Step 6: Verify diff scope against `main`**

Expected changed areas only:
- `assets/industry/v06/`;
- `src/industry/ui/` presentation files;
- visual tests/CI;
- docs/README.

No `industry_game.gd`, `industry_save.gd`, progression formulas, or migration files should change.

- [ ] **Step 7: Commit final docs/captures**

```bash
git add tests/test_visual_v06_captures.gd .github/workflows/godot-tests.yml README.md
git commit -m "docs: finalize final graphics v0.6"
```

- [ ] **Step 8: Run one fresh full CI gate on the exact final head**

Do not rely on any earlier green run. The final branch is integration-ready only if this exact commit is green and the artifact has been visually inspected.
