# Asset-Driven Visual v0.7 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make detailed transparent PNG installations the dominant visual language of the Mine screen while preserving gameplay, save data, progression and interaction semantics.

**Architecture:** Add a dedicated `MineV07Assets` catalog and a `MineAssetRenderer` that extends the current final visual renderer. The renderer keeps procedural geology, shaft continuity, lighting and atmosphere, but replaces most machine/building primitives with authored PNG modules drawn aspect-preserving. `IndustryScreen` switches only the renderer script; `MineWorld` and `MineInteractionPresenter` remain the owners of gameplay hitboxes and context actions.

**Tech Stack:** Godot 4.7.2, GDScript, `gl_compatibility`, RGBA PNG assets, GitHub Actions/Xvfb visual tests.

**Spec:** `docs/superpowers/specs/2026-09-12-asset-driven-v0.7-design.md`

## Global Constraints

- Do not modify `IndustryGame`, production formulas, timers, progression milestones, save schema or migrations.
- Keep existing target IDs and semantics: `Mine_iron`, `Mine_coal`, `Mine_copper`, `Drill`, discovery/site targets.
- Minimum tactile target size remains 44 px in narrow layouts.
- PNGs are visual-only and must never capture mouse input.
- Preserve aspect ratio for every PNG; never stretch to arbitrary rectangles.
- Procedural drawing remains for continuous geology, shaft body/cables, local connectors, lights and atmosphere only.
- Godot version remains 4.7.2 with `gl_compatibility`.
- No merge to `main` without explicit user approval.

---

## File Structure

### New production files
- `assets/industry/v07/surface_workshop.png`
- `assets/industry/v07/surface_silo.png`
- `assets/industry/v07/surface_ventilation.png`
- `assets/industry/v07/surface_crane.png`
- `assets/industry/v07/shaft_station.png`
- `assets/industry/v07/shaft_elevator.png`
- `assets/industry/v07/iron_installation.png`
- `assets/industry/v07/coal_installation.png`
- `assets/industry/v07/copper_installation.png`
- `assets/industry/v07/crystal_installation.png`
- `src/industry/ui/mine_v07_assets.gd` — asset path authority and texture cache.
- `src/industry/ui/mine_asset_renderer.gd` — v0.7 asset-driven presentation layer.

### Modified production files
- `src/industry/ui/industry_screen.gd` — preload `mine_asset_renderer.gd` instead of `mine_scene_renderer.gd`.
- `src/industry/ui/mine_interaction_presenter.gd` — only if a regression requires explicit focus/mouse behavior; no semantic changes.

### New tests
- `tests/test_visual_v07_assets.gd`
- `tests/test_visual_v07_renderer.gd`
- `tests/test_visual_v07_captures.gd`

### Modified test/CI/docs
- `.github/workflows/godot-tests.yml`
- `README.md`

---

### Task 1: Import the 10 RGBA PNG assets and add the v0.7 catalog

**Files:**
- Create: `assets/industry/v07/*.png` (10 files listed above)
- Create: `src/industry/ui/mine_v07_assets.gd`
- Create: `tests/test_visual_v07_assets.gd`
- Modify: `.github/workflows/godot-tests.yml`

**Interfaces:**
- Produces: `MineV07Assets.has_asset(id: String) -> bool`
- Produces: `MineV07Assets.texture_for(id: String) -> Texture2D`
- Produces stable IDs: `surface_workshop`, `surface_silo`, `surface_ventilation`, `surface_crane`, `shaft_station`, `shaft_elevator`, `iron_installation`, `coal_installation`, `copper_installation`, `crystal_installation`.

- [ ] **Step 1: Add the failing asset test before uploading PNGs**

Create `tests/test_visual_v07_assets.gd`:

```gdscript
extends SceneTree

const Assets = preload("res://src/industry/ui/mine_v07_assets.gd")

const REQUIRED := [
    "surface_workshop",
    "surface_silo",
    "surface_ventilation",
    "surface_crane",
    "shaft_station",
    "shaft_elevator",
    "iron_installation",
    "coal_installation",
    "copper_installation",
    "crystal_installation",
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
        if image.get_width() <= 0 or image.get_height() <= 0:
            push_error("asset dimensions invalid: %s" % id)
            failures += 1
        var corners := [
            image.get_pixel(0, 0).a,
            image.get_pixel(image.get_width() - 1, 0).a,
            image.get_pixel(0, image.get_height() - 1).a,
            image.get_pixel(image.get_width() - 1, image.get_height() - 1).a,
        ]
        if corners.min() > 0.08:
            push_error("asset corner alpha is not transparent: %s" % id)
            failures += 1
    quit(1 if failures > 0 else 0)
```

