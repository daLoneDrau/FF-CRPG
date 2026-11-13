class_name FFEquipmentComponent
extends EquipmentComponent
## Concrete equipment component. EquipmentComponent is abstract in the library.
## Slots map an EquipmentSlot value to the id of the equipped item entity.


func _init() -> void:
	super()
	allowed_slots.assign([
		EquipmentSlot.to_key(EquipmentSlot.Enum.MAIN_HAND),
		EquipmentSlot.to_key(EquipmentSlot.Enum.OFF_HAND),
		EquipmentSlot.to_key(EquipmentSlot.Enum.CHEST),
		EquipmentSlot.to_key(EquipmentSlot.Enum.BELT),
	])


func to_dict() -> Dictionary:
	var equipped := {}
	for slot: int in slots:
		equipped[str(slot)] = slots[slot]
	return {
		"key": get_class_name(),
		"enabled": enabled,
		"slots": equipped,
	}
