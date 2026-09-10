extends Node2D

const VisualProfile := preload("res://src/view/terrain_visual_profile.gd")

@onready var cave_backdrop = $CaveBackdrop
@onready var terrain_renderer: TerrainRenderer = $TerrainRenderer
@onready var ancient_overlay = $AncientOverlay
@onready var game_camera: GameCamera = $GameCamera
@onready var game_input: GameInput = $GameInput
@onready var hud: DiggerHUD = $HUD

var model: TerrainModel
var controller: SimulationController
var _layout_data: Dictionary
var _stability := StabilitySystem.new()
var _network := AncientNetwork.new()
var _save_system := SaveSystem.new()
var _catalog := MaterialCatalog.new()
var _objective_reached := false
var _last_hovered_cell := Vector2i.ZERO
var _has_hovered_cell := false

func _ready() -> void:
	_layout_data = VerticalSliceLayout.new().build()
	model = _layout_data["model"]

	var saved := _save_system.load_default_for_content(VerticalSliceLayout.CONTENT_ID)
	if not saved.is_empty():
		model.restore(saved["terrain"])
		_objective_reached = bool(saved.get("objective_reached", false))

	controller = SimulationController.new(
		model,
		_layout_data["relay_source"],
		_layout_data["relay_pos"],
		6
	)

	cave_backdrop.configure(Vector2i(model.width, model.height), TerrainRenderer.CELL_SIZE)
	terrain_renderer.set_model(model)
	ancient_overlay.configure(_layout_data["ancient_path"], _layout_data["relay_pos"], TerrainRenderer.CELL_SIZE)
	ancient_overlay.set_connected(controller.relay_connected)
	game_camera.set_focus_cell(_layout_data["spawn_focus"], TerrainRenderer.CELL_SIZE)
	game_input.configure(terrain_renderer)

	controller.state_changed.connect(_on_state_changed)
	controller.energy_changed.connect(hud.set_energy)
	controller.resolution_finished.connect(_on_resolution_finished)

	game_input.dig_requested.connect(_on_dig_requested)
	game_input.move_requested.connect(_on_move_requested)
	game_input.fuse_requested.connect(_on_fuse_requested)
	game_input.prepare_requested.connect(_on_prepare_requested)
	game_input.trigger_requested.connect(_on_trigger_requested)
	game_input.undo_requested.connect(_on_undo_requested)
	game_input.cancel_requested.connect(_on_cancel_requested)
	game_input.tool_changed.connect(_on_tool_changed)
	game_input.selection_changed.connect(terrain_renderer.set_selection)
	game_input.hover_changed.connect(_on_hover_changed)

	hud.prepare_pressed.connect(_on_prepare_requested)
	hud.trigger_pressed.connect(_on_trigger_requested)
	hud.undo_pressed.connect(_on_undo_requested)
	hud.cancel_pressed.connect(_on_cancel_requested)
	hud.tool_pressed.connect(game_input.set_active_tool)

	_objective_reached = _objective_reached or _is_exit_open()
	_refresh_hud()

	if int(saved.get("cycle_state", SimulationController.OBSERVER)) == SimulationController.PREPARE and not _objective_reached:
		controller.enter_prepare()
		_refresh_prepare_state()

func _on_prepare_requested() -> void:
	if _objective_reached:
		return
	if controller.enter_prepare():
		_refresh_prepare_state()

func _on_trigger_requested() -> void:
	if controller.trigger_resolution():
		_clear_selection()

func _on_undo_requested() -> void:
	if controller.state == SimulationController.PREPARE and controller.terrain_actions.undo():
		_refresh_prepare_state()

func _on_cancel_requested() -> void:
	if controller.cancel_prepare():
		_clear_selection()
		terrain_renderer.queue_redraw()
		hud.set_relay_connected(controller.relay_connected)
		ancient_overlay.set_connected(controller.relay_connected)

func _on_dig_requested(cell: Vector2i) -> void:
	if controller.state == SimulationController.PREPARE and controller.terrain_actions.dig(cell):
		_refresh_prepare_state()

