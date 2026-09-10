# Project Digger v0.2 — Design

Date: 2026-09-10
Branch: `feature/digger-v0.2`
Base: v0.1 merged and green on `main`

## 1. Goal

The v0.2 turns the validated technical vertical slice into the first slice that already feels like a real game.

The priority is not to add more simulation depth. The priority is to make the existing loop easier to read, more atmospheric, and more satisfying:

`Observer → Préparer → Déclencher/Résoudre → Observer`

The v0.2 must preserve the deterministic terrain simulation, the hidden logical grid, energy costs, undo/cancel, stability/collapse rules, ancient-network continuity, persistence, and the existing completion objective.

The v0.2 succeeds when a new player can understand the main cave problem without explanation, manipulate the terrain precisely, trigger a satisfying collapse, and feel that the game already has a distinct identity.

## 2. Design pillars

### 2.1 Organic world, exact simulation

The terrain remains cell-based logically, but the grid must no longer dominate the normal rendering.

- Observer mode: no global grid.
- Prepare mode: tactical precision appears only where useful.
- Hovered, selected, targeted, and analyzed cells may reveal their logical boundaries locally.
- Rendering must never change simulation authority.

The player should see a cave first and a grid second.

### 2.2 Readability before decoration

Every material must remain identifiable without reading a tooltip:

- `rock_common`: neutral gray stone, matte and readable.
- `rock_fragile`: warmer brown/ochre, visibly fractured.
- `rock_dense`: dark slate, compact and heavy.
- `stabilizer`: cyan/turquoise mineral/crystalline material.
- ancient conductive route: luminous cyan geometric/mineral language, distinct from ordinary stabilizer deposits.

Atmosphere must not hide actionable terrain.

### 2.3 Calm decisions, strong consequences

The game should be quiet during observation, informative during preparation, and briefly impactful during resolution.

This is not a constant spectacle game. The emotional rhythm is:

`calm → inspect → decide → tension → impact → calm`

## 3. Visual direction

### 3.1 Camera and composition

The game remains a 2D side cutaway.

The playable foreground contains the authoritative terrain. Behind it, a non-interactive cavern background creates depth using dark gradients, silhouettes, recesses, distant rock formations, and restrained atmospheric details.

The main cave composition should make three things readable at a glance:

1. where the player entered,
2. what formation blocks downward progress,
3. where the ancient relay/network is located.

### 3.2 Organic terrain rendering

The v0.1 renderer draws visible rectangular cells. The v0.2 renderer must preserve the same cells internally while softening the resulting silhouette.

Required visual techniques may include:

- deterministic edge variation,
- irregular corners and chipped edges,
- material-specific internal marks,
- darker boundary shading between solid terrain and empty cavern,
- small decorative protrusions that do not alter collision/simulation,
- clusters/veins rather than perfectly rectangular visual bands.

The renderer must remain deterministic: the same cell/model state must render consistently across redraws and reloads.

No procedural visual effect may affect gameplay state.

### 3.3 Background and depth

Empty cells are not rendered as flat gray/black space. The cave should have a background layer that communicates depth without reducing foreground readability.

Target feel:

- dark blue-gray cavern depth,
- subtle warm accents in deeper recesses,
- cyan highlights around ancient/mineral elements,
- no visually busy animated background in v0.2.

### 3.4 Ancient technology identity

Ancient technology combines geometric monolithic forms with crystalline/mineral growth.

The relay and conductive route should use:

- cyan/turquoise light,
- visible nodes or junctions,
- clean geometric lines embedded into rock,
- a small persistent glow when connected,
- a clearer pulse during resolution.

The ancient system should feel discovered inside the geology rather than placed on top like a modern electrical installation.

## 4. First real cave

The v0.1 technical test layout is replaced by a designed cave with three connected spaces.

### 4.1 Entrance / learning pocket

A compact, safe upper area introduces the environment.

It must:

- contain immediately readable common rock,
- expose fragile rock nearby,
- allow a harmless digging action,
- visually suggest the direction of descent,
- avoid a large instructional text wall.

This section is short. It exists to orient the player, not to become a tutorial level.

### 4.2 Central chamber / main problem

The central chamber is the visual and mechanical focus of v0.2.

It contains:

- a large dense formation blocking the main descent,
- removable supports that can make the formation collapse,
- fragile material that communicates instability,
- a secondary stabilizer route/deposit,
- the ancient network positioned away from the collapse shaft but visible enough to create a preservation constraint.

