# Project Digger — Final Graphics v0.6 Design

Date: 2026-09-11
Branch: `feature/final-graphics-v0.6`
Status: design approved in conversation, implementation not started

## Goal

Bring the Mine screen as close as practical to a final premium game presentation while preserving the existing v0.3–v0.5 gameplay, save model, economy, interactions, and navigation.

The approved visual target is the latest generated DIGGER mockup: a dense industrial-retrofuturist cutaway mine with a dominant central shaft, large readable extraction installations, thick rock mass, strong warm/cool lighting contrast, detailed surface base, and deeper cyan sci-fi accents.

This is not another pass of small procedural details. v0.6 changes the visual architecture from “thin procedural diagram” to “large illustrated modules + procedural geology/lighting + existing interactive hitboxes”.

## Non-goals

- No changes to economy, costs, production rates, timers, progression rules, capacity, technologies, events, save schema, or migration.
- No changes to public gameplay APIs unless strictly required for read-only presentation state.
- No new gameplay resources.
- No replacement of the Mine screen by a single static image.
- No dependency on runtime network access.

## Chosen approach

### Hybrid modular renderer

Use Godot-composed illustrated modules as the primary visual language, with procedural geology, depth atmosphere, lighting, particles, rails, cables, and overlays around them.

Why this approach:
- much closer to the approved final mockup than pure procedural line drawing;
- remains interactive and state-driven;
- modules can evolve independently without rewriting gameplay;
- supports desktop and narrow/mobile layouts;
- keeps deterministic tests possible.

A full static background was rejected because it would not reflect depth, Centre level, discoveries, sites, or interactions. Pure procedural drawing was rejected because v0.5 already reached the point of diminishing visual returns.

## Visual direction

75% industrial retro-future / 25% restrained sci-fi.

Primary materials:
- dark steel and gunmetal;
- concrete and layered rock;
- copper/brass accents;
- amber work lights;
- cyan/turquoise deep mineral light;
- occasional hazard yellow/orange.

Avoid:
- cartoon steampunk gear spam;
- flat debug rectangles;
- thin schematic lines as primary shapes;
- large floating UI labels inside the world;
- excessive neon at shallow depth.

## Architecture

### 1. MineSceneRenderer remains the visual root

`src/industry/ui/mine_scene_renderer.gd` remains responsible for:
- camera-relative spatial composition;
- geology and depth atmosphere;
- shaft placement;
- module placement;
- light/particle overlays;
- visual metrics used by tests.

It does not mutate game state.

### 2. New module renderer layer

Add `src/industry/ui/mine_module_renderer.gd` as a read-only `Control`/drawing component responsible for large recognizable installations.

It exposes simple drawing methods/state for:
- surface workshop;
- silo/storage;
- control center;
- ventilation building;
- crane/utility yard;
- shaft station;
- iron extraction module;
- coal extraction module;
- copper extraction module;
- crystal/deep anomaly module;
- service gallery/depot module.

The module renderer receives presentation state only. It never calls gameplay actions.

### 3. Existing MineInteractionPresenter stays on top

Existing interactive buttons/hitboxes remain authoritative for clicks.

The new illustrated modules sit under interaction targets. Marker emphasis still follows hover/focus/selection and context panel state.

### 4. Existing MineVisualLayout remains deterministic

`mine_visual_layout.gd` continues to provide deterministic layout variants. It will gain module placement/profile helpers where needed, but no runtime RNG.

## Surface redesign

At Centre level 1–6 the surface becomes an evolving industrial base rather than a collection of primitive shapes.

Visual modules:
- workshop with lit bay and internal silhouettes;
- cylindrical silo with ladder/platforms;
- headframe with pulley wheel, cables and service deck;
- control center with lit windows and antenna equipment;
- ventilation block with large visible fan;
- crane/mechanical arm with storage yard;
- pipe/conveyor links between modules;
- stronger ground edge and distant mountain/industrial skyline silhouette.

Centre level controls only visual presence/detail of modules already justified by existing progression.

## Central shaft redesign

The shaft becomes the dominant visual anchor and is widened roughly 35–45% relative to v0.5.

Required elements:
- visible elevator cage;
- twin guide rails;
- hoist cables;
- counterweight track;
- utility pipes/cable trays;
- station platforms at unlocked horizons;
- hazard markings and indicator lights;
- lateral station entrances that connect visibly to galleries;
- lower drill assembly integrated into the shaft rather than floating below it.

The shaft must remain readable on 720×1000 without hiding interaction targets.

## Resource installation identity

### Iron

Readable without text:
- rusty/brown ore piles and seams;
- crusher body;
- heavy conveyor;
- ore carts;
- amber light;
- thick structural beams.

### Coal

Readable without text:
- black coal piles;
- dust/steam haze;
- larger ventilation duct/fan;
- darker warm lighting;
- conveyor and carts.

### Copper

