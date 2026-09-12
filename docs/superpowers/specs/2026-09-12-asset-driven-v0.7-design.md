# Project Digger — Asset-Driven Visual v0.7 Design

## Goal

Replace the remaining schematic/vector-heavy mine presentation with an asset-driven renderer whose primary visual language comes from detailed transparent PNG modules, while preserving the existing gameplay model, save format, progression, interaction zones and responsive behavior.

The target is a materially more final-looking game screen: illustrated mining buildings and machines become the dominant visual objects; Godot procedural drawing remains only for terrain mass, connective structure, lighting, atmosphere and state-driven variation.

## Scope

This is a visual architecture change only.

Must not change:
- `IndustryGame` economy or formulas;
- timers or production rates;
- progression milestones;
- save schema or migration behavior;
- resource counts;
- context actions and interaction semantics;
- existing touch/click target meaning.

May change:
- Mine renderer classes under `src/industry/ui/`;
- visual asset catalog and loading;
- asset placement and scaling;
- procedural geology/connective drawing used behind or around the PNG modules;
- capture tests and CI visual gates;
- documentation.

## Approved Visual Direction

Primary style:
- 75% retro-futurist industrial;
- 25% restrained industrial sci-fi;
- dark steel and gunmetal;
- copper/brass piping and fittings;
- warm amber industrial lighting;
- cyan only for deep/crystal content;
- detailed but readable side-view 2D game art;
- no cartoon steampunk gears everywhere;
- no giant single background image representing the entire mine.

The renderer must feel assembled from real industrial modules rather than drawn from lines and primitive rectangles.

## Asset Pack

The v0.7 pack uses ten generated RGBA PNGs with real transparency. The source images have been verified as RGBA with alpha values from 0 to 255.

Repository destination:

`res://assets/industry/v07/`

Canonical names:
- `surface_workshop.png`
- `surface_silo.png`
- `surface_ventilation.png`
- `surface_crane.png`
- `shaft_station.png`
- `shaft_elevator.png`
- `iron_installation.png`
- `coal_installation.png`
- `copper_installation.png`
- `crystal_installation.png`

Visual roles:
- Workshop: main surface anchor / operations-workshop building.
- Silo: surface bulk storage and ore handling.
- Ventilation: major surface ventilation/exhaust machinery.
- Crane: surface loading/gantry visual focal object.
- Shaft station: repeated station/platform module at mine horizons.
- Shaft elevator: animated cage moving inside the shaft.
- Iron installation: crusher/conveyor/bins with red-brown ore identity.
- Coal installation: coal bunkers/conveyors/ventilation with black material identity.
- Copper installation: processing line with orange/green copper cues and piping.
- Crystal installation: deep cavern/extraction system with cyan crystal glow.

## Architecture

### 1. `MineV07Assets`

Create `src/industry/ui/mine_v07_assets.gd` as the only authority for v0.7 asset paths and texture loading.

Responsibilities:
- map stable visual IDs to `res://assets/industry/v07/*.png`;
- cache loaded `Texture2D` objects;
- expose `has_asset(id)` and `texture_for(id)`;
- keep image processing read-only relative to gameplay;
- do not perform the v0.6 white-background removal because the v0.7 files already contain proper alpha.

Stable IDs:
- `surface_workshop`
- `surface_silo`
- `surface_ventilation`
- `surface_crane`
- `shaft_station`
- `shaft_elevator`
- `iron_installation`
- `coal_installation`
- `copper_installation`
- `crystal_installation`

### 2. Asset-driven final renderer

Create `src/industry/ui/mine_asset_renderer.gd`, extending the current v0.7-compatible final renderer rather than changing gameplay/UI ownership.

It becomes the presentation layer consumed by the existing Mine screen.

Drawing order:
1. geological background and depth atmosphere;
2. large rock masses/cavities;
3. shaft body/connective rails/cables;
4. illustrated PNG structures;
5. procedural local connectors/pipes/rails only where needed to visually join modules;
6. ambient effects and lighting glows;
7. existing interaction presenter remains above the renderer.

PNG modules must dominate the image. Procedural primitives must not redraw a second fake version of the same machine underneath or on top.

### 3. Surface composition

Wide layout:
- workshop on left side;
- headframe/shaft near center;
- silo on right-center;
- ventilation farther right;
- crane used as a large secondary focal object when Centre progression allows it.

The old v0.6 tiny surface sprites are replaced by the new high-detail PNGs.

The workshop may absorb the previous separate control-room visual role; no duplicate control-room building is required.

Narrow/mobile layout:
- preserve workshop + shaft + one or two major supporting modules;
- omit or reduce crane before shrinking the primary modules below legible scale;
- keep all assets inside viewport bounds.

### 4. Shaft composition

The shaft keeps its procedural vertical mass/cables/rails for continuity across arbitrary depth.