The intended player thought is:

> If I remove these supports, what falls, and will the relay survive?

The main formation should read as heavy before analysis mode is enabled.

### 4.3 Descent / completion space

The collapse opens a clear route downward.

Once the required corridor is open and the network remains in a valid state, the objective is completed and the final message is shown.

The descent should visually reveal more depth below so completion feels like opening the next layer of the world rather than simply clearing a test condition.

### 4.4 Solution philosophy

The cave has one obvious canonical solution but should not behave like a single-answer scripted puzzle.

The player may, within the limits of the existing systems:

- remove the supports directly,
- reinforce/reposition material before triggering,
- collect/use stabilizer as part of preparation where the existing mechanics permit it.

The v0.2 does not need many alternative solutions. It needs enough systemic freedom that the player feels they manipulated a physical problem rather than executed a hidden script.

## 5. Observer mode

Observer mode is the atmospheric default.

### Required behavior

- No global grid overlay.
- Minimal HUD.
- Terrain materials readable without overlays.
- Ancient relay connection readable in-world and in HUD.
- Current objective readable but compact.
- Hover may show a very subtle local indication, but should not cover the cave with UI.

### HUD content

Observer HUD should expose only essential state:

- `Observer`
- current/available cycle energy
- `Relais : connecté` or `Relais : coupé`
- current objective
- compact access to tools / Prepare

The cave must occupy most of the visual hierarchy.

## 6. Prepare mode

Prepare mode is the tactical layer.

### Required behavior

- Active tool is visually obvious.
- Hovered cell gets a clear local outline.
- Selected cells remain visible.
- If relevant, the local material/type and action cost can be shown near the cursor or in a compact contextual panel.
- Stability overlays appear only in this mode.
- The whole map must not become a permanent square grid.

### Stability language

- Stable: green, low-opacity overlay.
- Fragile: orange/amber overlay.
- Critical: red overlay.

These colors are an analysis layer, not the base terrain palette.

The overlay must preserve underlying material readability.

### Prepare controls

The UI must provide direct access to:

- active tool selection,
- remaining energy,
- `Déclencher`,
- `Annuler`,
- `Undo`.

Keyboard shortcuts remain supported.

## 7. HUD redesign

The current v0.1 panel is functionally correct but visually resembles a debug/control panel.

The v0.2 reorganizes information into two lightweight zones:

### 7.1 Status strip

A compact top or top-left strip containing state, energy, relay status, and objective.

It should remain readable over the cave through a restrained translucent/dark backing rather than a large opaque box.

### 7.2 Tool/action bar

A compact bottom or side bar containing the current tools and mode-specific actions.

Observer mode shows the minimum required actions.
Prepare mode expands to show Trigger, Cancel, and Undo.

Buttons should communicate selected/available/disabled state through shape, light, icon, and text rather than relying on color alone.

### 7.3 Contextual hover information

When a cell is actionable, the player can see concise contextual information such as:

- material name,
- active action,
- energy cost,
- non-diggable state when applicable.

This information should appear locally and disappear when no longer relevant.

## 8. Feedback and audiovisual direction

### 8.1 Observer ambience

The base state remains calm.

Suggested sound palette:

- distant cave resonance,
- occasional drops or small rock ticks,
- restrained low-frequency ambience,
- subtle ancient-relay hum.

No dense music system is required for v0.2.

### 8.2 Prepare feedback

Interactions should provide concise feedback:

- hover/selection: light mineral/UI tick,
- common rock: dry stone response,
- fragile rock: sharper/cracking response,
- dense rock: heavy/low response,
- stabilizer: crystalline response,
- ancient conductor: mineral-electronic tone.

Fragile and critical analysis states may add restrained looping/occasional tension cues, but must not become noisy.

### 8.3 Resolution sequence

Triggering a resolution should feel important without becoming cinematic interruption.

Target sequence:

1. very short anticipation pause,
2. ancient-network light pulse,
3. collapse resolution,
4. dust/debris visual feedback,
5. short camera impulse on meaningful heavy impacts,
6. final state update,
7. short success cue if the descent is opened.

The simulation remains deterministic and authoritative. Visual/audio feedback reacts to resolved movements; it never decides them.

### 8.4 Camera shake limits

Camera shake must be brief and proportional to the event.

