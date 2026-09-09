extends Node2D

@onready var terrain_renderer: TerrainRenderer = $TerrainRenderer
@onready var game_camera: GameCamera = $GameCamera
@onready var game_input: GameInput = $GameInput
@onready var hud: DiggerHUD = $HUD

var model: TerrainModel
var controller: SimulationController
var _layout_data: Dictionary
var _stability := StabilitySystem.new()
var _network := AncientNetwork.new()

func _ready() -> void:
	_layout_data = VerticalSliceLayout.new().build()
	model = _layout_data["model"]
	controller = SimulationController.new(
		model,
		_layout_data["relay_source"],
		_layout_data["relay_pos"],
		6
	)

	terrain_renderer.set_model(model)
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
	game_input.tool_changed.connect(hud.set_tool)
	game_input.selection_changed.connect(terrain_renderer.set_selection)

	hud.prepare_pressed.connect(_on_prepare_requested)
	hud.trigger_pressed.connect(_on_trigger_requested)
	hud.undo_pressed.connect(_on_undo_requested)
	hud.cancel_pressed.connect(_on_cancel_requested)

<<<<<<< Updated upstream
    hud.set_state(controller.state)
    hud.set_energy(controller.cycle_energy)
    hud.set_tool(game_input.active_tool)
    hud.set_relay_connected(controller.relay_connected)
    hud.set_objective_text("Objectif : atteindre la sortie")
=======
	hud.set_state(controller.state)
	hud.set_energy(controller.cycle_energy)
	hud.set_tool(game_input.active_tool)
	hud.set_relay_connected(controller.relay_connected)
	hud.set_objective("atteindre la sortie")
>>>>>>> Stashed changes

func _on_prepare_requested() -> void:
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

func _on_dig_requested(cell: Vector2i) -> void:
	if controller.state == SimulationController.PREPARE and controller.terrain_actions.dig(cell):
		_refresh_prepare_state()

func _on_move_requested(cells: Array[Vector2i], offset: Vector2i) -> void:
	if controller.state == SimulationController.PREPARE and controller.terrain_actions.move(cells, offset):
		_refresh_prepare_state()

func _on_fuse_requested(target: Vector2i, source: Vector2i) -> void:
	if controller.state == SimulationController.PREPARE and controller.terrain_actions.fuse(target, source):
		_refresh_prepare_state()

func _refresh_prepare_state() -> void:
	terrain_renderer.set_analysis(_stability.classify(model))
	terrain_renderer.queue_redraw()
	hud.set_energy(controller.terrain_actions.energy_remaining)
	hud.set_relay_connected(_network.is_relay_connected(model, _layout_data["relay_source"], _layout_data["relay_pos"]))

func _on_state_changed(value: int) -> void:
	hud.set_state(value)
	if value == SimulationController.PREPARE:
		terrain_renderer.set_analysis(_stability.classify(model))
	else:
		terrain_renderer.set_analysis({})

func _on_resolution_finished(movements: Array[Dictionary]) -> void:
	terrain_renderer.queue_redraw()
	terrain_renderer.animate_movements(movements)
	hud.set_relay_connected(controller.relay_connected)

func _clear_selection() -> void:
	var empty: Array[Vector2i] = []
	terrain_renderer.set_selection(empty)
