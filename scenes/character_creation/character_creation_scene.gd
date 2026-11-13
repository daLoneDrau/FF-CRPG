class_name CharacterCreationScene
extends Scene
## Character Creation: roll the stats, pick one potion, accept.
##
## Layout lives in character_creation.tscn and is built from containers (margin,
## vbox, hbox, panel), so it follows the viewport instead of fixed offsets.
## This script owns behaviour only: input, the roll, the potion selection, Accept.
## Keyboard input arrives from GameEngine as GameActions (register_action / do_action).
## Mouse input is handled here with Control signals, as in TitleScene.
##
## Flow (see character-creation.md):
##  - The scene rolls as soon as it loads. R rerolls all three stats, immediately,
##    with no limit and no prompt. A reroll never clears the potion choice.
##  - Keys 1/2/3 (or a click) choose a potion. None is chosen on open.
##  - ENTER accepts. It is greyed until a potion is chosen, and it is final.
##  - BACKSPACE goes back to Title and discards the character.
##
## Accept hands the rolled stats and the chosen potion id, as one Dictionary, to
## whoever listens on `accepted`, then moves on to the Prologue. The view does not build entities or
## write saves. CharacterCreationSystem, added in on_enter(), listens through the
## Switchboard, creates the adventurer and equips the starting items.

## Emitted on Accept with
## {"skill": int, "stamina": int, "luck": int,
##  "skill_dice": Array[int], "stamina_dice": Array[int], "luck_dice": Array[int],
##  "potion": StringName}.
signal accepted(result: Dictionary)
signal back_requested

const PROLOGUE_KEY := "prologue"
const PROLOGUE_PATH := "res://scenes/prologue/prologue.tscn"
const MESSAGE_SECONDS := 2.5
const NO_POTION := -1

@onready var _skill: StatColumn = %SkillColumn
@onready var _stamina: StatColumn = %StaminaColumn
@onready var _luck: StatColumn = %LuckColumn
@onready var _potions_box: Control = %Potions
@onready var _command_bar: Control = %CommandBar
@onready var _cmd_roll: Control = %CmdRoll
@onready var _cmd_back: Control = %CmdBack
@onready var _cmd_accept: Control = %CmdAccept
@onready var _message: Label = %Message

var _selected: int = NO_POTION
var _stats: Array[StatColumn] = []
var _columns: Array[PotionColumn] = []
var _landed_count: int = 0
var _flash_tween: Tween


# —— Lifecycle ———————————————————————————————————————————

## GameEngine calls this after set_engine(), so _game_engine is valid here.
func on_enter() -> void:
	_stats = [_skill, _stamina, _luck]
	for stat in _stats:
		stat.landed.connect(_on_stat_landed)

	_columns.clear()
	for child in _potions_box.get_children():
		_columns.append(child as PotionColumn)
	for i in _columns.size():
		_columns[i].chosen.connect(_select_potion.bind(i))

	_wire_command(_cmd_roll, _reroll)
	_wire_command(_cmd_back, _back)
	_wire_command(_cmd_accept, _accept)

	_register_keys()
	_refresh_potions()
	_refresh_accept()

	# FFScriptSystem runs entity scripts. CharacterCreationSystem listens for `accepted`,
	# creates the adventurer and equips its items through FFEquipmentSystem.
	Switchboard_auto.add_node_broadcaster(self, "accepted")
	var scripts := FFScriptSystem.new()
	add_child(scripts)
	register_system(scripts)
	var equipment := FFEquipmentSystem.new()
	add_child(equipment)
	register_system(equipment)
	var system := CharacterCreationSystem.new()
	add_child(system)
	register_system(system)

	_roll()


func on_exit() -> void:
	Switchboard_auto.remove_node_broadcaster(self, "accepted")
	if _flash_tween:
		_flash_tween.kill()


# —— Input ———————————————————————————————————————————————

func _register_keys() -> void:
	clear_actions()
	register_action("R", "reroll")
	register_action("Backspace", "back")
	register_action("Enter", "accept")
	register_action("Kp Enter", "accept")
	for i in _columns.size():
		register_action(str(i + 1), "potion_%d" % i)
		register_action("Kp %d" % (i + 1), "potion_%d" % i)


func do_action(action: GameAction) -> void:
	# The engine sends key press AND release. Only act on press.
	if not action.is_pressed():
		return
	if action.name == "reroll":
		_reroll()
	elif action.name == "back":
		_back()
	elif action.name == "accept":
		_accept()
	elif action.name.begins_with("potion_"):
		_select_potion(int(action.name.trim_prefix("potion_")))


func _wire_command(row: Control, handler: Callable) -> void:
	row.gui_input.connect(func(event: InputEvent) -> void:
		var mouse := event as InputEventMouseButton
		if mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			handler.call())


# —— Rolling —————————————————————————————————————————————

func _reroll() -> void:
	_roll()


## Rolls all three stats, tumbles the dice, and reveals the numbers when they land.
func _roll() -> void:
	_landed_count = 0
	for stat in _stats:
		stat.roll()


func _on_stat_landed() -> void:
	_landed_count += 1
	if _landed_count >= _stats.size():
		for stat in _stats:
			stat.show_result()


# —— Potions —————————————————————————————————————————————

func _select_potion(index: int) -> void:
	if index < 0 or index >= _columns.size():
		return
	_selected = index
	_refresh_potions()
	_refresh_accept()


func _refresh_potions() -> void:
	for i in _columns.size():
		_columns[i].set_selected(i == _selected)


## ACCEPT is greyed until a potion is chosen.
func _refresh_accept() -> void:
	var enabled := _selected != NO_POTION
	(_cmd_accept.get_node("Key") as Label).theme_type_variation = \
		&"MenuAccent" if enabled else &"MenuDisabled"
	(_cmd_accept.get_node("Text") as Label).theme_type_variation = \
		&"" if enabled else &"MenuDisabled"


# —— Exits ———————————————————————————————————————————————

func _back() -> void:
	# Nothing was saved before Accept, so there is nothing to discard.
	back_requested.emit()
	if _game_engine != null:
		_game_engine.change_scene(FFEngine.TITLE_KEY)


## Final. Reports the stats and the chosen potion, then goes to the Prologue.
func _accept() -> void:
	if _selected == NO_POTION:
		return
	accepted.emit({
		"skill": _skill.total,
		"stamina": _stamina.total,
		"luck": _luck.total,
		"skill_dice": _skill.dice,
		"stamina_dice": _stamina.dice,
		"luck_dice": _luck.dice,
		"potion": _columns[_selected].potion_id,
	})
	if not ResourceLoader.exists(PROLOGUE_PATH):
		_flash("PROLOGUE NOT BUILT YET")
		return
	_game_engine.change_scene(PROLOGUE_KEY, PROLOGUE_PATH)


## Shows a message in the keys panel, then restores the command row.
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
