# Industrial Economy Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development for the three independent implementation units and a whole-branch review. The user approved the attached design; continue without further design approval.

**Goal:** Deliver the 100-recipe economy, six working production buildings, migrated saves and equipment-based progression to 1,500 m.

**Architecture:** Extend the existing deterministic simulation with a data-driven recipe catalogue. Preserve historical visual MINES and add new extraction through a merged catalogue API. Commit job output and equipment costs when starting jobs; validate snapshots and migrate historical schemas explicitly.

**Tech Stack:** Godot 4.7.1 local, GDScript, generated data dictionaries, SceneTree tests.

**Spec:** docs/superpowers/specs/2026-09-12-industrial-economy-design.md and companion recipes.txt.

## Global Constraints

Keep current visual assets and compact portrait HUD. Touch targets >=44 logical px. No main merge or remote push. Preserve versions 1/2 saves, their stocks/depth/jobs and offline production. Use the six approved facilities and exact 100 recipe inputs, durations and yields. Ruling: continue in the current checkout on new dedicated branch, honoring the established session preference; unrelated Godot caches remain unstaged.

## Shared interfaces

Catalogue: `RESOURCES`, `RECIPES` retain old identifiers and labels. Each recipe has `facility`, `inputs`, `output`, `seconds`, `yield`, `depth`, `tier`, `number`, `label`. `FACILITIES` maps IDs to `{label, depth, prefix}`. `MINES` remains the three historical visible mines. `DEEP_MINES` adds raw extraction definitions `{label, base_rate, depth}`. `mine_definitions()->Dictionary` merges them. `GATES` maps transition depth to equipment ingredient dictionaries. `DRILL_UPGRADES` maps current level 1..4 to `{depth,cost}`. `MAX_DEPTH=1500`. Gate equipment amounts default to one of each proposed piece; balancing is subsequent.

Game: `batch_block_reason`, `start_batch`, `mine_rate`, upgrades and other existing APIs remain. Add `excavation_cost()->Dictionary`, `installed_equipment:Dictionary`, `fragment_recovery_block_reason(site_id:String)->String`, `start_fragment_recovery(site_id:String)->bool`, `drill_upgrade_block_reason()->String`. Production uses `mine_definitions`; locked mining returns zero. Session exposes `start_fragment_recovery`. Recovery takes 300 s and yields one fragment per operation, requires an opened active ancient site and depth>=1000, occupies shared recovery slot, and continues offline. These are conservative first-pass values for subsequent balancing.

Equipment paid for a major transition is installed at completion; already installed equipment is omitted from future costs. Drill upgrades install their head permanently and use it again for the corresponding gate. Level upgrades change speed; depth progression is controlled by equipment gates instead of the old automatic level requirement every 30 m. Existing equipment implied by historical depth/level is grandfathered on migration. New snapshots persist installed equipment and committed job outputs/equipment, so interrupted jobs resume correctly.

## Task 1: Catalogue and structural tests

Files: industry_catalog.gd, new industry_recipes.gd, tests/test_economy_catalog.gd.

- [x] Write and run a failing SceneTree test asserting 100 recipes, 6 buildings, multi-output yields, positive durations, valid products/ingredients and DAG accessibility.
- [x] Transcribe the approved recipe table exactly, normalizing abbreviations as approved. Supply metadata, new resource definitions, gated deep minerals and equipment transitions through the shared interfaces.
- [x] Keep existing CENTER_LEVELS keys 1..6 and historical milestones, replace their costs with accessible components and extend to deep zones without changing discovery dictionaries.
- [x] Run the catalogue test and self-review all 100 entries against the input table.

## Task 2: Simulation, recovery and save migration

Files: industry_game.gd, industry_save.gd, industry_session.gd, optional frozen legacy validation scripts, tests/test_economy_simulation.gd.

- [x] Write and observe failures for three batches of copper wire delivering twelve, locked recipe rejection without payment, parallel buildings, equipment gates and no duplicate installation consumption.
- [x] Extend resources/mine levels and atomic job startup/completion using the catalogue APIs. Guarantee raw extraction by zone and ancient structure at 1000. Keep legacy discovery generation deterministic.
- [x] Add recovery startup/completion and persistence; test one completion produces exactly one fragment and segmented/offline advancement match.
- [x] Bump save version to 3, validate versions 1/2 with their historical schemas and then migrate to full stocks/levels/equipment. Preserve already paid jobs and reject malformed snapshots without mutation.
- [x] Test migrated active production/drill jobs, large advances, all gate reachability and round-trip snapshots. Run the new simulation suite.

## Task 3: Production and inventory UI

Files: industry_panel.gd, industry_screen.gd, center_panel.gd, site_panel.gd, optional new inventory/recipe card helper, tests/test_economy_ui.gd.

- [x] Write a failing SceneTree UI test for six facilities, search/filter, yield-aware batch display, inventory quantities and recovery action.
- [x] Replace the hard-coded two-building list with six working cards retaining Furnace/Workshop named controls where possible. Search and accessible filter operate on recipe metadata; preserve selection across per-frame refresh, even when a filter hides all recipes.
- [x] Show all new extraction and inventory resources inside Industry with a dedicated inventory section, leaving the portrait HUD unchanged. Show gate/upgrade equipment costs and recovery actions on actual ancient sites.
- [x] Verify no horizontal overflow at 480/720 and click actions use session APIs. Render surface/Industry/deep captures for inspection.

## Task 4: Integration, regression and review

Files: relevant historical tests, CI workflow, docs/economy-v09.md, artifacts/economy-v09.

- [x] Adapt assertions whose exact stock schema or old progression costs have deliberately changed; preserve malformed-save and production invariants.
- [x] Run existing runner/UI/portrait/render suites plus new catalogue/simulation/UI scripts. Inspect stderr for SCRIPT ERROR/ERROR even when exit code is zero.
- [x] Measure a deterministic crafting/progression route without injecting finished components, and record durations instead of claiming a final balance.
- [x] Independent review of data, save safety and progression; fix important findings and rerun affected tests.
- [x] Commit source/data/tests/docs selectively, leave caches and captures unstaged, deliver verified screenshots and limitations.
