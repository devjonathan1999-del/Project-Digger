# Asset-Driven Visual v0.7 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make detailed transparent PNG installations the dominant visual language of the Mine screen while preserving gameplay, save data, progression and interaction semantics.

**Architecture:** Add a dedicated `MineV07Assets` catalog and a `MineAssetRenderer` extending `mine_final_module_renderer.gd`. Because `IndustryScreen` currently expects its renderer to expose `bind(session, world)`, the v0.7 renderer also provides the small runtime bridge (`bind`, `_process`, `_sync_state`) that feeds the existing presentation state into the final renderer. `MineWorld` and `MineInteractionPresenter` remain the owners of hitboxes and context actions.

**Tech Stack:** Godot 4.7.2, GDScript, `gl_compatibility`, RGBA PNG assets, GitHub Actions/Xvfb visual tests.

**Spec:** `docs/superpowers/specs/2026-09-12-asset-driven-v0.7-design.md`

## Global Constraints

- Do not modify `IndustryGame`, production formulas, timers, progression milestones, save schema or migrations.
- Keep existing target IDs and semantics: `Mine_iron`, `Mine_coal`, `Mine_copper`, `Drill`, discovery/site targets.
- Minimum tactile target size remains 44 px in narrow layouts.
- PNGs are visual-only and must never capture mouse input.
- Preserve aspect ratio for every PNG; never stretch to arbitrary rectangles.
- Procedural drawing remains for continuous geology, shaft body/cables, local connectors, lights and atmosphere only.
- Godot remains 4.7.2 with `gl_compatibility`.
- No merge to `main` without explicit user approval.

---

### Task 1: Import the 10 RGBA assets and create `MineV07Assets`

**Files:**
- Create: `assets/industry/v07/surface_workshop.png`
- Create: `assets/industry/v07/surface_silo.png`
- Create: `assets/industry/v07/surface_ventilation.png`
- Create: `assets/industry/v07/surface_crane.png`
- Create: `assets/industry/v07/shaft_station.png`
- Create: `assets/industry/v07/shaft_elevator.png`
- Create: `assets/industry/v07/iron_installation.png`
- Create: `assets/industry/v07/coal_installation.png`
- Create: `assets/industry/v07/copper_installation.png`
- Create: `assets/industry/v07/crystal_installation.png`
- Create: `src/industry/ui/mine_v07_assets.gd`
- Create: `tests/test_visual_v07_assets.gd`
- Modify: `.github/workflows/godot-tests.yml`

**Interfaces:**
- `MineV07Assets.has_asset(id: String) -> bool`
- `MineV07Assets.texture_for(id: String) -> Texture2D`

- [ ] **Step 1: Add the failing asset test**

```gdscript
extends SceneTree
const Assets = preload("res://src/industry/ui/mine_v07_assets.gd")
const REQUIRED := [
    "surface_workshop", "surface_silo", "surface_ventilation", "surface_crane",
    "shaft_station", "shaft_elevator", "iron_installation", "coal_installation",
    "copper_installation", "crystal_installation",
]
func _init() -> void:
    var failures := 0
    for id in REQUIRED:
        if not Assets.has_asset(id):
            push_error("missing v0.7 asset: %s" % id)
            failures += 1
            continue
        var texture := Assets.texture_for(id)
        if texture == null:
            push_error("asset did not load: %s" % id)
            failures += 1
            continue
        var image := texture.get_image()
        if image == null or image.is_empty():
            push_error("asset image empty: %s" % id)
            failures += 1
            continue
        var corners := [
            image.get_pixel(0, 0).a,
            image.get_pixel(image.get_width() - 1, 0).a,
            image.get_pixel(0, image.get_height() - 1).a,
            image.get_pixel(image.get_width() - 1, image.get_height() - 1).a,
        ]
        if corners.min() > 0.08:
            push_error("asset lacks transparent corner: %s" % id)
            failures += 1
    quit(1 if failures > 0 else 0)
```

- [ ] **Step 2: Add CI step and confirm red**

```yaml
      - name: Exercise asset-driven v0.7 assets
        run: xvfb-run -a godot --headless --path . -s tests/test_visual_v07_assets.gd
```

Expected: only v0.7 asset step fails because catalog/assets are not present.

- [ ] **Step 3: Validate and upload generated files as binary blobs**

Source mapping:

