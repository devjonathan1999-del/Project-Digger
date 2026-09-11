# Visual Depth v0.5 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transformer la Mine v0.4 en complexe minier souterrain visuellement varié et crédible, sans modifier le gameplay, les timers, la progression ni les sauvegardes.

**Architecture:** Ajouter un composant pur `MineVisualLayout` qui choisit des profils visuels déterministes à partir de la profondeur et du côté. `MineSceneRenderer` consomme ces profils pour dessiner galeries, puits, surface et géologie, tandis que `MineInteractionPresenter` reste responsable des marqueurs et zones tactiles. Aucun composant v0.5 ne doit appeler une API de mutation de `IndustryGame` ou `IndustrySession`.

**Tech Stack:** Godot 4.7.2, GDScript, renderer `gl_compatibility`, tests headless maison, UI tests Xvfb, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-09-11-visual-depth-v0.5-design.md`

## Global Constraints

- `IndustryGame` et `IndustrySession` restent inchangés.
- Aucun coût, rendement, timer ou palier de progression n'est modifié.
- Le format de sauvegarde reste inchangé.
- HUD compact v0.4 et navigation basse sont conservés.
- Les zones tactiles et actions contextuelles v0.4 restent fonctionnelles.
- Le rendu v0.5 est strictement en lecture seule vis-à-vis du modèle.
- Les choix visuels sont déterministes pour une même profondeur/côté.
- Godot 4.7.2 / `gl_compatibility` / CI Xvfb restent la cible de validation.
- Aucun nouvel asset lourd ni dépendance externe n'est introduit en v0.5.

## File Map

- Create `src/industry/ui/mine_visual_layout.gd` — profils visuels déterministes purs.
- Modify `src/industry/ui/mine_scene_renderer.gd` — consommation des profils et dessin v0.5.
- Modify `src/industry/ui/mine_interaction_presenter.gd` — marqueurs discrets, hover/focus/sélection.
- Modify `src/industry/ui/mine_world.gd` — transmettre la sélection au presenter sans modifier le gameplay.
- Create `tests/test_visual_v05_layout.gd` — tests purs de déterminisme/variété.
- Create `tests/test_visual_v05_world.gd` — assertions UI structurelles du monde.
- Create `tests/test_visual_v05_markers.gd` — comportement visuel des marqueurs.
- Create `tests/test_visual_v05_captures.gd` — captures wide/narrow et sélection.
- Modify `tests/test_runner.gd` — enregistrer la suite pure v0.5.
- Modify `.github/workflows/godot-tests.yml` — déclencher la branche v0.5 et exécuter les nouveaux tests/captures.
- Modify `README.md` — décrire la v0.5 réellement livrée.

---

### Task 1: Deterministic Visual Layout Catalog

**Files:**
- Create: `src/industry/ui/mine_visual_layout.gd`
- Create: `tests/test_visual_v05_layout.gd`
- Modify: `tests/test_runner.gd`
- Modify: `.github/workflows/godot-tests.yml`

**Interfaces:**
- Produces: `MineVisualLayout.gallery_profile(depth: int, side: int, total_depth: int, center_level: int) -> Dictionary`
- Produces: `MineVisualLayout.geology_profile(depth: int) -> Dictionary`
- Produces: `MineVisualLayout.surface_profile(center_level: int) -> Dictionary`
- `gallery_profile()` returns keys: `variant`, `width_scale`, `height`, `support_spacing`, `lamp_stride`, `rail_break_start`, `rail_break_end`, `alcove_side`, `machine_count`, `pipe_count`.
- Valid gallery variants: `standard`, `narrow`, `wide`, `collapsed`, `alcove`, `dead_end`.

- [ ] **Step 1: Add the branch to CI before implementation**

Add `feature/visual-depth-v0.5` to the push branches in `.github/workflows/godot-tests.yml`.

- [ ] **Step 2: Write the failing pure test**

Create `tests/test_visual_v05_layout.gd` with assertions equivalent to:

```gdscript
extends RefCounted

