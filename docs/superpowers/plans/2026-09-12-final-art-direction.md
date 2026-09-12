# Final Art Direction Implementation Plan
> For agentic workers: use superpowers:subagent-driven-development for independent UI task and final review.
**Goal:** Implement the approved concept as layered dynamic Godot gameplay visuals.
**Architecture:** Keep MineAssetRenderer public geometry/state APIs and legacy desktop metrics. Add a dedicated portrait painter and raster atlas loader; renderer delegates portrait drawing while presenter maps existing buttons to the same chamber geometry. IndustryTheme and IndustryScreen polish controls independently.
**Tech Stack:** Godot GDScript, generated PNG raster assets, cached ImageTexture.
**Spec:** docs/superpowers/specs/2026-09-12-final-art-direction.md
## Global Constraints
Gameplay/save schema unchanged. Portrait720×1280, touch>=44. No main merge. Preserve old assets.
## Task1: Layered visual assets and dynamic painter
Files: assets/industry/final/*.png; src/industry/ui/mine_final_assets.gd; src/industry/ui/mine_portrait_painter.gd; mine_asset_renderer.gd; mine_interaction_presenter.gd; tests/test_final_art_direction.gd.
Interfaces: loader.texture_for(id:String)->Texture2D. Painter.draw_scene(host:Control,state:Dictionary,resource_rects:Dictionary)->void. Existing _resource_v07_rects remains authoritative for input. AssetRenderer _draw delegates narrow only.
- [x] Generate surface panorama, seamless rock, transparent chamber atlas and drill/elevator sprites from approved reference.
- [x] Test asset availability and real screen selection after camera move, geometry outside shaft, zoom alignment and no game-state mutation.
- [x] Implement painter ordered rock/surface/shaft/connections/chambers/drill/ruler, dynamic positions from world transform; preserve resource availability.
- [x] Run portrait+new art-direction test and inspect rendered surface/deep captures; fix regressions.
## Task2: Interface polish (independent worker)
Files: industry_theme.gd; industry_screen.gd; optional resource icon helper.
Interfaces: preserve named HUD nodes, buttons, signals, panel APIs and renderer preload.
- [x] Refine slate/brass theme, compact legible HUD, resource pictograms, amber selected tab, navigation icons, contextual panels.
- [x] Verify portrait and UI tests, avoid horizontal overflow and preserve hitbox sizes.
## Task3: Integrate and verify
Files: docs/final-art-direction.md; tests and artifacts.
- [x] Independent code review of state/geometry/input/save safety; resolve findings.
- [x] Run18 SceneTree scripts, rendered portrait and actual native click; inspect720/480 and150m focus90.
- [x] Record honest comparison to concept and deliver actual Godot captures on feature branch.
