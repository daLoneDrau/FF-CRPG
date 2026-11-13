class_name PotionColumn
extends PanelContainer
## One potion choice on the Character Creation screen: a 3D stage and a numbered
## name row inside a slot panel. The border turns red when selected, through the
## PotionSlot / PotionSlotSelected theme variations.
##
## The potion shown is static: number, id and name are set on each instance in
## character_creation.tscn. There is no external data for it.

## Emitted when the player clicks this column.
signal chosen

## Hotkey shown on screen (1, 2, 3).
@export var number: int = 1
## Identifier handed to whoever consumes the choice, for example "skill".
@export var potion_id: StringName = &""
## Text shown next to the number, for example "SKILL".
@export var potion_name: String = ""
## Emission colour of the liquid. Leave the alpha at 0 to keep the model's own colour.
@export var liquid_color: Color = Color(0.0, 0.0, 0.0, 0.0)

@onready var _stage: Stage3D = %Stage
@onready var _cursor: Label = %Cursor
@onready var _index: Label = %Index
@onready var _name: Label = %Name


func _ready() -> void:
	_index.text = str(number)
	_name.text = potion_name
	# The stage's own _ready has already loaded its model by now (children ready first).
	if liquid_color.a > 0.0:
		_stage.tint_node(&"liquid", liquid_color)
	set_selected(false)


## Switches the border colour and shows the ">" cursor. The cursor uses alpha 0 (not
## hide) so the row keeps its width and stays centred.
func set_selected(selected: bool) -> void:
	theme_type_variation = &"PotionSlotSelected" if selected else &"PotionSlot"
	_cursor.modulate.a = 1.0 if selected else 0.0


func _gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		chosen.emit()
