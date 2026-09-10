class_name IndustryScreen
extends Control

const Catalog = preload("res://src/industry/industry_catalog.gd")
const Style = preload("res://src/industry/ui/industry_theme.gd")
const Overview = preload("res://src/industry/ui/mine_overview.gd")
const IndustryPanelScript = preload("res://src/industry/ui/industry_panel.gd")
const CenterPanelScript = preload("res://src/industry/ui/center_panel.gd")
const TechnologyPanelScript = preload("res://src/industry/ui/technology_panel.gd")

var session
var _wallet: Dictionary = {}
var _wallet_grid: GridContainer
var _content_host: VBoxContainer
var _mine_panel: VBoxContainer
var _industry_panel
var _center_panel
var _technology_panel
var _depth: Label
var _overview: Control
var _drill_info: Label
var _drill_cost: Label
var _drill_upgrade: Button
var _dig: Button
var _dig_info: Label
var _dig_progress: ProgressBar
var _offline: Label
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

    _offline = _label(shell, "", 14, Style.ACCENT)
    _offline.name = "OfflineNotice"
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

func _build_mine_panel() -> void:
    _mine_panel = VBoxContainer.new()
    _mine_panel.name = "MinePanel"
    _mine_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _mine_panel.add_theme_constant_override("separation", 14)
    _content_host.add_child(_mine_panel)
    _label(_mine_panel, "MINE", 22)
    _label(_mine_panel, "Descends par horizons de 10 m et ouvre de nouveaux paliers.", 14, Style.MUTED)
    var row := BoxContainer.new()
    row.name = "MineColumns"
    row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_theme_constant_override("separation", 16)
    _mine_panel.add_child(row)

    var survey := _card(row)
    survey.custom_minimum_size.x = 280
    _label(survey, "COUPE DU SOUS-SOL", 14, Style.MUTED)
    _overview = Overview.new()
    survey.add_child(_overview)

    var drill := _card(row)
    _label(drill, "Foreuse", 20)
    _drill_info = _label(drill, "", 14, Style.MUTED)
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
    if view_id == "industry":
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
    _overview.set_progress(game.depth, game.drill_level, game.jobs.get("drill", {}))
    _industry_panel.refresh()
    _center_panel.refresh()
    _technology_panel.refresh()

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
    _offline.visible = session.offline_seconds >= 5.0
    if _offline.visible:
        var report: Dictionary = session.offline_report
        var completed: Array = report.get("completed", [])
        _offline.text = "Bon retour · %s d'absence\nRécolté : %s · %d travaux terminés · +%d m" % [_duration(session.offline_seconds), _cost(report.get("produced", {})), completed.size(), report.get("depth_gained", 0)]

func _responsive() -> void:
    if _wallet_grid == null:
        return
    var narrow := size.x < 1000
    _wallet_grid.columns = 3 if narrow else 7
    var mine_columns = find_child("MineColumns", true, false) as BoxContainer
    if mine_columns != null:
        mine_columns.vertical = size.x < 720
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