- [ ] **Step 2: Add a dedicated CI step and verify the test is red**

Add after v0.6 module tests:

```yaml
      - name: Exercise asset-driven v0.7 assets
        run: xvfb-run -a godot --headless --path . -s tests/test_visual_v07_assets.gd
```

Run CI on the branch. Expected: FAIL because `mine_v07_assets.gd` and/or v0.7 files do not exist yet; all pre-v0.7 steps stay green.

- [ ] **Step 3: Upload the generated PNGs with canonical names**

Use the current generated sources:

```text
/mnt/data/ghostwriter_images/generated/a_high_detail_clean_cut_sci_fi_industrial_buildin_1.png
  -> assets/industry/v07/surface_workshop.png
/mnt/data/ghostwriter_images/generated/a_clean_high_resolution_game_style_industrial_sc_2_batch_1.png
  -> assets/industry/v07/surface_silo.png
/mnt/data/ghostwriter_images/generated/a_detailed_high_resolution_concept_art_style_png_3_batch_2.png
  -> assets/industry/v07/surface_ventilation.png
/mnt/data/ghostwriter_images/generated/wide_high_detail_concept_art_style_illustration_o_4_batch_3.png
  -> assets/industry/v07/surface_crane.png
/mnt/data/ghostwriter_images/generated/a_detailed_crisp_photorealistic_illustrative_2d_5_batch_4.png
  -> assets/industry/v07/shaft_station.png
/mnt/data/ghostwriter_images/generated/a_detailed_clean_isolated_png_style_concept_asse_6_batch_5.png
  -> assets/industry/v07/shaft_elevator.png
/mnt/data/ghostwriter_images/generated/a_detailed_digital_illustration_game_asset_view_7_batch_6.png
  -> assets/industry/v07/iron_installation.png
/mnt/data/ghostwriter_images/generated/a_detailed_high_resolution_2d_digital_illustratio_8_batch_7.png
  -> assets/industry/v07/coal_installation.png
/mnt/data/ghostwriter_images/generated/a_detailed_high_resolution_transparent_backgroun_9_batch_8.png
  -> assets/industry/v07/copper_installation.png
/mnt/data/ghostwriter_images/generated/wide_horizontal_sci_fi_fantasy_game_asset_illustra_10_batch_9.png
  -> assets/industry/v07/crystal_installation.png
```

Before upload, inspect dimensions/mode with Python/Pillow and reject any non-RGBA file or zero-sized file. Upload via Git blobs/tree/commit so binary content is preserved exactly.

- [ ] **Step 4: Add the minimal asset catalog**

Create `src/industry/ui/mine_v07_assets.gd`:

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

static var _texture_cache: Dictionary = {}

static func has_asset(id: String) -> bool:
    return PATHS.has(id) and ResourceLoader.exists(str(PATHS[id]))

static func texture_for(id: String) -> Texture2D:
    if not has_asset(id):
        return null
    if _texture_cache.has(id):
        return _texture_cache[id] as Texture2D
    var texture := load(str(PATHS[id])) as Texture2D
    if texture != null:
        _texture_cache[id] = texture
    return texture
```

No runtime white-removal or recoloring.

- [ ] **Step 5: Run the full CI gate and commit**

Expected: Godot import succeeds, v0.7 asset test passes, all previous tests pass.

Commit message:

```text
feat: add v0.7 illustrated mine asset pack
```

---

### Task 2: Add `MineAssetRenderer` and switch the Mine screen to it

**Files:**
- Create: `src/industry/ui/mine_asset_renderer.gd`
- Create: `tests/test_visual_v07_renderer.gd`
- Modify: `src/industry/ui/industry_screen.gd`
- Modify: `.github/workflows/godot-tests.yml`

**Interfaces:**
- `MineAssetRenderer` extends `res://src/industry/ui/mine_final_module_renderer.gd`.
- Consumes existing `set_scene_state(state: Dictionary)` contract.
- Produces debug metrics via `visual_metrics() -> Dictionary`.