- Small movement: none or nearly none.
- Significant common/fragile collapse: very light impulse.
- Dense gate/large mass impact: short noticeable impulse.

No continuous shake.

## 9. System boundaries

The v0.2 should improve presentation without coupling rendering to simulation.

Recommended responsibility boundaries:

### TerrainModel / simulation systems

Remain authoritative for:

- cells,
- materials,
- staged actions,
- energy,
- stability,
- collapse movement,
- relay connectivity,
- persistence.

### TerrainRenderer

Responsible for:

- foreground terrain appearance,
- material visual language,
- organic edge treatment,
- local selection/hover display,
- stability overlays,
- movement rendering.

It does not modify TerrainModel.

### Cave presentation layer

Responsible for non-authoritative environment elements:

- cavern background,
- decorative depth,
- environmental props/glows that do not affect gameplay.

### HUD

Displays controller/model state and emits UI intent only.

It does not compute stability or game outcomes.

### Feedback controller

A small presentation-only component listens to meaningful events and coordinates:

- camera impulse,
- dust/debris effects,
- relay pulse,
- audio cues.

It must consume simulation results rather than duplicate simulation logic.

## 10. Persistence

Existing v0.1 terrain persistence remains valid.

The v0.2 visual changes must not require saving decorative renderer state.

If any new gameplay-relevant value is introduced during implementation, the save schema must be explicitly versioned and tested. Pure presentation state is not persisted unless there is a clear user-facing need.

## 11. Testing requirements

The current headless suite remains mandatory.

The v0.2 must add or update tests for the parts that can be verified deterministically without rendering screenshots.

At minimum:

- cave layout dimensions and mandatory zones,
- diggable entrance path,
- presence of common/fragile/dense/stabilizer materials,
- canonical support-removal solution,
- expected dense formation collapse,
- open exit corridor after solution,
- relay preserved by the canonical solution,
- save/reload after completion,
- hover/cell-coordinate conversion if renderer interaction logic changes,
- feedback classification logic if event magnitude is introduced.

Visual quality itself requires manual validation in Godot and cannot be considered proven by headless tests alone.

CI should run Godot 4.7.2 headless tests on the active v0.2 development branch and on `main` after merge.

## 12. Manual acceptance checklist

Before v0.2 can merge:

- Game launches without parser/runtime errors.
- Observer view reads as an organic cave rather than bands of cells.
- Global grid is absent in Observer mode.
- Materials remain distinguishable.
- Prepare mode clearly reveals local targeting precision.
- Stable/Fragile/Critical overlays are readable without hiding terrain.
- Tool selection and energy are understandable at a glance.
- Trigger/Cancel/Undo remain usable.
- Canonical collapse opens the descent.
- Relay state remains correct.
- Collapse animation/feedback is readable.
- Save/reload preserves the solved terrain state.
- Existing controls still work.
- Headless CI is green on the final branch tip.

## 13. Explicitly out of scope

The following remain outside v0.2:

- real-world construction/research timers,
- colony or hub management,
- refinery/logistics economy,
- NPC population simulation,
- advanced water/gas/heat/pressure simulation,
- complex procedural cave generation,
- adaptive music system,
- large VFX framework,
- story campaign implementation,
- monetization,
- mobile-specific controls,
- broad accessibility/settings menu work,
- additional biomes.

These systems belong to later versions once the core cave interaction is visually and tactically convincing.

## 14. Non-goals

The v0.2 is not an art-final milestone. It establishes the production direction and proves that the technical simulation can support an appealing game presentation.

Do not sacrifice deterministic gameplay, precision, or testability to imitate a painted concept image literally.

The approved visual target is the principle demonstrated by the Observer and Prepare mockups: organic cavern silhouette in normal play, tactical information revealed contextually in Prepare mode, dark mineral sci-fi atmosphere, cyan ancient technology, and a compact game-like HUD.

## 15. Definition of done

Project Digger v0.2 is done when:

1. the first cave reads as a coherent place rather than a test map,
2. Observer mode is atmospheric and uncluttered,
3. Prepare mode exposes exact tactical information locally,
4. the central collapse remains deterministic and understandable,
5. the resolution has concise audiovisual impact,
6. persistence and the v0.1 gameplay loop remain intact,
7. manual acceptance is complete,
8. the full Godot 4.7.2 headless CI suite passes on the final v0.2 branch tip.
