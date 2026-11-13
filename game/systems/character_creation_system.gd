class_name CharacterCreationSystem
extends GameSystem
## Creates the adventurer when Character Creation reports Accept.
##
## Subscribes to the scene's `accepted` signal through the Switchboard and asks
## the entity manager's factory to build the adventurer from the result.


func _on_ready() -> void:
	Switchboard_auto.connect_subscriber(self, "accepted", _on_accepted)


func _exit_tree() -> void:
	if is_instance_valid(Switchboard_auto):
		Switchboard_auto.remove_from_waitlist("accepted", _on_accepted)


## result: {"skill", "stamina", "luck", "skill_dice", "stamina_dice", "luck_dice", "potion"}
func _on_accepted(result: Dictionary) -> void:
	var manager := get_entity_manager() as FFEntityManager
	if manager == null:
		push_error("CharacterCreationSystem: no FFEntityManager on the engine.")
		return
	manager.create_adventurer(
			result["skill"], 
			result["stamina"], 
			result["luck"], 
			result["potion"]
	)


func _on_initialize() -> void:
	pass


func handle_event(_event_name: String, _payload: Dictionary = {}) -> bool:
	return true


func _process_system(_delta: float) -> void:
	pass


func _on_cleanup() -> void:
	pass