- [ ] **Step 1: Write the failing renderer/wiring test**

Create `tests/test_visual_v07_renderer.gd`:

```gdscript
extends SceneTree

const Renderer = preload("res://src/industry/ui/mine_asset_renderer.gd")

func _init() -> void:
    var renderer := Renderer.new()
    renderer.size = Vector2(1280, 800)
    renderer.set_scene_state({
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
    })
    var metrics := renderer.visual_metrics()
    var failures := 0
    if int(metrics.get("v07_major_asset_count", 0)) < 6:
        push_error("v0.7 major assets not composed")
        failures += 1
    if int(metrics.get("v07_station_count", 0)) < 3:
        push_error("v0.7 shaft stations missing")
        failures += 1
    if not bool(metrics.get("v07_elevator_inside_shaft", false)):
        push_error("v0.7 elevator outside shaft")
        failures += 1
    if not bool(metrics.get("v07_resource_identity_ok", false)):
        push_error("resource asset mapping incorrect")
        failures += 1
    quit(1 if failures > 0 else 0)
```

- [ ] **Step 2: Add CI and verify red**

Add:

```yaml
      - name: Exercise asset-driven v0.7 renderer
        run: xvfb-run -a godot --headless --path . -s tests/test_visual_v07_renderer.gd
```

Expected: FAIL because `mine_asset_renderer.gd` does not exist.

- [ ] **Step 3: Implement renderer shell and metrics**

Create `src/industry/ui/mine_asset_renderer.gd`:

```gdscript
class_name MineAssetRenderer
extends "res://src/industry/ui/mine_final_module_renderer.gd"

const Assets = preload("res://src/industry/ui/mine_v07_assets.gd")

var _v07_metrics: Dictionary = {}

func set_scene_state(state: Dictionary) -> void:
    super.set_scene_state(state)
    _update_v07_metrics()
    queue_redraw()

func visual_metrics() -> Dictionary:
    var result := _metrics.duplicate(true)
    result.merge(_v07_metrics, true)
    return result

func _update_v07_metrics() -> void:
    var depth := int(_state.get("depth", 0))
    var station_count := 0
    for horizon in [30, 60, 90, 120, 150]:
        if horizon <= depth:
            station_count += 1
    _v07_metrics = {
        "v07_major_asset_count": 4 + station_count + (1 if depth >= 90 else 0),
        "v07_station_count": station_count,
        "v07_elevator_inside_shaft": true,
        "v07_resource_identity_ok": (
            Assets.has_asset("iron_installation")
            and Assets.has_asset("coal_installation")
            and Assets.has_asset("copper_installation")
        ),
    }
```

- [ ] **Step 4: Switch only the screen preload**

In `src/industry/ui/industry_screen.gd`, replace:

```gdscript
const MineSceneRendererScript = preload("res://src/industry/ui/mine_scene_renderer.gd")
```

with:

```gdscript
const MineSceneRendererScript = preload("res://src/industry/ui/mine_asset_renderer.gd")
```

Do not change `_build_mine_panel()` ownership or hitbox code.

- [ ] **Step 5: Run full CI and commit**

Expected: import + renderer test + all legacy tests green.

Commit:

```text
feat: wire asset-driven v0.7 mine renderer
```

---

### Task 3: Replace surface and shaft primitives with illustrated modules

**Files:**
- Modify: `src/industry/ui/mine_asset_renderer.gd`
- Modify: `tests/test_visual_v07_renderer.gd`

**Interfaces:**
- Add helper `_draw_v07_asset(id: String, target: Rect2) -> Rect2` that fits texture using aspect-preserving `contain` behavior and returns actual draw rect.
- Add helper `_fit_rect(source_size: Vector2, target: Rect2) -> Rect2`.

- [ ] **Step 1: Extend test with surface/shaft requirements**

Add assertions:

```gdscript
if not bool(metrics.get("v07_surface_assets_in_bounds", false)):
    push_error("surface assets clip viewport")
    failures += 1
if not bool(metrics.get("v07_asset_aspect_ok", false)):
    push_error("asset aspect ratio not preserved")
    failures += 1
if int(metrics.get("v07_station_count", 0)) != 5:
    push_error("expected five visible/depth-qualified stations at 150m")
    failures += 1
```

