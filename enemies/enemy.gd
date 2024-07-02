class_name Enemy
extends Node2D

@export_category("Life")
@export var health: int = 10
@export var death_prefeb: PackedScene
var damage_digit_prefeb: PackedScene

@onready var damage_digit_marker = $DamageDigitMarker

@export_category("Drops")
@export var drop_change: float = 0.1
@export var drop_items: Array[PackedScene]
@export var drop_changes: Array[float]


func _ready():
	damage_digit_prefeb = preload("res://misc/damage_digit.tscn")


func damage(amount: int) -> void:
	health -= amount
	print("Inimigo recebeu dano de: ", amount, "A vida total é de:", health)
	
	# Piscar o inimigo ao eceber dano
	modulate = Color.RED
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	
	# Criar damage hit	
	var damage_digit = damage_digit_prefeb.instantiate()
	damage_digit.value = amount
	if damage_digit_marker:
		damage_digit.global_position = damage_digit_marker.global_position
	else:
		damage_digit.global_position = global_position
	get_parent().add_child(damage_digit)
	
	# Processar morte
	if health <= 0:
		die()


func die() -> void:
	if death_prefeb:
		var death_object = death_prefeb.instantiate()
		death_object.position = position
		get_parent().add_child(death_object)
	
	# Drop
	# @export var drop_change: float = 0.1	
	if randf() <= drop_change:
		drop_item()
	
	# Incrementar contador
	GameManager.monsters_defeated_counter += 1
	
	# Função pra destroir qualquer coisa no Godot	
	queue_free()


func drop_item() -> void:
	var drop = get_random_drop_item().instantiate()
	drop.position = position
	get_parent().add_child(drop)


func get_random_drop_item() -> PackedScene:
	if drop_items.size() == 1:
		return drop_items[0]
	
	# Calcular change máxima
	var max_change: float = 0.0
	for drop_change in drop_changes:
		max_change += drop_change
	
	# Jogar dado
	var random_value = randf() * max_change
	
	# Girar roleta
	var needle: float = 0.0
	for i in drop_items.size():
		var drop_item = drop_items[i]
		var drop_change = drop_changes[i] if i < drop_changes.size() else 1
		if random_value <= drop_change + needle:
			return drop_item
		needle += drop_change
	
	return drop_items[0]