const Layout = preload("res://src/industry/ui/mine_visual_layout.gd")

func run(t: TestSupport) -> void:
    var first := Layout.gallery_profile(60, 0, 150, 6)
    var again := Layout.gallery_profile(60, 0, 150, 6)
    t.equal(first, again, "même profondeur/côté => même profil")

    var variants: Dictionary = {}
    for depth in [12, 30, 60, 90, 120, 150]:
        for side in [0, 1]:
            var profile := Layout.gallery_profile(depth, side, 150, 6)
            variants[str(profile["variant"])] = true
            t.check(profile["width_scale"] >= 0.45 and profile["width_scale"] <= 1.0, "largeur de galerie valide")
            t.check(profile["height"] >= 34.0 and profile["height"] <= 76.0, "hauteur de galerie valide")
    t.check(variants.size() >= 4, "plusieurs silhouettes observables dans un parcours profond")

    var shallow := Layout.geology_profile(30)
    var deep := Layout.geology_profile(150)
    t.check(float(deep["cyan_strength"]) > float(shallow["cyan_strength"]), "profondeur plus cyan")
    t.check(int(deep["fracture_count"]) >= int(shallow["fracture_count"]), "profondeur au moins aussi détaillée")

    t.check(Layout.surface_profile(6)["modules"].size() > Layout.surface_profile(1)["modules"].size(), "surface évolutive avec le Centre")
```

Register the suite in `tests/test_runner.gd`.

- [ ] **Step 3: Run the test and verify RED**

Run:

```bash
./Godot_v4.7.2-stable_linux.x86_64 --headless --path . -s res://tests/test_runner.gd
```

Expected: parse/load failure because `mine_visual_layout.gd` does not exist.

- [ ] **Step 4: Implement the pure layout component**

Create `mine_visual_layout.gd` as a `RefCounted` with static methods only. Use a stable integer key, never `randf()`/`randi()`:

```gdscript
class_name MineVisualLayout
extends RefCounted

const GALLERY_VARIANTS := ["standard", "narrow", "wide", "collapsed", "alcove", "dead_end"]

static func _key(depth: int, side: int) -> int:
    return abs(depth * 31 + side * 17)

static func gallery_profile(depth: int, side: int, total_depth: int, center_level: int) -> Dictionary:
    var key := _key(depth, side)
    var variant := GALLERY_VARIANTS[key % GALLERY_VARIANTS.size()]
    var profile := {
        "variant": variant,
        "width_scale": 0.72 + float((key / 3) % 5) * 0.06,
        "height": 44.0 + float((key / 7) % 4) * 6.0,
        "support_spacing": 44 + (key % 4) * 8,
        "lamp_stride": 1 + (key % 3),
        "rail_break_start": -1.0,
        "rail_break_end": -1.0,
        "alcove_side": -1,
        "machine_count": 1 + (key % 2),
        "pipe_count": 1 + ((key / 5) % 2),
    }
    match variant:
        "narrow":
            profile["height"] = 36.0
            profile["width_scale"] = minf(float(profile["width_scale"]), 0.78)
        "wide":
            profile["height"] = 68.0
            profile["width_scale"] = 1.0
            profile["machine_count"] = 2 + (key % 2)
        "collapsed":
            profile["rail_break_start"] = 0.48
            profile["rail_break_end"] = 0.68
        "alcove":
            profile["alcove_side"] = key % 2
        "dead_end":
            profile["width_scale"] = 0.52 + float(key % 3) * 0.05
    return profile