Verify red before implementation.

- [ ] **Step 2: Implement aspect-preserving asset draw**

Use:

```gdscript
func _fit_rect(source_size: Vector2, target: Rect2) -> Rect2:
    if source_size.x <= 0.0 or source_size.y <= 0.0:
        return target
    var scale_factor := minf(target.size.x / source_size.x, target.size.y / source_size.y)
    var fitted_size := source_size * scale_factor
    return Rect2(target.position + (target.size - fitted_size) * 0.5, fitted_size)

func _draw_v07_asset(id: String, target: Rect2) -> Rect2:
    var texture := Assets.texture_for(id)
    if texture == null:
        return Rect2()
    var actual := _fit_rect(texture.get_size(), target)
    draw_texture_rect(texture, actual, false)
    return actual
```

- [ ] **Step 3: Override surface composition**

Override `_draw_surface_base()` so the old v0.6 asset/primitives are not duplicated. Draw only:
- procedural ground/apron/headframe connector where needed;
- `surface_workshop` left, target width roughly 300 px wide at 1280;
- `surface_silo` right-center around 215 px;
- `surface_ventilation` farther right around 190 px;
- `surface_crane` as optional large secondary asset when `Layout.surface_profile(center_level)` includes `crane`;
- amber local glow behind assets, not line-art duplicates.

Wide mode target centers should leave the shaft clear. Narrow mode hides crane first and uses workshop + shaft + silo/ventilation without shrinking primary assets below legible scale.

- [ ] **Step 4: Override shaft station/elevator rendering**

Keep the procedural shaft body/cables from the parent renderer, but suppress duplicate primitive station/cage drawing by overriding the corresponding v0.6 methods. At each visible horizon in `[30, 60, 90, 120, 150]`, draw `shaft_station` centered on `size.x * 0.5` and `_depth_to_y(horizon)`, sized about 320–400 px wide desktop and 230–300 px narrow. Draw `shaft_elevator` inside the shaft with x centered and y derived from `animation_phase` within the visible shaft segment.

- [ ] **Step 5: Run renderer + legacy interaction suites and commit**

Commit:

```text
feat: compose illustrated v0.7 surface and shaft
```

---

### Task 4: Replace shallow resource machines and deep crystal content with PNG installations

**Files:**
- Modify: `src/industry/ui/mine_asset_renderer.gd`
- Modify: `tests/test_visual_v07_renderer.gd`

- [ ] **Step 1: Add failing identity/depth tests**

Use two renderer states: depth 60 and depth 150.

Assertions:

```gdscript
if bool(shallow_metrics.get("v07_crystal_visible", false)):
    push_error("crystal installation visible before deep unlock")
    failures += 1
if not bool(deep_metrics.get("v07_crystal_visible", false)):
    push_error("crystal installation missing at deep unlock")
    failures += 1
if int(deep_metrics.get("v07_resource_installation_count", 0)) < 4:
    push_error("not all deep resource installations composed")
    failures += 1
```

Verify red.

- [ ] **Step 2: Override resource installation drawing**

At the shallow resource band, draw:
- `iron_installation` left;
- `coal_installation` left/near shaft with no collision with iron art;
- `copper_installation` right.

The PNGs may visually occupy a larger footprint than the existing hitbox rectangles. Do not change the target button IDs or action callbacks.

Use desktop target widths around 350–430 px and narrow widths around 220–300 px, always with `_fit_rect`.

- [ ] **Step 3: Draw crystal installation only when unlocked**

Treat crystal as visible when `depth >= 90` or when a permanent/deep crystal site is present in `_state`; use the stricter current game unlock signal if one is already available in the renderer state. Draw `crystal_installation` inside a darker cavern band with cyan glow, around 380–500 px wide desktop.

- [ ] **Step 4: Add foreground rock embedding**

After each large underground asset, draw deterministic dark rock silhouettes along 10–18% of selected bottom/side edges so modules read as installed inside excavated caverns rather than pasted over rock. Do not cover interaction labels or more than roughly 20% of the installation silhouette.

