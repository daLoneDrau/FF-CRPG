class_name TitleScene
extends Scene
## Title screen: a press-to-start gate, then the main menu.
##
## Layout lives in title.tscn (measured from the 320x180 wireframe). This script
## owns behaviour only: input, menu state, and the animated .glb on the stage.
## Keyboard input arrives from GameEngine as GameActions (register_action / do_action).
## Mouse input is handled here with Control signals.

signal new_game_requested
signal continue_requested
signal settings_requested

## Scene keys the Title hands off to. Each must be registered with GameEngine
## (register_scene) before its menu item works; until then the footer says so.
const SCENE_NEW_GAME := "character_creation"
const PATH_NEW_GAME := "res://scenes/character_creation/character_creation.tscn"
const SCENE_CONTINUE := "slot_select"
const SCENE_SETTINGS := "settings"

const SAVE_DIR := "user://saves"
const SLOT_COUNT := 3
const MESSAGE_SECONDS := 2.5
const BLINK_SECONDS := 0.6

## Node3D inside the diorama that the camera flies toward on New Game.
const ENTRANCE_NODE := "dungeon_entrance"

enum State { GATE, MENU, LEAVING }
enum Item { NEW_GAME, CONTINUE, SETTINGS }

## The imported .glb (as a PackedScene) shown on the stage. Leave empty to keep
## the hatched placeholder.
@export var stage_model: PackedScene
## Scale the model to fit inside fit_size (metres) and centre it on the stage.
@export var auto_fit: bool = true
@export var fit_size: Vector3 = Vector3(8.0, 2.2, 3.0)

@export_group("Cave dolly")
## Seconds the camera takes to move into the cave when New Game is chosen.
@export var dolly_seconds: float = 1.0
## Perspective camera: how close to the entrance the camera stops (scene units).
@export var dolly_stop_distance: float = 0.3
## Orthographic camera: final view size as a fraction of the starting size
## (smaller means closer). An orthographic camera can't dolly, so it pans and zooms.
@export_range(0.05, 1.0) var dolly_ortho_zoom: float = 0.2

@onready var _screen: Control = %Screen
@onready var _footer: Label = %Footer
@onready var _placeholder: Control = %StagePlaceholder
@onready var _anchor: Node3D = %StageAnchor
@onready var _camera: Camera3D = %StageCamera
@onready var _gate: Label = %GatePrompt
@onready var _menu: Control = %MenuList

var _state: State = State.GATE
var _cursor: int = Item.NEW_GAME
var _rows: Array[Control] = []
var _enabled: Array[bool] = [true, false, true]
var _footer_text: String = ""
var _blink: Tween
var _flash_tween: Tween
var _dolly: Tween


# —— Lifecycle ———————————————————————————————————————————

## GameEngine calls this after set_engine(), so _game_engine is valid here.
func on_enter() -> void:
	_footer_text = _footer.text
	_enabled[Item.CONTINUE] = _has_any_save()

	_rows.clear()
	for child in _menu.get_children():
		_rows.append(child as Control)
	for i in _rows.size():
		_wire_row(i)
	_screen.gui_input.connect(_on_screen_gui_input)

	_load_stage()
	_refresh_rows()
	_show_gate()


func on_exit() -> void:
	if _blink:
		_blink.kill()
	if _flash_tween:
		_flash_tween.kill()
	if _dolly:
		_dolly.kill()


# —— Input ———————————————————————————————————————————————

func do_action(action: GameAction) -> void:
	# The engine sends key press AND release. Only act on press.
	if not action.is_pressed():
		return
	match action.name:
		"gate_open":
			_show_menu()
		"menu_up":
			_move_cursor(-1)
		"menu_down":
			_move_cursor(1)
		"menu_confirm":
			_activate(_cursor)
		"menu_item_0":
			_activate(Item.NEW_GAME)
		"menu_item_1":
			_activate(Item.CONTINUE)
		"menu_item_2":
			_activate(Item.SETTINGS)


func _on_screen_gui_input(event: InputEvent) -> void:
	if _state == State.GATE and _is_left_click(event):
		_show_menu()


