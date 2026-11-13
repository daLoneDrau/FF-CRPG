class_name ShieldScript
extends EntityScript
## Script for the SHIELD. On INITIALIZED it names the item and sets the equip_slots of the
## parent entity's ItemComponent, which is what the equipment system reads.

var _entity_manager: EntityManager


func on_attach(p_entity_id: StringName, p_entity_manager: EntityManager) -> void:
	super(p_entity_id, p_entity_manager)
	_entity_manager = p_entity_manager


func on_initialized(_ctx: Dictionary) -> Dictionary:
	var named := _entity_manager.get_component(entity_id, NameComponent) as NameComponent
	named.display_name = "SHIELD"
	var item := _entity_manager.get_component(entity_id, ItemComponent) as ItemComponent
	item.item_name = "SHIELD"
	item.equip_slots.assign([EquipmentSlot.Enum.OFF_HAND])
	return {}
