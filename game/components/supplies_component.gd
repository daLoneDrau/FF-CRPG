class_name SuppliesComponent
extends EntityComponent
## The adventurer's counters: Provisions (meals) and the chosen potion with its
## remaining measures. These are not items and take no inventory slot.

const STARTING_PROVISIONS: int = 10
const STARTING_MEASURES: int = 2

## Meals left. One meal costs 1 and restores 4 STAMINA.
var provisions: int = STARTING_PROVISIONS
## The chosen potion: "skill", "strength" or "fortune".
var potion: StringName = &""
## Measures left in the potion bottle.
var potion_measures: int = STARTING_MEASURES


func _init() -> void:
	super()


## Sets the starting supplies: 10 Provisions and a full bottle of the chosen potion.
func setup(p_potion: StringName) -> void:
	provisions = STARTING_PROVISIONS
	potion = p_potion
	potion_measures = STARTING_MEASURES
	emit_update_signal()


func set_provisions(value: int) -> void:
	provisions = maxi(value, 0)
	emit_update_signal()


func set_potion_measures(value: int) -> void:
	potion_measures = maxi(value, 0)
	emit_update_signal()


func to_dict() -> Dictionary:
	return {
		"key": get_class_name(),
		"provisions": provisions,
		"potion": String(potion),
		"potion_measures": potion_measures,
		}


func from_dict(data: Dictionary) -> void:
	provisions = int(data.get("provisions", 0))
	potion = StringName(data.get("potion", ""))
	potion_measures = int(data.get("potion_measures", 0))
	emit_update_signal()
