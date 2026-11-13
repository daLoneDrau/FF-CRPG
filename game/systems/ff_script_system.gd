class_name FFScriptSystem
extends ScriptSystem
## Concrete script system for FF-CRPG. ScriptSystem is abstract in the library.
##
## When an entity is added, the library's ScriptSystem attaches its scripts
## (on_attach). When add_entity_immediately() emits the INITIALIZED script event,
## it dispatches it to the entity's scripts (on_initialized).
## The game has no positions, so a radius check never matches.


func _on_initialize() -> void:
	_entity_manager = get_entity_manager()


func _within_radius(_a, _b, _radius: int) -> bool:
	return false


func _on_ready() -> void:
	pass


func handle_event(_event_name: String, _payload: Dictionary = {}) -> bool:
	return true


func _process_system(_delta: float) -> void:
	pass


func _on_cleanup() -> void:
	pass
