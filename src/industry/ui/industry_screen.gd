class_name IndustryScreen
extends Control

const Catalog = preload("res://src/industry/industry_catalog.gd")
const Style = preload("res://src/industry/ui/industry_theme.gd")
const MineWorldScript = preload("res://src/industry/ui/mine_world.gd")
const MineSceneRendererScript = preload("res://src/industry/ui/mine_asset_renderer.gd")
const MineInteractionPresenterScript = preload("res://src/industry/ui/mine_interaction_presenter.gd")
const SitePanelScript = preload("res://src/industry/ui/site_panel.gd")
const IndustryPanelScript = preload("res://src/industry/ui/industry_panel.gd")
const CenterPanelScript = preload("res://src/industry/ui/center_panel.gd")
const TechnologyPanelScript = preload("res://src/industry/ui/technology_panel.gd")

const HUD_RESOURCE_LABELS := {
    "iron": "Fer",
    "coal": "Charbon",
    "copper": "Cuivre",
    "iron_ingot": "Lingot Fe",
    "copper_ingot": "Lingot Cu",
    "cable": "Câble",
    "crystal": "Cristal",
}

var session
var _wallet: Dictionary = {}
var _compact_hud: GridContainer
var _capacity: Label
var _content_host: VBoxContainer
var _mine_panel: Control
var _mine_stage: Control
var _mine_world
var _mine_renderer
var _interaction_presenter
var _overlay_layer: Control
var _alert_stack: VBoxContainer
var _site_panel
var _milestone_buttons: Dictionary = {}
var _industry_panel
var _center_panel
var _technology_panel
var _depth: Label
var _event_banner: PanelContainer
var _event_label: Label
var _event_view: Button
var _offline_card: PanelContainer
var _offline: Label
var _offline_dismissed := false
var _save_notice: Label
var _save_status: Label
var _tabs: Dictionary = {}
var _bottom_navigation: HBoxContainer
var _current_view := "mine"

func _ready() -> void:
    session = get_node("IndustrySession")
    theme = Style.create()
    _build()
    session.changed.connect(_refresh)
    session.notice_changed.connect(_refresh_notices)
    resized.connect(_responsive)
    _select_view("mine")
    _responsive()
    _refresh()
    _refresh_notices()

func _build() -> void:
    var background := ColorRect.new()
    background.color = Style.BACKGROUND
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background)
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var outer := MarginContainer.new()
    outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    outer.add_theme_constant_override("margin_left", 12)
    outer.add_theme_constant_override("margin_right", 12)
    outer.add_theme_constant_override("margin_top", 10)
    outer.add_theme_constant_override("margin_bottom", 10)
    add_child(outer)

    var shell := VBoxContainer.new()
    shell.name = "IndustryShell"
    shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
    shell.add_theme_constant_override("separation", 6)
    outer.add_child(shell)

    _build_compact_hud(shell)

    _save_notice = _label(shell, "", 12, Style.COPPER)
    _save_notice.name = "SaveNotice"

    var scroll := ScrollContainer.new()
    scroll.name = "PageScroll"
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    shell.add_child(scroll)

    var content_margin := MarginContainer.new()
    content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content_margin.add_theme_constant_override("margin_right", 4)
    scroll.add_child(content_margin)

    _content_host = VBoxContainer.new()
    _content_host.name = "ContentHost"
    _content_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _content_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content_margin.add_child(_content_host)

    _build_mine_panel()

    _industry_panel = IndustryPanelScript.new()
    _content_host.add_child(_industry_panel)
    _industry_panel.bind_session(session)

    _center_panel = CenterPanelScript.new()
    _content_host.add_child(_center_panel)
    _center_panel.bind_session(session)

    _technology_panel = TechnologyPanelScript.new()
    _content_host.add_child(_technology_panel)
    _technology_panel.bind_session(session)

    _save_status = _label(shell, "", 10, Style.MUTED)
    _save_status.name = "SaveStatus"

    _bottom_navigation = HBoxContainer.new()
    _bottom_navigation.name = "BottomNavigation"
    _bottom_navigation.custom_minimum_size.y = 44
    _bottom_navigation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _bottom_navigation.add_theme_constant_override("separation", 8)
    shell.add_child(_bottom_navigation)
    _add_tab(_bottom_navigation, "Mine", "TabMine", "mine")
    _add_tab(_bottom_navigation, "Industrie", "TabIndustrie", "industry")
    _add_tab(_bottom_navigation, "Centre", "TabCentre", "center")
    _add_tab(_bottom_navigation, "Technologie", "TabTechnologie", "technology")