func _wire_row(index: int) -> void:
	var row := _rows[index]
	row.mouse_entered.connect(func() -> void:
		if _state == State.MENU and _enabled[index]:
			_set_cursor(index))
	row.gui_input.connect(func(event: InputEvent) -> void:
		if _state == State.MENU and _is_left_click(event):
			_activate(index))


func _is_left_click(event: InputEvent) -> bool:
	var mouse := event as InputEventMouseButton
	return mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT


# —— States ——————————————————————————————————————————————

func _show_gate() -> void:
	_state = State.GATE
	_menu.hide()
	_gate.show()
	clear_actions()
	# Engine fallback: fires for any key that has no specific action.
	register_action("any_key", "gate_open")

	if _blink:
		_blink.kill()
	_blink = create_tween().set_loops()
	_blink.tween_callback(func() -> void: _gate.visible = false).set_delay(BLINK_SECONDS)
	_blink.tween_callback(func() -> void: _gate.visible = true).set_delay(BLINK_SECONDS)


func _show_menu() -> void:
	_state = State.MENU
	if _blink:
		_blink.kill()
	_gate.hide()
	_menu.show()

	# Replaces the gate's any_key fallback, so stray keys do nothing now.
	clear_actions()
	register_action("Up", "menu_up")
	register_action("W", "menu_up")
	register_action("Down", "menu_down")
	register_action("S", "menu_down")
	register_action("Enter", "menu_confirm")
	register_action("Kp Enter", "menu_confirm")
	register_action("Space", "menu_confirm")
	for i in _rows.size():
		register_action(str(i + 1), "menu_item_%d" % i)
		register_action("Kp %d" % (i + 1), "menu_item_%d" % i)

	_set_cursor(Item.NEW_GAME)


# —— Menu ————————————————————————————————————————————————

func _set_cursor(item: int) -> void:
	_cursor = item
	_refresh_rows()


func _move_cursor(step: int) -> void:
	var item := _cursor
	for _n in _rows.size():
		item = posmod(item + step, _rows.size())
		if _enabled[item]:
			_set_cursor(item)
			return


## Row children, in order: Cursor, Index, Text.
func _refresh_rows() -> void:
	for i in _rows.size():
		var parts := _rows[i].get_children()
		var cursor_label := parts[0] as Label
		var index_label := parts[1] as Label
		var text_label := parts[2] as Label
		var enabled := _enabled[i]
		# Alpha 0 (not hide) so the cursor column keeps its width and the row stays centred.
		cursor_label.modulate.a = 1.0 if (i == _cursor and enabled) else 0.0
		index_label.theme_type_variation = &"MenuAccent" if enabled else &"MenuDisabled"
		text_label.theme_type_variation = &"" if enabled else &"MenuDisabled"


func _activate(item: int) -> void:
	if not _enabled[item]:
		_flash("NO SAVED GAME")
		return
	match item:
		Item.NEW_GAME:
			if _free_slot() == -1:
				_flash("ALL SLOTS FULL - DELETE ONE FIRST")
				return
			if not _can_go(SCENE_NEW_GAME, PATH_NEW_GAME):
				_flash("NOT BUILT YET")
				return
			new_game_requested.emit()
			_enter_cave(func() -> void: _go(SCENE_NEW_GAME, PATH_NEW_GAME))
		Item.CONTINUE:
			continue_requested.emit()
			_go(SCENE_CONTINUE)
		Item.SETTINGS:
			settings_requested.emit()
			_go(SCENE_SETTINGS, "", true)


## True when the engine can load scene_key: the file exists (if a path is
## given) or the key is already registered.
func _can_go(scene_key: String, scene_path: String = "") -> bool:
	if _game_engine == null:
		return false
	if scene_path != "":
		return ResourceLoader.exists(scene_path)
	return _game_engine.scenes.has(scene_key)


