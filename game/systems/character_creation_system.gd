class_name CharacterCreationSystem
extends GameSystem
## Creates the adventurer when Character Creation reports Accept.
##
## Subscribes to the scene's `accepted` signal through the Switchboard and asks
## the entity manager's factory to build the adventurer from the result, then
## equips the starting items and writes the save.


func _on_ready() -> void:
	Switchboard_auto.connect_subscriber(self, "accepted", _on_accepted)


func _exit_tree() -> void:
	if is_instance_valid(Switchboard_auto):
		Switchboard_auto.remove_from_waitlist("accepted", _on_accepted)


## result: {"skill", "stamina", "luck", "skill_dice", "stamina_dice", "luck_dice", "potion"}
## Creates the adventurer and its items, equips the items through the scene's
## FFEquipmentSystem, then writes the save through SaveSystem.
func _on_accepted(result: Dictionary) -> void:
	var manager := get_entity_manager() as FFEntityManager
	if manager == null:
		push_error("CharacterCreationSystem: no FFEntityManager on the engine.")
		return
	var equipment := get_system(&"FFEquipmentSystem") as FFEquipmentSystem
	if equipment == null:
		push_error("CharacterCreationSystem: the scene has no FFEquipmentSystem.")
		return

	var made: Dictionary = manager.create_adventurer(
			result["skill"], result["stamina"], result["luck"], result["potion"])
	var adventurer: Entity = made["adventurer"]
	for item: Entity in made["items"]:
		if not equipment.equip(StringName(adventurer.id), StringName(item.id)):
			push_error("CharacterCreationSystem: could not equip item %s." % item.id)

	var save := get_system(&"SaveSystem") as SaveSystem
	if save == null:
		push_error("CharacterCreationSystem: the scene has no SaveSystem.")
		return
	save.write()


func _on_initialize() -> void:
	pass


func handle_event(_event_name: String, _payload: Dictionary = {}) -> bool:
	return true


func _process_system(_delta: float) -> void:
	pass


func _on_cleanup() -> void:
	pass