```

Implement `geology_profile()` with deterministic counts/strengths by depth band, and `surface_profile()` returning module IDs such as `headframe`, `workshop`, `silo`, `operations`, then `ventilation`, `crane`, `antenna`, `pipe_network` as Centre level grows.

- [ ] **Step 5: Run the headless suite and verify GREEN**

Run the same headless command. Expected: all previous tests plus `test_visual_v05_layout.gd` PASS.

- [ ] **Step 6: Commit**

```bash
git add src/industry/ui/mine_visual_layout.gd tests/test_visual_v05_layout.gd tests/test_runner.gd .github/workflows/godot-tests.yml
git commit -m "feat: add deterministic v0.5 mine visual layout"
```

---

### Task 2: Asymmetric Gallery Variants in the Renderer

**Files:**
- Modify: `src/industry/ui/mine_scene_renderer.gd`
- Create: `tests/test_visual_v05_world.gd`
- Modify: `.github/workflows/godot-tests.yml`

**Interfaces:**
- Consumes: `MineVisualLayout.gallery_profile(...)` from Task 1.
- Produces renderer debug properties used only by tests: `gallery_variants_seen: Dictionary`, `gallery_silhouette_count: int`, `broken_rail_count: int`, `alcove_count: int`.

- [ ] **Step 1: Write the failing world test**

Create `tests/test_visual_v05_world.gd` as a `SceneTree` UI test. Instantiate `res://scenes/industry.tscn`, set a deterministic deep presentation state through the real session (`depth = 150`, `center_level = 6`), emit `session.changed`, then assert:

```gdscript
var renderer = screen.find_child("MineSceneRenderer", true, false)
t.check(renderer != null, "renderer v0.5 présent")
t.check(renderer.gallery_variants_seen.size() >= 4, "au moins quatre variantes visibles/connues")
t.check(renderer.gallery_silhouette_count >= 8, "silhouettes gauche/droite générées")
t.check(renderer.broken_rail_count >= 1, "au moins une rupture de rails")
t.check(renderer.alcove_count >= 1, "au moins un renfoncement")
```

Also verify all existing touch targets still exist: `Mine_iron`, `Mine_coal`, `Mine_copper`, `Drill`.

- [ ] **Step 2: Add the test to CI and verify RED**

Add an Xvfb step:

```bash
xvfb-run -a ./Godot_v4.7.2-stable_linux.x86_64 --path . --audio-driver Dummy --rendering-method gl_compatibility -s res://tests/test_visual_v05_world.gd
```

Expected: fail because renderer debug properties/variant drawing do not yet exist.

- [ ] **Step 3: Integrate `MineVisualLayout` into gallery drawing**

Preload the layout in `mine_scene_renderer.gd`. Replace the symmetric `_draw_gallery()` composition with separate left/right profiles:

```gdscript
var left_profile := Layout.gallery_profile(int(depth_value), 0, int(_state.get("depth", 0)), int(_state.get("center_level", 1)))
var right_profile := Layout.gallery_profile(int(depth_value), 1, int(_state.get("depth", 0)), int(_state.get("center_level", 1)))
_draw_gallery_side_profile(left_start, left_end, y, false, accent, left_profile)
_draw_gallery_side_profile(right_start, right_end, y, true, accent, right_profile)
```

Implement profile-specific visuals:
- `standard`: current industrial gallery with small deterministic offsets.
- `narrow`: reduced cavity height, closer roof/supports.
- `wide`: taller cavity, extra machine/storage block.
- `collapsed`: rock pile + interrupted rails between `rail_break_start`/`rail_break_end`.
- `alcove`: extra recessed cavity polygon/rectangle on one side.
- `dead_end`: shorter gallery length and blocked rock face.

Do not alter game state or target coordinates.

- [ ] **Step 4: Run UI test and full existing suite**

Expected: new world test PASS; v0.4 world/layout/actions remain PASS.

- [ ] **Step 5: Commit**

```bash
git add src/industry/ui/mine_scene_renderer.gd tests/test_visual_v05_world.gd .github/workflows/godot-tests.yml
git commit -m "feat: add varied v0.5 gallery silhouettes"
```

---

### Task 3: Detailed Central Shaft and Surface Base