Replace most platform/station primitives with `shaft_station.png` at visible horizons.

Use `shaft_elevator.png` as the actual moving lift visual.

The elevator position continues to derive from presentation animation state only; it must not become gameplay state or save state.

Shaft station art must align to existing horizon depth coordinates and must not move interaction targets.

### 5. Resource installations

At the shallow resource horizon, replace the v0.6 illustrated-placeholder modules and most procedural machine details with the new installations:
- iron installation on left;
- coal installation near/left of shaft as space allows;
- copper installation on right.

Because the PNGs are larger and more detailed, compositions may overlap the old gallery footprint visually, but their interactive target rectangles remain the existing mine targets.

The crystal installation appears only when crystal/deep content is unlocked and should sit inside a visually darker cavern region with local cyan glow.

### 6. Geology and masking strategy

Do not use PNGs as a single mine background.

Procedural geology remains responsible for:
- continuous depth mass;
- strata;
- cavities;
- variation by depth;
- darkness around tunnels;
- connecting rock around modules.

Large PNG installations are placed inside cutout/open cavern bands so they do not look pasted onto flat rock.

Where needed, draw dark foreground rock silhouettes partially in front of module edges to visually embed them into the mine.

### 7. Lighting and animation

Keep lighting lightweight and 2D:
- local amber glow around surface/industrial modules;
- cyan glow around crystal module;
- existing dust/steam retained;
- elevator cage moves;
- future fan/conveyor animation can be added later only if individual rotating/moving sprites exist.

Do not fake detailed moving machinery by distorting the entire PNG.

### 8. Interaction preservation

The existing `MineInteractionPresenter` remains the interaction layer.

PNG assets must use `MOUSE_FILTER_IGNORE` or be drawn directly by the renderer so they cannot steal clicks.

Existing IDs and context actions remain unchanged:
- `Mine_iron`
- `Mine_coal`
- `Mine_copper`
- `Drill`
- discovery/site targets.

Minimum tactile targets remain at least 44 px on narrow layouts.

## Scaling Rules

Do not scale every asset to the same rectangle dimensions.

Each v0.7 asset gets an authored aspect-preserving target box chosen by role. Fit behavior is equivalent to `contain`, not stretch.

Recommended visual size ranges at 1280×800 gameplay viewport:
- workshop: 260–330 px wide;
- silo: 180–240 px wide;
- ventilation: 160–220 px wide;
- crane: 210–300 px wide;
- shaft station: 300–420 px wide;
- elevator: 65–95 px wide;
- resource installation: 330–460 px wide where layout permits;
- crystal installation: 360–520 px wide in deep views.

Narrow mode may reduce these by approximately 25–40%, but must prefer hiding tertiary surface clutter over making the main modules unreadable.

## Asset Import Requirements

Godot import expectations:
- lossless PNG source;
- alpha preserved;
- filtering enabled for downscaled game presentation;
- mipmaps disabled for the current 2D target;
- repeat disabled.

No runtime white-background cleanup should be needed for v0.7.

## Testing

### Asset tests

Add `tests/test_visual_v07_assets.gd` validating:
- all 10 assets exist;
- all 10 load as `Texture2D`;
- dimensions are non-zero;
- alpha exists at transparent corners;
- no asset falls back to a v0.6 path.

### Renderer tests

Add `tests/test_visual_v07_renderer.gd` validating:
- wide and narrow composition metrics;
- visible major asset count;
- station count increases with depth;
- elevator is present and remains inside shaft bounds;
- resource identities are mapped to the correct assets;
- crystal module is absent before deep unlock and present after unlock;
- renderer does not mutate state.

### Interaction regression

Reuse and extend responsive/context-action tests to confirm:
- hitboxes remain available;
- clicks still open the expected context;
- closing context returns marker to rest;
- PNG layer does not capture mouse input.

### Capture matrix

Generate deterministic screenshots:
- `v07-wide-surface.png`
- `v07-wide-60m.png`
- `v07-wide-150m.png`
- `v07-narrow-90m.png`
- `v07-wide-selected.png`

Visual rejection criteria:
- scene still looks mostly like line art / technical diagram;
- PNG assets are visibly stretched;
- buildings float without geological/structural integration;
- resource installations are too small to read;
- shaft stations do not align with the shaft;
- surface clips at the top or sides;
- mobile view becomes unreadable;
- labels or hitboxes dominate the art.

## CI and Integration

Add v0.7 tests/captures to the existing Godot 4.7.2 CI workflow.

The final branch must pass:
- project import;
- full headless suite;
- legacy UI/progression tests;
- v0.4/v0.5/v0.6 visual regressions;
- new v0.7 asset/renderer/responsive tests;
- v0.7 capture generation.

The branch must be visually reviewed from the CI artifact before PR/merge.

No merge to `main` without explicit user approval.
