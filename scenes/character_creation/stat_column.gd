class_name StatColumn
extends MarginContainer
## One attribute on the Character Creation screen: a heading, the dice expression,
## the die stage(s), and the ROLL / TOTAL text that appears once the dice land.
##
## The column owns its own roll. Heading, dice count and bonus are set per instance
## in character_creation.tscn (SKILL 1 and 6, STAMINA 2 and 12, LUCK 1 and 6).

## Emitted when every die in this column has settled after roll().
signal landed

## Attribute name shown at the top, for example "SKILL".
@export var heading: String = ""
## Number of six-sided dice: 1 or 2.
@export_range(1, 2) var dice_count: int = 1
## Added to the dice total.
@export var bonus: int = 0

## The face values of the last roll, one per die.
var dice: Array[int] = []
## Dice total plus bonus for the last roll.
var total: int = 0

@onready var _heading: Label = %Heading
@onready var _expression: Label = %Expression
@onready var _die_a: Stage3D = %Die1
@onready var _die_b: Stage3D = %Die2
@onready var _roll: Label = %Roll
@onready var _total: Label = %Total

var _stages: Array[Stage3D] = []
var _pending: int = 0


func _ready() -> void:
	_heading.text = heading
	_expression.text = "%dD6+%d" % [dice_count, bonus]
	if dice_count < 2:
		_stages.assign([_die_a])
	else:
		_stages.assign([_die_a, _die_b])
	# _stages = [_die_a] if dice_count < 2 else [_die_a, _die_b]
	_die_b.visible = dice_count >= 2
	for stage in _stages:
		stage.settled.connect(_on_die_settled)


## Rolls the dice, tumbles the stages to the result and hides the old numbers.
## The ROLL / TOTAL text appears when `landed` fires.
func roll() -> void:
	dice.clear()
	total = bonus
	for value in DiceTower_auto.roll_dice(dice_count, 6):
		dice.append(int(value))
		total += int(value)
	hide_result()
	_pending = _stages.size()
	for i in _stages.size():
		_stages[i].tumble_to_face(dice[i])


## Shows "ROLL 4" (or "ROLL 3+5") and "TOTAL 10".
func show_result() -> void:
	var parts := PackedStringArray()
	for value in dice:
		parts.append(str(value))
	_roll.text = "ROLL %s" % "+".join(parts)
	_total.text = "TOTAL %d" % total
	_roll.show()
	_total.show()


func hide_result() -> void:
	_roll.hide()
	_total.hide()


## A reroll mid-tumble kills the old tweens, so a stale roll never reaches the count.
func _on_die_settled() -> void:
	_pending -= 1
	if _pending <= 0:
		landed.emit()
