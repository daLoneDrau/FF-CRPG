class_name FFEquipmentSystem
extends EquipmentSystem
## Concrete equipment system for FF-CRPG. EquipmentSystem is abstract in the
## library. The game has no item requirements, set bonuses or slot restrictions
## beyond each item's own compatible slots.


func _on_initialize() -> void:
	_entity_manager = get_entity_manager()


func _slot_accepts_item(_entity_id: StringName, _slot: int, _item_id: StringName, _reasons: Array[String]) -> bool:
	return true


func _find_any_set_bonuses(_set_id: StringName) -> Array:
	return []


func _on_ready() -> void:
	pass


func handle_event(_event_name: String, _payload: Dictionary = {}) -> bool:
	return true


func _process_system(_delta: float) -> void:
	pass


func _on_cleanup() -> void:
	pass
