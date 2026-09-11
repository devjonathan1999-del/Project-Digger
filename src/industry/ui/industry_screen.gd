class_name IndustryScreen
extends Control

const Catalog = preload("res://src/industry/industry_catalog.gd")
const Style = preload("res://src/industry/ui/industry_theme.gd")
const MineWorldScript = preload("res://src/industry/ui/mine_world.gd")
const SitePanelScript = preload("res://src/industry/ui/site_panel.gd")
const IndustryPanelScript = preload("res://src/industry/ui/industry_panel.gd")
const CenterPanelScript = preload("res://src/industry/ui/center_panel.gd")
const TechnologyPanelScript = preload("res://src/industry/ui/technology_panel.gd")

var session
var _wallet: Dictionary = {}
var _wallet_grid: GridContainer
var _content_host: VBoxContainer
var _mine_panel: VBoxContainer
var _mine_layout: BoxContainer
var _mine_world
var _site_panel
var _milestone_buttons: Dictionary = {}
var _industry_panel
var _center_panel
var _technology_panel
var _depth: Label
var _drill_info: Label
var _drill_cost: Label
var _drill_upgrade: Button
var _dig: Button
var _dig_info: Label
var _dig_progress: ProgressBar
var _event_banner: PanelContainer
var _event_label: Label
var _event_view: Button
var _offline_card: PanelContainer
var _offline: Label
var _offline_dismissed := false
var _save_notice: Label
var _save_status: Label
var _tabs: Dictionary = {}
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
    for side in ["left", "right", "top", "bottom"]:
        outer.add_theme_constant_override("margin_" + side, 16)
    add_child(outer)

    var shell := VBoxContainer.new()
    shell.name = "IndustryShell"
    shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
    shell.add_theme_constant_override("separation", 10)
    outer.add_child(shell)

    var header := HBoxContainer.new()
    shell.add_child(header)
    var title := VBoxContainer.new()
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_constant_override("separation", 1)
    header.add_child(title)
    _label(title, "D I G G E R  /  INDUSTRIES", 22)
    _label(title, "Progression verticale", 13, Style.MUTED)
    _depth = _label(header, "", 27, Style.COPPER)

    _wallet_grid = GridContainer.new()
    _wallet_grid.name = "WalletGrid"
    shell.add_child(_wallet_grid)
    for id in Catalog.RESOURCES:
        var box := _card(_wallet_grid, 8)
        _label(box, Catalog.RESOURCES[id]["label"], 12, Style.MUTED)
        var number := _label(box, "0", 19, Style.ACCENT if Catalog.RESOURCES[id]["raw"] else Style.COPPER)
        number.name = "Stock_" + id
        _wallet[id] = number

    _build_event_banner(shell)
    _build_offline_card(shell)

    _save_notice = _label(shell, "", 14, Style.COPPER)
    _save_notice.name = "SaveNotice"

    var scroll := ScrollContainer.new()
    scroll.name = "PageScroll"
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    shell.add_child(scroll)
    var content_margin := MarginContainer.new()
    content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content_margin.add_theme_constant_override("margin_right", 8)
    scroll.add_child(content_margin)
    _content_host = VBoxContainer.new()
    _content_host.name = "ContentHost"
    _content_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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

    _save_status = _label(shell, "", 12, Style.MUTED)
    _save_status.name = "SaveStatus"

    var nav := HBoxContainer.new()
    nav.name = "BottomNavigation"
    nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    shell.add_child(nav)
    _add_tab(nav, "Mine", "TabMine", "mine")
    _add_tab(nav, "Industrie", "TabIndustrie", "industry")
    _add_tab(nav, "Centre", "TabCentre", "center")
    _add_tab(nav, "Technologie", "TabTechnologie", "technology")

func _build_event_banner(parent: Node) -> void:
    _event_banner = PanelContainer.new()
    _event_banner.name = "PendingEventBanner"
    _event_banner.visible = false
    _event_banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _event_banner.add_theme_stylebox_override("panel", Style.panel(Color("1d2b32"), Style.COPPER, 10))
    parent.add_child(_event_banner)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 10)
    _event_banner.add_child(row)
    _event_label = _label(row, "", 14, Style.COPPER)
    _event_view = _button(row, "VOIR", "PendingEventView")
    _event_view.custom_minimum_size.x = 100
    _event_view.pressed.connect(_open_event)

func _build_offline_card(parent: Node) -> void:
    _offline_card = PanelContainer.new()
    _offline_card.name = "OfflineCard"
    _offline_card.visible = false
    _offline_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _offline_card.add_theme_stylebox_override("panel", Style.panel(Color("102c30"), Style.ACCENT, 10))
    parent.add_child(_offline_card)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 10)
    _offline_card.add_child(row)
    _offline = _label(row, "", 14, Style.ACCENT)
    _offline.name = "OfflineNotice"
    var close := _button(row, "×", "OfflineClose")
    close.custom_minimum_size = Vector2(40, 40)
    close.pressed.connect(_dismiss_offline)

