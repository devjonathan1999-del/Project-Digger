class_name IndustryTheme
extends RefCounted

const BACKGROUND := Color("0b1420")
const PANEL := Color("142334")
const ACCENT := Color("52dcc5")
const COPPER := Color("f0b272")
const TEXT := Color("eff4ef")
const MUTED := Color("9eb3c5")

static func panel(color: Color = PANEL, border: Color = Color("294052"), padding: int = 16) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = border
    style.set_border_width_all(1)
    style.set_corner_radius_all(10)
    style.content_margin_left = padding
    style.content_margin_right = padding
    style.content_margin_top = padding
    style.content_margin_bottom = padding
    return style

static func create() -> Theme:
    var result := Theme.new()
    result.default_font_size = 16
    result.set_color("font_color", "Label", TEXT)
    result.set_color("font_color", "Button", TEXT)
    result.set_color("font_disabled_color", "Button", MUTED)
    result.set_stylebox("panel", "PanelContainer", panel())
    for type in ["Button", "OptionButton"]:
        result.set_stylebox("normal", type, panel(Color("203a4a"), Color("3e6374"), 10))
        result.set_stylebox("hover", type, panel(Color("294e5b"), ACCENT, 10))
        result.set_stylebox("pressed", type, panel(Color("16665e"), ACCENT, 10))
        result.set_stylebox("disabled", type, panel(Color("172a39"), Color("263d4e"), 10))
        result.set_stylebox("focus", type, panel(Color(0, 0, 0, 0), ACCENT, 0))
        result.set_color("font_color", type, TEXT)
    result.set_stylebox("normal", "LineEdit", panel(Color("0e1d2a"), Color("3e6374"), 10))
    result.set_stylebox("background", "ProgressBar", panel(Color("091823"), Color("294052"), 0))
    result.set_stylebox("fill", "ProgressBar", panel(ACCENT, ACCENT, 0))
    result.set_constant("separation", "VBoxContainer", 10)
    result.set_constant("separation", "HBoxContainer", 12)
    result.set_constant("h_separation", "GridContainer", 12)
    result.set_constant("v_separation", "GridContainer", 12)
    return result
