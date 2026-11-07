extends Area3D

signal activated(interaction_id: String)

@export var interaction_id := ""
@export var prompt := "INTERAGISCI"

func activate() -> void:
	activated.emit(interaction_id)
