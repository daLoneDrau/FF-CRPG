class_name FFItemComponent
extends ItemComponent
## Concrete item component. ItemComponent is abstract in the library.


func to_dict() -> Dictionary:
	return {
		"key": get_class_name(),
		"enabled": enabled,
		"item_name": item_name,
		"equip_slots": equip_slots.duplicate(),
	}