**Files:**
- Modify: `src/industry/ui/mine_scene_renderer.gd`
- Modify: `tests/test_visual_v05_world.gd`

**Interfaces:**
- Consumes: `MineVisualLayout.surface_profile(center_level)`.
- Produces renderer counters: `shaft_platform_count`, `shaft_utility_count`, `surface_feature_count`, `ventilation_visible`.

- [ ] **Step 1: Extend the failing world test**

Add assertions at `depth = 150`, `center_level = 6`:

```gdscript
t.check(renderer.shaft_platform_count >= 5, "plateformes de puits aux horizons")
t.check(renderer.shaft_utility_count >= 3, "câbles/conduites/contrepoids visibles")
t.check(renderer.surface_feature_count >= 7, "base de surface fonctionnellement riche")
t.equal(renderer.ventilation_visible, true, "ventilation identifiable")
```

At `center_level = 1`, assert `surface_feature_count` is lower than level 6.

- [ ] **Step 2: Verify RED**

Run `test_visual_v05_world.gd`; expected failure on the new counters/features.

- [ ] **Step 3: Enrich `_draw_shaft()`**

Keep the shaft at the same X coordinate but add:
- elevator cage rectangle moving from existing animation phase;
- two main cables;
- one counterweight track and block;
- two technical pipes on the outer shaft edges;
- horizontal platforms at every visible 30 m horizon;
- diagonal braces between platforms;
- amber safety lights at platform junctions;
- short connection decks from shaft to each gallery.

Update `shaft_platform_count` and `shaft_utility_count` during draw/state sync for tests.

- [ ] **Step 4: Enrich `_draw_surface()` using `surface_profile()`**

Draw identifiable modules with distinct silhouettes, not aligned rectangles:
- workshop: roof + large service door + small chimney;
- silo: cylindrical body + hopper/legs;
- operations: wider building + windows/screens;
- ventilation: fan housing + duct to shaft;
- crane/antenna/pipes based on Centre level.

Store `surface_feature_count` and `ventilation_visible` from the selected profile, not from frame timing.

- [ ] **Step 5: Run UI and regression tests**

Expected: world test PASS, no change in game snapshot, v0.4 UI/action tests remain green.

- [ ] **Step 6: Commit**

```bash
git add src/industry/ui/mine_scene_renderer.gd tests/test_visual_v05_world.gd
git commit -m "feat: deepen shaft and surface mine presentation"
```

---

### Task 4: Geological Mass, Fractures, Cavities and Depth Atmosphere

**Files:**
- Modify: `src/industry/ui/mine_scene_renderer.gd`
- Modify: `tests/test_visual_v05_world.gd`

**Interfaces:**
- Consumes: `MineVisualLayout.geology_profile(depth)`.
- Produces renderer debug properties: `geology_detail_count`, `visible_cavity_count`, `visible_fracture_count`, `deep_cyan_strength`.

- [ ] **Step 1: Extend the world test for geology**

Drive the renderer at 30 m and 150 m and capture counters:

```gdscript
renderer.set_scene_state(_state_for(30, 2))
var shallow_cyan := renderer.deep_cyan_strength
var shallow_details := renderer.geology_detail_count
renderer.set_scene_state(_state_for(150, 6))
t.check(renderer.deep_cyan_strength > shallow_cyan, "cyan renforcé en profondeur")
t.check(renderer.geology_detail_count > shallow_details, "géologie plus riche en profondeur")
t.check(renderer.visible_fracture_count >= 4, "fissures visibles")
t.check(renderer.visible_cavity_count >= 2, "petites cavités visibles")
```

- [ ] **Step 2: Verify RED**

Expected failure because the current renderer mostly uses horizontal strata and flat fills.

- [ ] **Step 3: Replace flat geology with deterministic details**

