class_name StatsComponent
extends EntityComponent


## SKILL, STAMINA and LUCK for the adventurer, each kept as an Initial value
## (rolled at Character Creation, never changes) and a Current value (what the
## game changes). Nothing here is modified by equipment, spells or statuses.

const SKILL: StringName = &"skill"
const STAMINA: StringName = &"stamina"
const LUCK: StringName = &"luck"

## The rolled values. Set once by setup().
var initial: Dictionary[StringName, int] = {SKILL: 0, STAMINA: 0, LUCK: 0}
## The values in play. Starts equal to initial.
var current: Dictionary[StringName, int] = {SKILL: 0, STAMINA: 0, LUCK: 0}


func _init() -> void:
	super()


## Assigns the rolled stats. Initial and Current both start at the rolled value.
func setup(skill: int, stamina: int, luck: int) -> void:
	initial = {SKILL: skill, STAMINA: stamina, LUCK: luck}
	current = initial.duplicate()
	emit_update_signal()


func get_initial(stat: StringName) -> int:
	return initial.get(stat, 0)


func get_current(stat: StringName) -> int:
	return current.get(stat, 0)


## Sets the Current value of a stat. Ignores unknown stats.
func set_current(stat: StringName, value: int) -> void:
	if not current.has(stat):
		return
	current[stat] = value
	emit_update_signal()


func to_dict() -> Dictionary:
	return {
		"key": get_class_name(),
		"initial": {SKILL: initial[SKILL], STAMINA: initial[STAMINA], LUCK: initial[LUCK]},
		"current": {SKILL: current[SKILL], STAMINA: current[STAMINA], LUCK: current[LUCK]},
	}


func from_dict(data: Dictionary) -> void:
	var i: Dictionary = data.get("initial", {})
	var c: Dictionary = data.get("current", {})
	for stat: StringName in [SKILL, STAMINA, LUCK]:
		initial[stat] = int(i.get(stat, 0))
		current[stat] = int(c.get(stat, initial[stat]))
	emit_update_signal()