```text
/mnt/data/ghostwriter_images/generated/a_high_detail_clean_cut_sci_fi_industrial_buildin_1.png -> surface_workshop.png
/mnt/data/ghostwriter_images/generated/a_clean_high_resolution_game_style_industrial_sc_2_batch_1.png -> surface_silo.png
/mnt/data/ghostwriter_images/generated/a_detailed_high_resolution_concept_art_style_png_3_batch_2.png -> surface_ventilation.png
/mnt/data/ghostwriter_images/generated/wide_high_detail_concept_art_style_illustration_o_4_batch_3.png -> surface_crane.png
/mnt/data/ghostwriter_images/generated/a_detailed_crisp_photorealistic_illustrative_2d_5_batch_4.png -> shaft_station.png
/mnt/data/ghostwriter_images/generated/a_detailed_clean_isolated_png_style_concept_asse_6_batch_5.png -> shaft_elevator.png
/mnt/data/ghostwriter_images/generated/a_detailed_digital_illustration_game_asset_view_7_batch_6.png -> iron_installation.png
/mnt/data/ghostwriter_images/generated/a_detailed_high_resolution_2d_digital_illustratio_8_batch_7.png -> coal_installation.png
/mnt/data/ghostwriter_images/generated/a_detailed_high_resolution_transparent_backgroun_9_batch_8.png -> copper_installation.png
/mnt/data/ghostwriter_images/generated/wide_horizontal_sci_fi_fantasy_game_asset_illustra_10_batch_9.png -> crystal_installation.png
```

Check each with Pillow: mode must be `RGBA`, width/height > 0, alpha extrema must include 0 and >0. Upload with Git blob/tree/commit APIs so binary bytes are preserved.

- [ ] **Step 4: Add catalog implementation**

```gdscript
class_name MineV07Assets
extends RefCounted
const PATHS := {
    "surface_workshop": "res://assets/industry/v07/surface_workshop.png",
    "surface_silo": "res://assets/industry/v07/surface_silo.png",
    "surface_ventilation": "res://assets/industry/v07/surface_ventilation.png",
    "surface_crane": "res://assets/industry/v07/surface_crane.png",
    "shaft_station": "res://assets/industry/v07/shaft_station.png",
    "shaft_elevator": "res://assets/industry/v07/shaft_elevator.png",
    "iron_installation": "res://assets/industry/v07/iron_installation.png",
    "coal_installation": "res://assets/industry/v07/coal_installation.png",
    "copper_installation": "res://assets/industry/v07/copper_installation.png",
    "crystal_installation": "res://assets/industry/v07/crystal_installation.png",
}
static var _cache: Dictionary = {}
static func has_asset(id: String) -> bool:
    return PATHS.has(id) and ResourceLoader.exists(str(PATHS[id]))
static func texture_for(id: String) -> Texture2D:
    if not has_asset(id): return null
    if _cache.has(id): return _cache[id] as Texture2D
    var texture := load(str(PATHS[id])) as Texture2D
    if texture != null: _cache[id] = texture
    return texture
```

- [ ] **Step 5: Run full CI and commit**

Commit: `feat: add v0.7 illustrated mine asset pack`

---

### Task 2: Add runtime-compatible `MineAssetRenderer` and wire it into `IndustryScreen`

**Files:**
- Create: `src/industry/ui/mine_asset_renderer.gd`
- Create: `tests/test_visual_v07_renderer.gd`
- Modify: `src/industry/ui/industry_screen.gd`
- Modify: `.github/workflows/godot-tests.yml`

**Interfaces:**
- `MineAssetRenderer` extends `res://src/industry/ui/mine_final_module_renderer.gd`.
- Must expose `bind(session, world: Control) -> void` because `IndustryScreen._build_mine_panel()` calls it.
- Must keep `set_scene_state(state: Dictionary) -> void` for deterministic tests/captures.
- Must expose `visual_metrics() -> Dictionary`.

- [ ] **Step 1: Add failing runtime bridge test**

Test must instantiate `MineAssetRenderer`, call `bind(fake_session, fake_world)` using a minimal fake session/world compatible with the existing renderer state contract, then assert that calling `_process(0.0)` updates metrics without an invalid-method error. Also assert direct `set_scene_state()` still works.

The deterministic state used by direct tests is:

```gdscript
{
    "depth": 150,
    "center_level": 6,
    "mine_levels": {"iron": 5, "coal": 5, "copper": 5},
    "discoveries": {},
    "permanent_sites": [],
    "jobs": {},
    "scroll_depth": 55.0,
    "zoom": 1.0,
    "animation_phase": 0.35,
    "viewport_size": Vector2(1280, 800),
}
```