func _on_move_requested(cells: Array[Vector2i], offset: Vector2i) -> void:
	if controller.state == SimulationController.PREPARE and controller.terrain_actions.move(cells, offset):
		_refresh_prepare_state()

func _on_fuse_requested(target: Vector2i, source: Vector2i) -> void:
	if controller.state == SimulationController.PREPARE and controller.terrain_actions.fuse(target, source):
		_refresh_prepare_state()

func _on_tool_changed(tool: StringName) -> void:
	hud.set_tool(tool)
	_refresh_hover_context()

func _on_hover_changed(cell: Vector2i) -> void:
	if cell.x < 0 or cell.y < 0 or cell.x >= model.width or cell.y >= model.height:
		_has_hovered_cell = false
		terrain_renderer.clear_hovered_cell()
		hud.clear_context()
		return

	_last_hovered_cell = cell
	_has_hovered_cell = true
	terrain_renderer.set_hovered_cell(cell)
	_refresh_hover_context()

func _refresh_hover_context() -> void:
	if not _has_hovered_cell or controller.state != SimulationController.PREPARE:
		hud.clear_context()
		return

	var terrain_cell := model.get_cell(_last_hovered_cell)
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

	hud.set_context(VisualProfile.display_name(terrain_cell.material_id), action_name, cost, actionable)

func _refresh_prepare_state() -> void:
	terrain_renderer.set_analysis(_stability.classify(model))
	terrain_renderer.queue_redraw()
	hud.set_energy(controller.terrain_actions.energy_remaining)
	var relay_connected := _network.is_relay_connected(model, _layout_data["relay_source"], _layout_data["relay_pos"])
	hud.set_relay_connected(relay_connected)
	ancient_overlay.set_connected(relay_connected)
	_refresh_hover_context()

func _on_state_changed(value: int) -> void:
	hud.set_state(value)
	terrain_renderer.set_prepare_mode(value == SimulationController.PREPARE)
	if value == SimulationController.PREPARE:
		terrain_renderer.set_analysis(_stability.classify(model))
		_refresh_hover_context()
	else:
		terrain_renderer.set_analysis({})
		hud.clear_context()

func _on_resolution_finished(movements: Array[Dictionary]) -> void:
	terrain_renderer.queue_redraw()
	terrain_renderer.animate_movements(movements)
	hud.set_relay_connected(controller.relay_connected)
	ancient_overlay.set_connected(controller.relay_connected)

	if _is_exit_open():
		_objective_reached = true
	_refresh_hud()
	_autosave()

func _refresh_hud() -> void:
	hud.set_state(controller.state)
	hud.set_energy(controller.cycle_energy)
	hud.set_tool(game_input.active_tool)
	hud.set_relay_connected(controller.relay_connected)
	ancient_overlay.set_connected(controller.relay_connected)
	terrain_renderer.set_prepare_mode(controller.state == SimulationController.PREPARE)
	if _objective_reached:
		hud.set_objective_text("Accès aux profondeurs ouvert — Vertical slice terminé")
	else:
		hud.set_objective_text("Objectif : ouvrir la descente")

func _is_exit_open() -> bool:
	var exit_rect: Rect2i = _layout_data["exit_rect"]
	var corridor_x: int = exit_rect.position.x + int(exit_rect.size.x / 2)
	for y in range(VerticalSliceLayout.GATE_POS.y, exit_rect.end.y):
		if model.get_cell(Vector2i(corridor_x, y)) != null:
			return false
	return true

func _autosave() -> void:
	var saved := _save_system.save_default(model, {
		"relay_connected": controller.relay_connected,
		"cycle_state": controller.state,
		"objective_reached": _objective_reached,
		"content_id": VerticalSliceLayout.CONTENT_ID,
	})
	if not saved:
		push_error("Project Digger: autosave failed")

func _clear_selection() -> void:
	var empty: Array[Vector2i] = []
	terrain_renderer.set_selection(empty)