func _build_compact_hud(parent: Node) -> void:
    _compact_hud = GridContainer.new()
    _compact_hud.name = "CompactHUD"
    _compact_hud.columns = 10
    _compact_hud.custom_minimum_size.y = 40
    _compact_hud.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _compact_hud.add_theme_constant_override("h_separation", 5)
    _compact_hud.add_theme_constant_override("v_separation", 4)
    parent.add_child(_compact_hud)

    var title_chip := _hud_panel(_compact_hud, 86)
    var title := _label(title_chip, "DIGGER", 16, Style.TEXT)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

    for id in Catalog.RESOURCES:
        var chip := _hud_panel(_compact_hud, 84)
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 4)
        chip.add_child(row)
        var short_label := str(HUD_RESOURCE_LABELS.get(id, Catalog.RESOURCES[id]["label"]))
        var caption := _label(row, short_label, 10, Style.MUTED)
        caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var number := _label(row, "0", 15, Style.ACCENT if Catalog.RESOURCES[id]["raw"] else Style.COPPER)
        number.name = "Stock_" + id
        number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        _wallet[id] = number

    var capacity_chip := _hud_panel(_compact_hud, 108)
    _capacity = _label(capacity_chip, "Capacité 0/0", 11, Style.MUTED)
    _capacity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _capacity.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

    var depth_chip := _hud_panel(_compact_hud, 82)
    _depth = _label(depth_chip, "−0 m", 18, Style.COPPER)
    _depth.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _depth.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _hud_panel(parent: Node, min_width: float) -> PanelContainer:
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(min_width, 36)
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.add_theme_stylebox_override("panel", Style.panel(Color("111d29"), Color("283d4b"), 5))
    parent.add_child(panel)
    return panel

func _build_mine_panel() -> void:
    _mine_panel = Control.new()
    _mine_panel.name = "MinePanel"
    _mine_panel.custom_minimum_size = Vector2(0, 540)
    _mine_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _mine_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _content_host.add_child(_mine_panel)

    _mine_stage = Control.new()
    _mine_stage.name = "MineStage"
    _mine_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _mine_panel.add_child(_mine_stage)
    _mine_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var world_card := PanelContainer.new()
    world_card.name = "MineWorldCard"
    world_card.mouse_filter = Control.MOUSE_FILTER_PASS
    world_card.add_theme_stylebox_override("panel", Style.panel(Color("0a131c"), Color("2d4553"), 4))
    _mine_stage.add_child(world_card)
    world_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    _mine_world = MineWorldScript.new()
    world_card.add_child(_mine_world)
    _mine_world.bind_session(session)
    _mine_world.selection_changed.connect(_on_world_selection)

    _mine_renderer = MineSceneRendererScript.new()
    _mine_world.add_child(_mine_renderer)
    _mine_world.move_child(_mine_renderer, 0)
    _mine_renderer.bind(session, _mine_world)

    _interaction_presenter = MineInteractionPresenterScript.new()
    _mine_world.add_child(_interaction_presenter)
    _interaction_presenter.bind(_mine_world)
    _overlay_layer = Control.new()
    _overlay_layer.name = "MineOverlayLayer"
    _overlay_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _mine_stage.add_child(_overlay_layer)
    _overlay_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    _build_camera_shortcuts(_overlay_layer)
    _build_alert_stack(_overlay_layer)

    _site_panel = SitePanelScript.new()
    _overlay_layer.add_child(_site_panel)

func _build_camera_shortcuts(parent: Control) -> void:
    var shortcut_panel := PanelContainer.new()
    shortcut_panel.name = "MineShortcutPanel"
    shortcut_panel.position = Vector2(12, 12)
    shortcut_panel.mouse_filter = Control.MOUSE_FILTER_STOP
    shortcut_panel.add_theme_stylebox_override("panel", Style.panel(Color("0f1b25d8"), Color("4a6572"), 5))
    parent.add_child(shortcut_panel)

    var camera_row := HFlowContainer.new()
    camera_row.name = "MineCameraShortcuts"
    camera_row.custom_minimum_size = Vector2(520, 36)
    camera_row.add_theme_constant_override("h_separation", 5)
    camera_row.add_theme_constant_override("v_separation", 4)
    shortcut_panel.add_child(camera_row)

    var surface := _compact_button(camera_row, "Surface", "FocusSurface")
    surface.pressed.connect(_focus_depth.bind(0))
    var drill_focus := _compact_button(camera_row, "Foreuse", "FocusDrill")
    drill_focus.pressed.connect(_focus_drill)
    for milestone in [30, 60, 90, 120, 150]:
        var focus := _compact_button(camera_row, "%d m" % milestone, "Focus%d" % milestone)
        focus.pressed.connect(_focus_depth.bind(milestone))
        _milestone_buttons[milestone] = focus