For each visible 10 m band, use `geology_profile(depth)` to draw:
- 2–6 irregular stratum segments rather than one full-width line;
- deterministic cracks with 2–4 connected segments;
- rock blocks and rubble clusters near selected horizons;
- shallow dark cavities as polygons/ellipses;
- mineral inclusions with restrained amber/cyan accents;
- local shadow halos around galleries/shaft.

All positions must derive from integer depth and fixed arithmetic; do not call random generators during draw.

- [ ] **Step 4: Implement depth palette progression**

Keep warm/neutral 0–60 m; dim 60–90 m; introduce cyan 90–120 m; strengthen turquoise/crystal inclusions 120–150 m; make 150 m+ colder without turning the entire scene neon.

Set `deep_cyan_strength` from the deepest visible profile, not from animation phase.

- [ ] **Step 5: Run world and non-mutation regression**

Expected: geology assertions PASS and the existing renderer non-mutation test remains PASS.

- [ ] **Step 6: Commit**

```bash
git add src/industry/ui/mine_scene_renderer.gd tests/test_visual_v05_world.gd
git commit -m "feat: add deterministic geological depth detail"
```

---

### Task 5: Context-Aware World Markers

**Files:**
- Modify: `src/industry/ui/mine_interaction_presenter.gd`
- Modify: `src/industry/ui/mine_world.gd`
- Create: `tests/test_visual_v05_markers.gd`
- Modify: `.github/workflows/godot-tests.yml`

**Interfaces:**
- Produces: `MineInteractionPresenter.set_selected_key(key: String) -> void`.
- Produces test-readable `marker_alpha(key: String) -> float` and `marker_is_emphasized(key: String) -> bool`.
- Rest marker alpha target: `<= 0.45`.
- Hover/focus/selected alpha target: `>= 0.90`.

- [ ] **Step 1: Write the failing marker test**

Instantiate the real industry scene, locate `MineInteractionPresenter`, then assert:

```gdscript
var presenter = screen.find_child("MineInteractionPresenter", true, false)
await process_frame
t.check(presenter.marker_alpha("iron") <= 0.45, "Fer discret au repos")
presenter.set_selected_key("iron")
await process_frame
t.check(presenter.marker_alpha("iron") >= 0.90, "Fer renforcé quand sélectionné")
t.check(presenter.marker_is_emphasized("iron"), "marqueur sélectionné signalé")
presenter.set_selected_key("")
```

Also simulate `grab_focus()` on `Mine_copper` and verify copper reaches full emphasis. Confirm `Mine_iron.modulate.a <= 0.08` so the tactile button remains invisible.

- [ ] **Step 2: Add CI step and verify RED**

Run under Xvfb. Expected failure because presenter has no selection/focus emphasis API.

- [ ] **Step 3: Implement marker presentation states**

In presenter:
- store `_selected_key`;
- keep rest label alpha around `0.30–0.40` and font size 10–11;
- use `target.is_hovered()`, `target.has_focus()`, or selected key to set alpha to `1.0` and optionally font size 12;
- preserve copper for drill, cyan for sites/discoveries, neutral for raw mines;
- expose the two test helpers without touching gameplay state.

- [ ] **Step 4: Wire selection from `MineWorld`**

Before emitting `selection_changed(kind, id)`, translate to the presenter key:
- mine => resource id (`iron`, `coal`, `copper`);
- drill => `Drill`;
- discovery => `Discovery_<sanitized id>`;
- site => `Site_<sanitized id>`.

When selection is cleared from the context panel, allow the presenter to return to rest state; do not remove the existing context action behavior.

- [ ] **Step 5: Run marker + action regression**

Expected: marker test PASS and `test_progression_ui_actions.gd` still PASS with real clicks.

- [ ] **Step 6: Commit**

```bash
git add src/industry/ui/mine_interaction_presenter.gd src/industry/ui/mine_world.gd tests/test_visual_v05_markers.gd .github/workflows/godot-tests.yml
git commit -m "feat: integrate subtle context-aware world markers"
```

---

### Task 6: v0.5 Showcase, Documentation and Final Gate