## Asks the engine to load scene_key. If scene_path is given, the engine
## registers the key on first use; otherwise the key must already be registered.
func _go(scene_key: String, scene_path: String = "", as_overlay: bool = false) -> void:
	if not _can_go(scene_key, scene_path):
		_flash("NOT BUILT YET")
		return
	if as_overlay:
		_game_engine.push_scene(scene_key, scene_path)
	else:
		_game_engine.change_scene(scene_key, scene_path)


## Flies the stage camera into the diorama's entrance, then calls on_done.
## Input is locked while it runs. With no entrance node, on_done runs at once.
func _enter_cave(on_done: Callable) -> void:
	_state = State.LEAVING
	clear_actions()

	var entrance := _anchor.find_child(ENTRANCE_NODE, true, false) as Node3D
	if entrance == null or _camera == null:
		push_warning("TitleScene: '%s' not found, skipping the dolly." % ENTRANCE_NODE)
		on_done.call()
		return

	var cam_pos := _camera.global_position
	var cam_basis := _camera.global_transform.basis
	var to_target := entrance.global_position - cam_pos
	var end_pos: Vector3

	_dolly = create_tween().set_parallel(true)
	_dolly.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	if _camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
		# Moving along the view axis changes nothing in an orthographic view,
		# so slide sideways until the entrance is centred and shrink the view.
		var local := cam_basis.inverse() * to_target
		end_pos = cam_pos + cam_basis * Vector3(local.x, local.y, 0.0)
		_dolly.tween_property(_camera, "size", _camera.size * dolly_ortho_zoom, dolly_seconds)
	else:
		end_pos = entrance.global_position - to_target.normalized() * dolly_stop_distance

	_dolly.tween_property(_camera, "global_position", end_pos, dolly_seconds)
	_dolly.chain().tween_callback(on_done)


## Shows a message in the footer line, then restores the tagline.
func _flash(text: String) -> void:
	if _flash_tween:
		_flash_tween.kill()
	_footer.text = text
	_flash_tween = create_tween()
	_flash_tween.tween_interval(MESSAGE_SECONDS)
	_flash_tween.tween_callback(func() -> void: _footer.text = _footer_text)


# —— Saves (probe only; the save service comes later) ————————

func _slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, slot]


func _has_any_save() -> bool:
	for slot in range(1, SLOT_COUNT + 1):
		if FileAccess.file_exists(_slot_path(slot)):
			return true
	return false


## First empty slot (1-based), or -1 when all are full.
func _free_slot() -> int:
	for slot in range(1, SLOT_COUNT + 1):
		if not FileAccess.file_exists(_slot_path(slot)):
			return slot
	return -1


# —— Stage (animated .glb) ———————————————————————————————

func _load_stage() -> void:
	if stage_model == null:
		return
	var model := stage_model.instantiate() as Node3D
	if model == null:
		push_warning("TitleScene: stage_model root is not a Node3D.")
		return
	_anchor.add_child(model)
	if auto_fit:
		_fit_to_stage(model)
	_placeholder.hide()
	_play_first_animation(model)


func _play_first_animation(model: Node3D) -> void:
	var players := model.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		return
	var player := players[0] as AnimationPlayer
	for anim_name in player.get_animation_list():
		if anim_name == "RESET":
			continue
		player.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
		player.play(anim_name)
		return


func _fit_to_stage(model: Node3D) -> void:
	var bounds := _combined_aabb(model)
	if bounds.size == Vector3.ZERO:
		return
	var factor := minf(
			minf(fit_size.x / bounds.size.x, fit_size.y / bounds.size.y),
			fit_size.z / bounds.size.z)
	model.scale = Vector3.ONE * factor
	model.position = -bounds.get_center() * factor


## Bounding box of every visual node under root, in root's local space.
func _combined_aabb(root: Node3D) -> AABB:
	var to_local := root.global_transform.affine_inverse()
	var result := AABB()
	var first := true
	for node in root.find_children("*", "VisualInstance3D", true, false):
		var visual := node as VisualInstance3D
		var box := (to_local * visual.global_transform) * visual.get_aabb()
		result = box if first else result.merge(box)
		first = false
	return result