func _build_alert_stack(parent: Control) -> void:
    _alert_stack = VBoxContainer.new()
    _alert_stack.name = "MineAlertStack"
    _alert_stack.position = Vector2(12, 58)
    _alert_stack.custom_minimum_size.x = 440
    _alert_stack.mouse_filter = Control.MOUSE_FILTER_PASS
    _alert_stack.add_theme_constant_override("separation", 6)
    parent.add_child(_alert_stack)
    _build_event_banner(_alert_stack)
    _build_offline_card(_alert_stack)

func _build_event_banner(parent: Node) -> void:
    _event_banner = PanelContainer.new()
    _event_banner.name = "PendingEventBanner"
    _event_banner.visible = false
    _event_banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _event_banner.add_theme_stylebox_override("panel", Style.panel(Color("261f1ae8"), Style.COPPER, 7))
    parent.add_child(_event_banner)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 8)
    _event_banner.add_child(row)
    _event_label = _label(row, "", 12, Style.COPPER)
    _event_view = _compact_button(row, "VOIR", "PendingEventView")
    _event_view.custom_minimum_size.x = 84
    _event_view.pressed.connect(_open_event)

func _build_offline_card(parent: Node) -> void:
    _offline_card = PanelContainer.new()
    _offline_card.name = "OfflineCard"
    _offline_card.visible = false
    _offline_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _offline_card.add_theme_stylebox_override("panel", Style.panel(Color("102b2ee8"), Style.ACCENT, 7))
    parent.add_child(_offline_card)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 8)
    _offline_card.add_child(row)
    _offline = _label(row, "", 12, Style.ACCENT)
    _offline.name = "OfflineNotice"
    var close := _compact_button(row, "×", "OfflineClose")
    close.custom_minimum_size = Vector2(32, 32)
    close.pressed.connect(_dismiss_offline)

func _add_tab(parent: Node, title: String, node_name: String, view_id: String) -> void:
    var button := _button(parent, title, node_name)
    button.custom_minimum_size.y = 40
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.pressed.connect(_select_view.bind(view_id))
    _tabs[view_id] = button

func _select_view(view_id: String) -> void:
    if view_id not in ["mine", "industry", "center", "technology"]:
        return
    _current_view = view_id
    _mine_panel.visible = view_id == "mine"
    _industry_panel.visible = view_id == "industry"
    _center_panel.visible = view_id == "center"
    _technology_panel.visible = view_id == "technology"
    for id in _tabs:
        _tabs[id].disabled = id == view_id
    if view_id == "mine":
        _mine_world.refresh()
    elif view_id == "industry":
        _industry_panel.refresh()
    elif view_id == "center":
        _center_panel.refresh()
    elif view_id == "technology":
        _technology_panel.refresh()

func _refresh() -> void:
    if session == null:
        return
    var game = session.game
    _depth.text = "−%d m" % game.depth
    _capacity.text = "Capacité %d/%d" % [game.used_capacity(), game.total_capacity()]
    for id in _wallet:
        _wallet[id].text = str(floori(game.resources[id]))
    _refresh_milestone_buttons()
    _mine_world.refresh()
    if _site_panel.visible:
        _site_panel.refresh()
    _industry_panel.refresh()
    _center_panel.refresh()
    _technology_panel.refresh()
    _refresh_event_banner()
    _refresh_offline_card()

func _refresh_milestone_buttons() -> void:
    for milestone in _milestone_buttons:
        _milestone_buttons[milestone].visible = session.game.depth >= int(milestone)

func _refresh_event_banner() -> void:
    if _event_banner == null:
        return
    var game = session.game
    if not game.active_event.is_empty():
        _event_banner.visible = true
        var resource_id := str(game.active_event.get("resource", ""))
        if resource_id == "":
            _event_label.text = "Filon instable détecté — choisir une priorité"
            _event_view.text = "CHOISIR"
        else:
            var label := str(Catalog.RESOURCES[resource_id]["label"])
            _event_label.text = "Filon instable · %s · %s" % [label, _duration(float(game.active_event.get("remaining", 0.0)))]
            _event_view.text = "DÉTAILS"
        return
    if not game.pending_events.is_empty():
        _event_banner.visible = true
        _event_label.text = "Filon instable détecté — choisir une priorité"
        _event_view.text = "VOIR"
        return
    _event_banner.visible = false

func _open_event() -> void:
    if session.game.active_event.is_empty():
        if not session.present_pending_event():
            return
    _select_view("mine")
    _site_panel.show_event(session)
    _refresh_event_banner()

