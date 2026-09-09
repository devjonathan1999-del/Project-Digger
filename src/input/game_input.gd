class_name GameInput
extends Node

signal dig_requested(cell: Vector2i)
signal move_requested(cells: Array[Vector2i], offset: Vector2i)
signal fuse_requested(target: Vector2i, source: Vector2i)
signal prepare_requested
signal trigger_requested
signal undo_requested
signal cancel_requested
signal tool_changed(tool: StringName)
signal selection_changed(cells: Array[Vector2i])

var active_tool: StringName = &"dig"
var _renderer: TerrainRenderer
var _move_source := Vector2i.ZERO
var _has_move_source := false
var _fuse_source := Vector2i.ZERO
var _has_fuse_source := false

func configure(renderer: TerrainRenderer) -> void:
    _renderer = renderer

func set_active_tool(tool: StringName) -> void:
    if tool != &"dig" and tool != &"move" and tool != &"fuse":
        return
    active_tool = tool
    _clear_selection()
    tool_changed.emit(active_tool)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("tool_dig"):
        set_active_tool(&"dig")
        return
    if event.is_action_pressed("tool_move"):
        set_active_tool(&"move")
        return
    if event.is_action_pressed("tool_fuse"):
        set_active_tool(&"fuse")
        return

    if event.is_action_pressed("prepare_action"):
        prepare_requested.emit()
        return
    if event.is_action_pressed("trigger_action"):
        trigger_requested.emit()
        return
    if event.is_action_pressed("undo_action"):
        undo_requested.emit()
        return
    if event.is_action_pressed("cancel_action"):
        _clear_selection()
        cancel_requested.emit()
        return

    if not event.is_action_pressed("primary_action") or not event is InputEventMouseButton or _renderer == null:
        return

    var cell := _renderer.cell_from_screen(event.position)
    match active_tool:
        &"dig":
            dig_requested.emit(cell)
        &"move":
            _handle_move_click(cell)
        &"fuse":
            _handle_fuse_click(cell)

func _handle_move_click(cell: Vector2i) -> void:
    if not _has_move_source:
        _move_source = cell
        _has_move_source = true
        var selection: Array[Vector2i] = [cell]
        selection_changed.emit(selection)
        return
    var offset := cell - _move_source
    var cells: Array[Vector2i] = [_move_source]
    _has_move_source = false
    _emit_empty_selection()
    if offset != Vector2i.ZERO:
        move_requested.emit(cells, offset)

func _handle_fuse_click(cell: Vector2i) -> void:
    if not _has_fuse_source:
        _fuse_source = cell
        _has_fuse_source = true
        var selection: Array[Vector2i] = [cell]
        selection_changed.emit(selection)
        return
    var source := _fuse_source
    _has_fuse_source = false
    _emit_empty_selection()
    if cell != source:
        fuse_requested.emit(cell, source)

func _clear_selection() -> void:
    _has_move_source = false
    _has_fuse_source = false
    _emit_empty_selection()

func _emit_empty_selection() -> void:
    var empty: Array[Vector2i] = []
    selection_changed.emit(empty)
