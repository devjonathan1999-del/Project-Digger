class_name SimulationController
extends RefCounted

signal state_changed(state: int)
signal resolution_finished(movements: Array[Dictionary])
signal energy_changed(value: int)

enum { OBSERVER, PREPARE, RESOLVING }

var state := OBSERVER
var cycle_energy: int
var relay_connected := false
var terrain_actions := TerrainActions.new()

var _model: TerrainModel
var _source: Vector2i
var _relay: Vector2i
var _stability := StabilitySystem.new()
var _network := AncientNetwork.new()

func _init(
    model: TerrainModel = null,
    source: Vector2i = Vector2i.ZERO,
    relay: Vector2i = Vector2i.ZERO,
    p_cycle_energy: int = 6
) -> void:
    _model = model
    _source = source
    _relay = relay
    cycle_energy = maxi(0, p_cycle_energy)
    if _model != null:
        relay_connected = _network.is_relay_connected(_model, _source, _relay)

func enter_prepare() -> bool:
    if state != OBSERVER or _model == null:
        return false
    terrain_actions.begin_prepare(_model, cycle_energy)
    _set_state(PREPARE)
    energy_changed.emit(terrain_actions.energy_remaining)
    return true

func trigger_resolution() -> bool:
    if state != PREPARE or _model == null:
        return false

    terrain_actions.commit()
    energy_changed.emit(terrain_actions.energy_remaining)
    _set_state(RESOLVING)
    var movements := _stability.resolve(_model)
    relay_connected = _network.is_relay_connected(_model, _source, _relay)
    resolution_finished.emit(movements)
    _set_state(OBSERVER)
    return true

func cancel_prepare() -> bool:
    if state != PREPARE:
        return false
    terrain_actions.cancel()
    energy_changed.emit(terrain_actions.energy_remaining)
    _set_state(OBSERVER)
    return true

func _set_state(next_state: int) -> void:
    state = next_state
    state_changed.emit(state)