func _on_world_selection(kind: String, id: String) -> void:
    _site_panel.show_selection(kind, id, session)

func _focus_depth(target_depth: int) -> void:
    _mine_world.focus_depth(target_depth)

func _focus_drill() -> void:
    _mine_world.focus_depth(session.game.depth)

func _dismiss_offline() -> void:
    _offline_dismissed = true
    if _offline_card != null:
        _offline_card.visible = false
    if _offline != null:
        _offline.visible = false

func _refresh_notices() -> void:
    _save_notice.visible = session.save_blocked or session.save_error != ""
    if session.save_blocked:
        _save_notice.text = "Sauvegarde : %s · fichier d'origine préservé · session provisoire non enregistrée." % session.save_error
        _save_status.text = "Enregistrement désactivé · Session provisoire."
    elif session.save_error != "":
        _save_notice.text = "Sauvegarde : %s · nouvelle tentative automatique." % session.save_error
        _save_status.text = "Enregistrement en attente · Nouvelle tentative automatique."
    else:
        _save_notice.text = ""
        _save_status.text = "Progression enregistrée automatiquement · Les mines restent actives pendant ton absence."
    _refresh_offline_card()

func _refresh_offline_card() -> void:
    if _offline_card == null or _offline == null:
        return
    var should_show: bool = session.offline_seconds >= 5.0 and not _offline_dismissed
    _offline_card.visible = should_show
    _offline.visible = should_show
    if not should_show:
        return
    var report: Dictionary = session.offline_report
    var completed: Array = report.get("completed", [])
    var pending_count: int = int(session.game.pending_events.size())
    var event_text := "%d événement%s" % [pending_count, "s" if pending_count != 1 else ""]
    _offline.text = "Retour · %s · %s · %d travaux · +%d m · %s" % [
        _duration(session.offline_seconds),
        _cost(report.get("produced", {})),
        completed.size(),
        report.get("depth_gained", 0),
        event_text,
    ]

func _responsive() -> void:
    if _compact_hud == null:
        return
    var narrow := size.x < 900
    var portrait := size.y > size.x
    _compact_hud.columns = 5 if narrow else 10
    if _mine_panel != null:
        _mine_panel.custom_minimum_size.y = 860.0 if portrait else 540.0
    if _bottom_navigation != null:
        _bottom_navigation.custom_minimum_size.y = 52.0 if portrait else 44.0
    for tab in _tabs.values():
        var tab_button := tab as Button
        tab_button.custom_minimum_size.y = 48.0 if portrait else 40.0
    if _site_panel != null:
        _site_panel.set_layout_mode("bottom_sheet" if narrow else "floating_right")
    if _alert_stack != null:
        _alert_stack.custom_minimum_size.x = 0 if narrow else 440
        _alert_stack.size.x = minf(440.0, maxf(300.0, size.x - 72.0))
    if _industry_panel != null:
        _industry_panel._responsive()

func _cost(cost: Dictionary, multiplier: int = 1) -> String:
    var parts := PackedStringArray()
    for id in cost:
        parts.append("%d %s" % [floori(float(cost[id]) * multiplier), Catalog.RESOURCES[id]["label"]])
    return " · ".join(parts) if not parts.is_empty() else "Aucune ressource"

func _duration(seconds: float) -> String:
    var rounded := ceili(seconds)
    if rounded >= 3600:
        return "%d h %02d min" % [rounded / 3600, (rounded % 3600) / 60]
    if rounded >= 60:
        return "%d min %02d s" % [rounded / 60, rounded % 60]
    return "%d s" % rounded

func _card(parent: Node, padding: int = 16) -> VBoxContainer:
    var panel := PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.add_theme_stylebox_override("panel", Style.panel(Style.PANEL, Color("294052"), padding))
    parent.add_child(panel)
    var content := VBoxContainer.new()
    panel.add_child(content)
    return content

func _label(parent: Node, value: String, font_size: int = 16, color: Color = Style.TEXT) -> Label:
    var label := Label.new()
    label.text = value
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(label)
    return label

func _button(parent: Node, title: String, node_name: String) -> Button:
    var button := Button.new()
    button.name = node_name
    button.text = title
    button.custom_minimum_size.y = 40
    parent.add_child(button)
    return button

func _compact_button(parent: Node, title: String, node_name: String) -> Button:
    var button := Button.new()
    button.name = node_name
    button.text = title
    button.custom_minimum_size = Vector2(62, 32)
    button.add_theme_font_size_override("font_size", 12)
    parent.add_child(button)
    return button