Expected red: `mine_asset_renderer.gd` missing.

- [ ] **Step 2: Implement runtime bridge**

```gdscript
class_name MineAssetRenderer
extends "res://src/industry/ui/mine_final_module_renderer.gd"
const Assets = preload("res://src/industry/ui/mine_v07_assets.gd")
var _session
var _world: Control
var _v07_metrics: Dictionary = {}
func _ready() -> void:
    name = "MineAssetRenderer"
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    set_process(true)
func bind(session, world: Control) -> void:
    _session = session
    _world = world
    _sync_state()
func _process(_delta: float) -> void:
    if _session != null and _world != null:
        _sync_state()
func _sync_state() -> void:
    var game = _session.game
    set_scene_state({
        "depth": game.depth,
        "center_level": game.center_level,
        "mine_levels": game.mine_levels.duplicate(true),
        "discoveries": game.discoveries.duplicate(true),
        "permanent_sites": game.permanent_sites.duplicate(true),
        "jobs": game.jobs.duplicate(true),
        "scroll_depth": float(_world.get("scroll_depth")),
        "zoom": float(_world.get("zoom")),
        "animation_phase": float(_world.get("animation_phase")),
        "viewport_size": size,
    })
func set_scene_state(state: Dictionary) -> void:
    super.set_scene_state(state)
    _update_v07_metrics()
    queue_redraw()
func visual_metrics() -> Dictionary:
    var result := metrics()
    result.merge(_v07_metrics, true)
    return result
```

- [ ] **Step 3: Add initial metrics**

Track `v07_major_asset_count`, `v07_station_count`, `v07_elevator_inside_shaft`, `v07_resource_identity_ok`, `v07_surface_assets_in_bounds`, `v07_asset_aspect_ok`, `v07_crystal_visible`, and `v07_resource_installation_count`.

- [ ] **Step 4: Switch only the screen preload**

In `industry_screen.gd`:

```gdscript
const MineSceneRendererScript = preload("res://src/industry/ui/mine_asset_renderer.gd")
```

Do not change `_mine_renderer.bind(session, _mine_world)` or world ownership.

- [ ] **Step 5: Add CI step, run full gate, commit**

Commit: `feat: wire runtime-compatible v0.7 mine renderer`

---

### Task 3: Make surface and shaft asset-driven

**Files:**
- Modify: `src/industry/ui/mine_asset_renderer.gd`
- Modify: `tests/test_visual_v07_renderer.gd`

- [ ] **Step 1: Add red assertions**

Require desktop surface assets to stay in bounds, asset aspect ratio to remain unchanged, five station assets at 150 m, and elevator draw rect inside shaft bounds.

- [ ] **Step 2: Add aspect-preserving helper**

```gdscript
func _fit_rect(source_size: Vector2, target: Rect2) -> Rect2:
    if source_size.x <= 0.0 or source_size.y <= 0.0: return target
    var scale_factor := minf(target.size.x / source_size.x, target.size.y / source_size.y)
    var fitted_size := source_size * scale_factor
    return Rect2(target.position + (target.size - fitted_size) * 0.5, fitted_size)
func _draw_v07_asset(id: String, target: Rect2) -> Rect2:
    var texture := Assets.texture_for(id)
    if texture == null: return Rect2()
    var actual := _fit_rect(texture.get_size(), target)
    draw_texture_rect(texture, actual, false)
    return actual
```

- [ ] **Step 3: Override `_draw_surface_base()`**

Wide target widths at 1280: workshop 300–330 px, silo 200–230 px, ventilation 180–210 px, crane 230–280 px when unlocked. Keep shaft center clear. Narrow mode hides crane first and preserves workshop + shaft + at least one support module at readable scale.

Do not call the parent v0.6 surface-machine drawing after the v0.7 assets are drawn; retain only ground/headframe/utility primitives required for continuity.

- [ ] **Step 4: Override shaft stations/elevator**

Retain procedural shaft body/cables. Replace station/cage primitives with `shaft_station.png` at `[30,60,90,120,150]` and `shaft_elevator.png` using `animation_phase`. Desktop station target width 320–400 px; narrow 230–300 px; elevator 65–95 px desktop and proportionally smaller narrow.

- [ ] **Step 5: Run CI and commit**

Commit: `feat: compose illustrated v0.7 surface and shaft`

---

### Task 4: Replace Fer / Charbon / Cuivre / Cristal visuals