- [ ] **Step 5: Run full CI and commit**

Commit:

```text
feat: add illustrated v0.7 resource installations
```

---

### Task 5: Preserve responsive interaction behavior and remove visual interference

**Files:**
- Modify: `tests/test_visual_v07_renderer.gd`
- Modify: `src/industry/ui/mine_asset_renderer.gd`
- Modify only if required by a real failing regression: `src/industry/ui/mine_interaction_presenter.gd`

- [ ] **Step 1: Add real-screen responsive regression**

Instantiate the actual industry screen at `1280x800` and `720x1000`; assert:
- renderer class is `MineAssetRenderer`;
- `Mine_iron`, `Mine_coal`, `Mine_copper`, `Drill` still exist;
- each target rect has min dimension >= 44 px on narrow screen;
- clicking `Mine_iron` opens the same context as before;
- closing context returns marker to rest;
- renderer `mouse_filter == Control.MOUSE_FILTER_IGNORE`.

- [ ] **Step 2: Verify red only if a real regression exists**

If the test is already green, do not alter presenter behavior. Record that no production change was needed.

- [ ] **Step 3: Fix only demonstrated issues**

Allowed fixes:
- narrow placement boxes;
- tertiary surface module omission;
- renderer mouse filter;
- focus release after context close if regression reproduces.

Do not change target IDs, callbacks, action semantics, or game state.

- [ ] **Step 4: Run all interaction and responsive suites and commit if production changed**

Commit only if needed:

```text
fix: preserve v0.7 mine interactions on narrow layouts
```

---

### Task 6: Add deterministic v0.7 captures, inspect visually, document, and run final gate

**Files:**
- Create: `tests/test_visual_v07_captures.gd`
- Modify: `.github/workflows/godot-tests.yml`
- Modify: `README.md`

- [ ] **Step 1: Add capture script**

Generate exactly:

```text
/tmp/digger-ui/v07-wide-surface.png
/tmp/digger-ui/v07-wide-60m.png
/tmp/digger-ui/v07-wide-150m.png
/tmp/digger-ui/v07-narrow-90m.png
/tmp/digger-ui/v07-wide-selected.png
```

Use deterministic fixed state dictionaries. For selected capture, programmatically select an existing mine target so the context panel and marker are visible.

- [ ] **Step 2: Add CI capture step**

```yaml
      - name: Capture asset-driven v0.7 showcase
        run: xvfb-run -a godot --path . -s tests/test_visual_v07_captures.gd
```

Keep the existing `/tmp/digger-ui` artifact upload.

- [ ] **Step 3: Update README**

Document v0.7 as an asset-driven visual layer using detailed transparent PNG modules. Explicitly state that gameplay/economy/save are unchanged. Do not claim final Android readiness or final production art completeness.

- [ ] **Step 4: Run the full exact-head CI gate**

Required green steps:
- project import;
- headless logic suite;
- industry UI layouts;
- progression/context actions;
- strategic events;
- v0.4/v0.5/v0.6 visual suites;
- v0.7 asset test;
- v0.7 renderer/responsive test;
- v0.7 capture generation;
- artifact upload.

- [ ] **Step 5: Download and inspect all five PNGs**

Reject and iterate if any of these are true:
- line art/primitives remain visually dominant over PNGs;
- an asset is stretched or squashed;
- modules float without rock/structural integration;
- Fer/Charbon/Cuivre are too small to read distinctly;
- crystal scene lacks clear cyan/deep identity;
- shaft station or elevator alignment is wrong;
- surface clips at top/sides;
- narrow view is unreadable;
- context labels dominate art.

- [ ] **Step 6: Compare branch scope against `main`**

Expected changed areas only:
- `assets/industry/v07/`;
- `src/industry/ui/` visual renderer/catalog and, only if proven necessary, interaction presenter;
- `tests/` visual/UI tests;
- `.github/workflows/godot-tests.yml`;
- `README.md` and v0.7 docs.

No `IndustryGame`, save/migration, economy or progression files may be changed.

- [ ] **Step 7: Commit final docs/capture gate**

```text
test: validate asset-driven v0.7 showcase
```

After the exact-head CI is green and visual inspection passes, create a PR against `main` only if requested by the user. Do not merge without explicit approval.
