extends Node

func packed_load(packed: PackedScene) -> void:
	var instance: Node = packed.instantiate()

	add_child(instance)

	instance.owner = self
	instance.unique_name_in_owner = true