**Files:**
- Create: `tests/test_visual_v05_captures.gd`
- Modify: `.github/workflows/godot-tests.yml`
- Modify: `README.md`

**Interfaces:**
- Produces CI artifact images: `v05-wide-60m.png`, `v05-wide-150m.png`, `v05-narrow-90m.png`, `v05-wide-selected.png`.
- No gameplay interface changes.

- [ ] **Step 1: Create deterministic capture scenarios**

`test_visual_v05_captures.gd` must instantiate the real industry screen and set presentation-only test state on the in-memory game before emitting `session.changed`.

Capture:

```text
1280x800 @ 60 m, context closed -> v05-wide-60m.png
1280x800 @ 150 m, Centre 6, context closed -> v05-wide-150m.png
720x1000 @ 90 m -> v05-narrow-90m.png
1280x800 @ 150 m, select a discovery/site -> v05-wide-selected.png
```

The test must save PNGs into the `--screenshots` directory and fail if any image is empty or `save_png()` returns non-OK.

- [ ] **Step 2: Add the v0.5 capture step to CI**

Add:

```bash
timeout 90s xvfb-run -a ./Godot_v4.7.2-stable_linux.x86_64 --path . --audio-driver Dummy --rendering-method gl_compatibility -s res://tests/test_visual_v05_captures.gd -- --screenshots /tmp/digger-ui
```

Keep the existing `industry-ui` artifact upload so v0.4 and v0.5 images are available together.

- [ ] **Step 3: Update README with only shipped v0.5 behavior**

Document:
- deterministic semi-procedural gallery variety;
- richer shaft and surface base;
- geological depth progression;
- contextual world markers;
- explicit statement that economy/save schema are unchanged.

Do not claim final art assets, Android release readiness, or infinite procedural generation.

- [ ] **Step 4: Run the complete final gate on the exact head**

Run locally if available and then require GitHub Actions success on the same commit:

```bash
./Godot_v4.7.2-stable_linux.x86_64 --headless --editor --quit --path .
./Godot_v4.7.2-stable_linux.x86_64 --headless --path . -s res://tests/test_runner.gd
```

CI must additionally pass all Xvfb tests from v0.3/v0.4/v0.5 and upload the screenshot artifact.

- [ ] **Step 5: Inspect the four v0.5 captures**

Reject the gate and fix before PR if any of these remain:
- repeated identical gallery silhouettes across most visible horizons;
- shaft still reads as two vertical lines only;
- surface still reads as aligned rectangles;
- flat geology dominates most of the screen;
- marker text dominates the scenery;
- narrow capture clips navigation or context controls.

- [ ] **Step 6: Commit documentation/captures**

```bash
git add tests/test_visual_v05_captures.gd .github/workflows/godot-tests.yml README.md
git commit -m "test: validate visual depth v0.5 showcase"
```

- [ ] **Step 7: Final integration action**

After the exact-head CI is green and captures are visually accepted, open a PR from `feature/visual-depth-v0.5` to `main`. Do not merge `main` automatically unless the user explicitly asks for publication.

---

## Self-Review

- Spec coverage: all six spec areas are mapped to Tasks 1–6.
- Gameplay isolation: no task modifies `industry_game.gd`, `industry_session.gd`, catalog economics, save schema, recipes, timers or progression rules.
- Determinism: all variety comes from `MineVisualLayout` integer keys; no random frame-time generation is permitted.
- Responsive coverage: Task 6 includes 1280×800 and 720×1000 captures.
- Interaction coverage: Task 5 preserves real touch targets and Task 2 re-checks their presence.
- Regression coverage: existing v0.1–v0.4 suites remain in CI throughout.
- Placeholder scan: no TBD/TODO/unspecified implementation steps remain.
- Type consistency: `gallery_profile`, `geology_profile`, `surface_profile`, `set_selected_key`, and renderer debug properties are named consistently across producer/consumer tasks.
