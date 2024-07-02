extends Node

@export var speed: float = 1

var enemy: Enemy
var sprite: AnimatedSprite2D
var input_vector

func _ready():
	enemy = get_parent()
	sprite = enemy.get_node("AnimatedSprite2D")


func _physics_process(delta: float) -> void:
	# Ignorar Game Over
	if GameManager.is_game_over : return
	
	# Calcula a direção
	var player_position = GameManager.player_position
	var difference = player_position - enemy.position
	input_vector = difference.normalized()
	rotate_sprite()
	
	# Movimento
	enemy.velocity = input_vector * speed * 100.0
	enemy.move_and_slide()
	
	
func rotate_sprite() -> void:
	# Girar sprite
	if input_vector.x > 0:
		sprite.flip_h = false
	elif input_vector.x < 0:
		sprite.flip_h = true
