class_name SwordScript
extends EntityScript
## Script for the SWORD. On INITIALIZED it names the item and sets the equip_slots of the
## parent entity's ItemComponent, which is what the equipment system reads.

var _entity_manager: EntityManager


func on_attach(p_entity_id: StringName, p_entity_manager: EntityManager) -> void:
	super(p_entity_id, p_entity_manager)
	_entity_manager = p_entity_manager


func on_initialized(_ctx: Dictionary) -> Dictionary:
	var named := _entity_manager.get_component(entity_id, NameComponent) as NameComponent
	named.display_name = "SWORD"
	var item := _entity_manager.get_component(entity_id, ItemComponent) as ItemComponent
	item.item_name = "SWORD"
	item.equip_slots.assign([EquipmentSlot.Enum.MAIN_HAND])
	return {}