func _build_mine_panel() -> void:
    _mine_panel = VBoxContainer.new()
    _mine_panel.name = "MinePanel"
    _mine_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _mine_panel.add_theme_constant_override("separation", 12)
    _content_host.add_child(_mine_panel)
    _label(_mine_panel, "MINE", 22)
    _label(_mine_panel, "Fais glisser la coupe verticale, sélectionne un élément et ouvre de nouveaux horizons.", 14, Style.MUTED)

    var camera_row := HBoxContainer.new()
    camera_row.name = "MineCameraShortcuts"
    camera_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _mine_panel.add_child(camera_row)
    var surface := _button(camera_row, "Surface", "FocusSurface")
    surface.pressed.connect(_focus_depth.bind(0))
    var drill_focus := _button(camera_row, "Foreuse", "FocusDrill")
    drill_focus.pressed.connect(_focus_drill)
    for milestone in [30, 60, 90, 120, 150]:
        var focus := _button(camera_row, "%d m" % milestone, "Focus%d" % milestone)
        focus.pressed.connect(_focus_depth.bind(milestone))
        _milestone_buttons[milestone] = focus

    _mine_layout = BoxContainer.new()
    _mine_layout.name = "MineWorldLayout"
    _mine_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _mine_layout.add_theme_constant_override("separation", 14)
    _mine_panel.add_child(_mine_layout)

    var world_card := PanelContainer.new()
    world_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    world_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
    world_card.add_theme_stylebox_override("panel", Style.panel(Color("0d1821"), Color("294052"), 6))
    _mine_layout.add_child(world_card)
    _mine_world = MineWorldScript.new()
    world_card.add_child(_mine_world)
    _mine_world.bind_session(session)
    _mine_world.selection_changed.connect(_on_world_selection)

    var side := VBoxContainer.new()
    side.name = "MineSidePanel"
    side.custom_minimum_size.x = 280
    side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    side.add_theme_constant_override("separation", 12)
    _mine_layout.add_child(side)

    _site_panel = SitePanelScript.new()
    side.add_child(_site_panel)

    var drill := _card(side)
    _label(drill, "COMMANDES FOREUSE", 14, Style.MUTED)
    _drill_info = _label(drill, "", 16)
    _drill_cost = _label(drill, "", 13, Style.COPPER)
    _drill_upgrade = _button(drill, "Améliorer la foreuse", "DrillUpgrade")
    _drill_upgrade.pressed.connect(_upgrade_drill)
    _dig_info = _label(drill, "", 13, Style.MUTED)
    _dig_progress = _progress(drill, "ExcavationProgress")
    _dig = _button(drill, "", "ExcavationStart")
    _dig.pressed.connect(_start_excavation)

func _add_tab(parent: Node, title: String, node_name: String, view_id: String) -> void:
    var button := _button(parent, title, node_name)
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
    for id in _wallet:
        _wallet[id].text = str(floori(game.resources[id]))
    var maximum: bool = game.drill_level >= Catalog.MAX_DRILL_LEVEL
    var affordable: bool = game.can_afford(game.drill_upgrade_cost())
    _drill_info.text = "Niveau %d / %d · Objectif : −%d m" % [game.drill_level, Catalog.MAX_DRILL_LEVEL, game.depth + 10]
    _drill_cost.text = "Niveau maximum" if maximum else "%s\n%s" % [_cost(game.drill_upgrade_cost()), "Amélioration disponible" if affordable else "Ressources insuffisantes"]
    _drill_upgrade.disabled = maximum or not affordable
    var reason: String = game.excavation_block_reason()
    _dig.disabled = reason != ""
    _dig.text = "Ouvrir le chantier · %s" % _duration(game.excavation_duration())
    _dig_progress.value = 0
    if game.jobs.has("drill"):
        _dig_info.text = "Forage en cours · reste %s" % _duration(game.jobs["drill"]["remaining"])
        _dig_progress.value = _percent(game.jobs["drill"])
    else:
        _dig_info.text = "Chantier disponible · +10 m" if reason == "" else reason
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
            _event_label.text = "Filon instable détecté — choisir une priorité d'exploitation"
            _event_view.text = "CHOISIR"
        else:
            var label := str(Catalog.RESOURCES[resource_id]["label"])
            _event_label.text = "Filon instable · %s · %s restantes" % [label, _duration(float(game.active_event.get("remaining", 0.0)))]
            _event_view.text = "DÉTAILS"
        return
    if not game.pending_events.is_empty():
        _event_banner.visible = true
        _event_label.text = "Filon instable détecté — choisir une priorité d'exploitation"
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
        _save_notice.text = "Sauvegarde : %s\nLa sauvegarde d'origine est préservée. La progression de cette session provisoire ne sera pas enregistrée." % session.save_error
        _save_status.text = "Enregistrement désactivé · Session provisoire."
    elif session.save_error != "":
        _save_notice.text = "Sauvegarde : %s\nNouvelle tentative automatique. La progression récente n'est pas encore enregistrée." % session.save_error
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
    var event_text := "%d événement%s en attente" % [pending_count, "s" if pending_count != 1 else ""]
    _offline.text = "Bon retour · %s d'absence\nRécolté : %s · %d travaux terminés · +%d m · %s" % [
        _duration(session.offline_seconds),
        _cost(report.get("produced", {})),
        completed.size(),
        report.get("depth_gained", 0),
        event_text,
    ]

func _responsive() -> void:
    if _wallet_grid == null:
        return
    var narrow := size.x < 1000
    _wallet_grid.columns = 3 if narrow else 7
    if _mine_layout != null:
        _mine_layout.vertical = size.x < 880
    if _industry_panel != null:
        _industry_panel._responsive()

func _upgrade_drill() -> void:
    session.upgrade_drill()

func _start_excavation() -> void:
    session.start_excavation()

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

func _percent(job: Dictionary) -> float:
    return 100.0 * (1.0 - float(job["remaining"]) / float(job["duration"]))

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

func _progress(parent: Node, node_name: String) -> ProgressBar:
    var bar := ProgressBar.new()
    bar.name = node_name
    bar.custom_minimum_size.y = 8
    bar.show_percentage = false
    parent.add_child(bar)
    return bar