**Files:**
- Modify: `src/industry/ui/mine_asset_renderer.gd`
- Modify: `tests/test_visual_v07_renderer.gd`

- [ ] **Step 1: Add red shallow/deep identity tests**

At depth 60: three shallow installations visible, crystal absent. At depth 150: all four visible. Require mapping `iron_installation`, `coal_installation`, `copper_installation`, `crystal_installation` and a major asset count dominated by PNG modules rather than primitive-only metrics.

- [ ] **Step 2: Override `_draw_resource_installations()`**

Desktop target widths: 350–430 px for shallow resource installations where space permits. Fer left, Charbon left/near shaft without overlapping Fer, Cuivre right. Narrow widths 220–300 px and vertically stagger where needed rather than shrinking below readability.

- [ ] **Step 3: Add deep crystal composition**

Show `crystal_installation` only when `depth >= 90` or when the current state exposes an already unlocked permanent crystal site. Place it in a darker cavern with cyan local glow, target width 380–500 px desktop.

- [ ] **Step 4: Embed assets in geology**

Draw deterministic foreground rock silhouettes over small bottom/side portions of underground assets (roughly 10–18%, never >20%) so installations read as excavated into rock rather than pasted on top. Preserve labels/hitboxes above the renderer.

- [ ] **Step 5: Run CI and commit**

Commit: `feat: add illustrated v0.7 resource installations`

---

### Task 5: Preserve interactions and responsive behavior

**Files:**
- Modify: `tests/test_visual_v07_renderer.gd`
- Modify only if a demonstrated failure requires it: `src/industry/ui/mine_interaction_presenter.gd`

- [ ] **Step 1: Add actual-screen regression at 1280×800 and 720×1000**

Assert renderer class is `MineAssetRenderer`; `Mine_iron`, `Mine_coal`, `Mine_copper`, `Drill` still exist; narrow targets are >=44 px; click on Fer opens expected context; closing context returns marker to rest; renderer mouse filter is IGNORE.

- [ ] **Step 2: Run red/green honestly**

If already green, do not change production code. If red, fix only the proven issue: placement, tertiary-module hiding, mouse filter, or focus release. Never alter target IDs/callback semantics.

- [ ] **Step 3: Run all interaction/responsive suites and commit only if needed**

If production changes are required, commit: `fix: preserve v0.7 mine interactions on narrow layouts`

---

### Task 6: Capture, inspect and final-gate v0.7

**Files:**
- Create: `tests/test_visual_v07_captures.gd`
- Modify: `.github/workflows/godot-tests.yml`
- Modify: `README.md`

- [ ] **Step 1: Generate exact capture matrix**

```text
/tmp/digger-ui/v07-wide-surface.png
/tmp/digger-ui/v07-wide-60m.png
/tmp/digger-ui/v07-wide-150m.png
/tmp/digger-ui/v07-narrow-90m.png
/tmp/digger-ui/v07-wide-selected.png
```

Use fixed deterministic states. The selected capture programmatically selects an existing target and leaves the context panel visible.

- [ ] **Step 2: Add CI capture step**

```yaml
      - name: Capture asset-driven v0.7 showcase
        run: xvfb-run -a godot --path . -s tests/test_visual_v07_captures.gd
```

Keep existing `/tmp/digger-ui` artifact upload.

- [ ] **Step 3: Update README**

Document that v0.7 is an asset-driven visual layer using detailed transparent PNGs; gameplay/economy/save remain unchanged. Do not claim Android readiness or final production-art completeness.

- [ ] **Step 4: Run exact-head full CI**

Required green: import, headless logic, industry UI, progression/context, events, v0.4/v0.5/v0.6 regressions, v0.7 assets, v0.7 renderer/responsive, captures, artifact upload.

- [ ] **Step 5: Download and inspect all five PNGs**

Reject if line art still dominates, PNGs stretch, modules float, resources are unreadably small, crystal identity is weak, shaft alignment is wrong, surface clips, narrow view is unreadable, or labels dominate art.

- [ ] **Step 6: Scope check against `main`**

Only assets v0.7, visual UI renderer/catalog, proven interaction fix if any, tests/CI, README/docs may differ. No `IndustryGame`, economy, save/migration or progression files.

- [ ] **Step 7: Commit final gate**

Commit: `test: validate asset-driven v0.7 showcase`

After exact-head CI and visual inspection pass, present integration options. Do not merge without explicit user approval.
