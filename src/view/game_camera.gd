class_name GameCamera
extends Camera2D

@export var pan_speed := 460.0
@export var min_zoom := 0.6
@export var max_zoom := 2.0
@export var zoom_step := 1.12

var _dragging := false

func set_focus_cell(cell: Vector2i, cell_size: int) -> void:
    var half_cell := float(cell_size) * 0.5
    position = Vector2(
        float(cell.x * cell_size) + half_cell,
        float(cell.y * cell_size) + half_cell
    )

func _process(delta: float) -> void:
    var direction := Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
    if direction != Vector2.ZERO:
        position += direction * pan_speed * delta / maxf(zoom.x, 0.01)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("camera_zoom_in"):
        _set_zoom_level(zoom.x * zoom_step)
        get_viewport().set_input_as_handled()
        return
    if event.is_action_pressed("camera_zoom_out"):
        _set_zoom_level(zoom.x / zoom_step)
        get_viewport().set_input_as_handled()
        return

    if event.is_action_pressed("camera_pan"):
        _dragging = true
        get_viewport().set_input_as_handled()
        return
    if event.is_action_released("camera_pan"):
        _dragging = false
        get_viewport().set_input_as_handled()
        return

    if _dragging and event is InputEventMouseMotion:
        var motion := event as InputEventMouseMotion
        position -= motion.relative / maxf(zoom.x, 0.01)
        get_viewport().set_input_as_handled()

func _set_zoom_level(value: float) -> void:
    var clamped := clampf(value, min_zoom, max_zoom)
    zoom = Vector2(clamped, clamped)