Readable without text:
- orange/green mineral veins;
- lateral drill heads;
- pipes and processing tank/hopper;
- copper-colored machinery accents;
- cyan-green reflections in deeper variants.

### Crystal/deep sites

- bright but localized cyan/turquoise mineral clusters;
- scanning/instrumentation hardware;
- deep drilling rigs;
- stronger cold light pools;
- restrained sci-fi panels, never a full neon scene.

## Geology and depth

Replace the visual impression of flat horizontal bands with thicker irregular rock masses around playable galleries.

Add:
- irregular ceiling/floor silhouettes;
- larger strata chunks;
- boulders and broken shelves;
- cavity mouths;
- mineral seams tied to resource identity;
- shadow pockets behind infrastructure;
- denser detail with depth.

Depth language:
- 0–30 m: warm industrial stone, brown/grey;
- 30–60 m: steel/blue-grey, heavier supports;
- 60–90 m: darker dense rock, stronger machinery;
- 90–120 m: first significant cyan mineral accents;
- 120–150 m: large cavities, ancient/abandoned visual traces;
- 150 m+: strongest mystery/cyan contrast, still subordinate to industrial readability.

## Lighting and atmosphere

Add deterministic visual effects driven by animation phase only:
- warm lamp pools;
- subtle bloom-like circles/gradients using layered primitives/textures;
- dust motes;
- coal haze;
- small steam exhaust;
- moving conveyor highlights;
- elevator indicator motion;
- localized cyan glow in deep mineral zones.

No visual effect may alter gameplay timing or state.

## Labels and UI integration

Top HUD and bottom navigation remain structurally unchanged.

World labels become secondary:
- tiny stencil/signage integrated into walls/machines;
- low-opacity idle state;
- stronger on hover/focus/selection;
- resource identity must primarily come from art, not text.

The context panel remains the source of explicit actions and details.

## Asset strategy

The runtime should use reusable local visual assets where they materially improve fidelity. Assets must be stored under `assets/industry/v06/` and loaded locally by Godot.

Preferred asset set:
- surface workshop;
- silo;
- operations/control center;
- ventilation unit;
- crane/yard;
- iron machinery module;
- coal machinery module;
- copper machinery module;
- deep crystal machinery module;
- shaft/elevator decorative overlays.

Where transparent PNG assets are used, they must be sized/cropped for modular placement and must not contain UI text that conflicts with localization. Procedural fallback shapes remain available so missing/failed asset loads do not break the scene.

The approved mockup itself is a visual target/reference, not a single runtime background.

## Responsive behavior

### 1280×800
- shaft dominates center;
- surface base readable at shallow focus;
- left/right resource installations are visually distinct;
- context panel overlays without permanently shrinking the world.

### 720×1000
- modules simplify visually but retain identity;
- shaft width is capped so galleries remain usable;
- context uses bottom sheet;
- labels stay inside viewport;
- no horizontal overflow.

## Performance

Target stable rendering in Godot 4.7.2 `gl_compatibility`.

Rules:
- reuse assets rather than spawning hundreds of unique nodes;
- prefer one renderer with batched drawing for geology/rails/lights;
- keep animated particles/effects capped and deterministic;
- avoid per-frame allocation of large arrays where possible;
- do not create one Control per visual pebble/fissure.

## Tests

Add/extend deterministic tests for:
- module renderer exists and is read-only;
- surface modules appear according to Centre level;
- shaft width/station count and elevator visuals;
- iron/coal/copper installation identity metrics;
- deep cyan intensity grows with depth;
- geology silhouette/detail count grows without mutating economy state;
- interactive hitboxes remain clickable over the new art;
- marker selection/clear behavior remains intact;
- wide and narrow layout bounds;
- render-only animation leaves `IndustryGame.snapshot()` unchanged.

CI captures:
- 1280×800 at surface/30 m;
- 1280×800 at 60 m;
- 1280×800 at 120–150 m;
- 1280×800 selected deep site;
- 720×1000 at 90 m.

## Acceptance criteria

1. A screenshot no longer reads primarily as a schematic or debug diagram.
2. The central shaft is the dominant hero object.
3. Iron, coal and copper zones are recognizable even with their text hidden.
4. Rock visually surrounds and contains galleries instead of appearing as flat background bands.
5. Surface reads as a coherent mine base with workshop, storage, control and ventilation functions.
6. Deep zones clearly introduce cyan/turquoise and larger cavities without turning the whole screen neon.
7. Major machinery is substantially larger than v0.5 micro-details.
8. Existing Mine/Industrie/Centre/Technologie navigation is unchanged.
9. Existing gameplay actions remain real-clickable.
10. No economy/save/progression behavior changes.
11. All v0.1–v0.5 tests remain green.
12. Godot 4.7.2 CI and wide/narrow screenshot gates are green.

## Definition of done

v0.6 is done when the Mine screen visually resembles the approved final mockup in composition and identity, while remaining a real state-driven Godot scene rather than a static illustration, and all existing gameplay/CI behavior is preserved.