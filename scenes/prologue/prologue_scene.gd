class_name PrologueScene
extends Scene
## Prologue: the background and the inciting event, told as twelve screens of text over
## 3D diorama vignettes. The player can only move forward or skip. The scene exits to
## the Adventure. See docs/prologue.md in the project for the design.
##
## Layout lives in prologue.tscn and is built from containers. Two layouts share the
## screen and only one is visible at a time:
##  - Stage: one large diorama (306x90) over a 58px text panel with a red caption line.
##  - Carousel: three small dioramas (98x54) over an 84px text panel. The active panel
##    has a red frame and a red caption, and the highlight moves when the beat changes.
## The content is in PrologueData. This script owns behaviour only.
##
## Input arrives from GameEngine as GameActions (register_action / do_action).
##  - Space, Enter or a left click: next screen. On the last screen it begins the Adventure.
##  - S: skip straight to the Adventure.
## There is no Back. The last screen replaces SKIP with ENTER - BEGIN ADVENTURE.
##
## The Prologue writes nothing to the save. The save was written at Accept in Character
## Creation, so leaving early loses nothing.

const ADVENTURE_KEY := "adventure"
const ADVENTURE_PATH := "res://scenes/adventure/adventure.tscn"
const MESSAGE_SECONDS := 2.5

## Ignore advance input for this long after opening, so the Enter that accepted the
## character (or its key repeat) cannot skip the first screen.
const INPUT_GUARD_MSEC := 300

## Art area and text panel heights (pixels) for each layout, from the wireframes.
const STAGE_ART_HEIGHT := 90.0
const STAGE_TEXT_HEIGHT := 58.0
const CAROUSEL_ART_HEIGHT := 64.0
const CAROUSEL_TEXT_HEIGHT := 84.0

@onready var _screen: Control = %Screen
@onready var _art: Control = %Art
@onready var _stage_area: Control = %StageArea
@onready var _carousel_area: Control = %CarouselArea
@onready var _text_panel: Control = %TextPanel
@onready var _caption: Label = %Caption
@onready var _body: Label = %Body
@onready var _command_bar: Control = %CommandBar
@onready var _cmd_next: Control = %CmdNext
@onready var _cmd_skip: Control = %CmdSkip
@onready var _counter: Label = %Counter
@onready var _message: Label = %Message

## One entry per carousel panel, left to right. Filled in on_enter().
var _frames: Array[ReferenceRect] = []
var _panel_captions: Array[Label] = []

var _screens: Array[Dictionary] = []
var _index: int = 0
var _opened_msec: int = 0
var _leaving: bool = false
var _flash_tween: Tween


# —— Lifecycle ———————————————————————————————————————————

## GameEngine calls this after set_engine(), so _game_engine is valid here.
func on_enter() -> void:
	_opened_msec = Time.get_ticks_msec()
	_screens = PrologueData.build_screens()

	_frames.clear()
	_panel_captions.clear()
	for i in PrologueData.CAROUSEL_CAPTIONS.size():
		_frames.append(get_node("%%Frame%d" % (i + 1)) as ReferenceRect)
		var caption := get_node("%%PanelCaption%d" % (i + 1)) as Label
		caption.text = PrologueData.CAROUSEL_CAPTIONS[i]
		_panel_captions.append(caption)

	_wire_command(_cmd_next, _advance)
	_wire_command(_cmd_skip, _leave)
	_screen.gui_input.connect(_on_screen_gui_input)

	_register_keys()
	_show_screen(0)


func on_exit() -> void:
	if _flash_tween:
		_flash_tween.kill()


# —— Input ———————————————————————————————————————————————

func _register_keys() -> void:
	clear_actions()
	register_action("Space", "next")
	register_action("Enter", "next")
	register_action("Kp Enter", "next")
	register_action("S", "skip")


func do_action(action: GameAction) -> void:
	# The engine sends key press AND release. Only act on press.
	if not action.is_pressed():
		return
	if action.name == "next":
		_advance()
	elif action.name == "skip":
		_leave()


## A left click anywhere that is not a command row continues. Command rows accept their
## own click event, so it does not reach here.
func _on_screen_gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		_advance()


func _wire_command(row: Control, handler: Callable) -> void:
	row.gui_input.connect(func(event: InputEvent) -> void:
		var mouse := event as InputEventMouseButton
		if mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			row.accept_event()
			handler.call())


func _input_ready() -> bool:
	return not _leaving and Time.get_ticks_msec() - _opened_msec >= INPUT_GUARD_MSEC


# —— Screens —————————————————————————————————————————————

## Next screen. On the last screen this begins the Adventure.
func _advance() -> void:
	if not _input_ready():
		return
	if _index >= _screens.size() - 1:
		_go_to_adventure()
		return
	_show_screen(_index + 1)


## Skip: leave from any screen.
func _leave() -> void:
	if not _input_ready():
		return
	_go_to_adventure()


func _show_screen(index: int) -> void:
	_index = index
	var data := _screens[index]
	var is_stage: bool = data["layout"] == PrologueData.STAGE

	_stage_area.visible = is_stage
	_carousel_area.visible = not is_stage
	_art.custom_minimum_size.y = STAGE_ART_HEIGHT if is_stage else CAROUSEL_ART_HEIGHT
	_text_panel.custom_minimum_size.y = STAGE_TEXT_HEIGHT if is_stage else CAROUSEL_TEXT_HEIGHT

	_caption.visible = is_stage
	_caption.text = data["caption"]
	_body.text = data["text"]
	if not is_stage:
		_highlight_panel(data["panel"])

	_counter.text = "%d/%d" % [index + 1, _screens.size()]
	_refresh_commands()


## Frames the active carousel panel in red and the others in ink.
func _highlight_panel(active: int) -> void:
	var ink := _screen.get_theme_color(&"font_color", &"Label")
	var red := _screen.get_theme_color(&"font_color", &"MenuAccent")
	for i in _frames.size():
		_frames[i].border_color = red if i == active else ink
		_panel_captions[i].theme_type_variation = &"MenuAccent" if i == active else &""


## NEXT and SKIP on every screen but the last. The last shows only ENTER - BEGIN ADVENTURE,
## in place of SKIP.
func _refresh_commands() -> void:
	var is_last := _index >= _screens.size() - 1
	# Alpha 0 (not hide) so NEXT keeps its width and BEGIN ADVENTURE stays centred.
	_cmd_next.modulate.a = 0.0 if is_last else 1.0
	_cmd_next.mouse_filter = Control.MOUSE_FILTER_IGNORE if is_last else Control.MOUSE_FILTER_PASS
	var key := _cmd_skip.get_node("Key") as Label
	var text := _cmd_skip.get_node("Text") as Label
	key.text = "ENTER" if is_last else "S"
	text.text = "- BEGIN ADVENTURE" if is_last else "- SKIP"


# —— Exit ————————————————————————————————————————————————

func _go_to_adventure() -> void:
	if _game_engine == null or not ResourceLoader.exists(ADVENTURE_PATH):
		_flash("ADVENTURE NOT BUILT YET")
		return
	_leaving = true
	clear_actions()
	_game_engine.change_scene(ADVENTURE_KEY, ADVENTURE_PATH)


## Shows a message in place of the command row, then restores the row.
func _flash(text: String) -> void:
	if _flash_tween:
		_flash_tween.kill()
	_message.text = text
	_message.show()
	_command_bar.hide()
	_flash_tween = create_tween()
	_flash_tween.tween_interval(MESSAGE_SECONDS)
	_flash_tween.tween_callback(func() -> void:
		_message.hide()
		_command_bar.show())
