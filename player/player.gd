class_name Player
extends CharacterBody2D

@export_category("Movement")
@export var speed: float = 3
@export_category("Sword")
@export var sword_damage: int = 2
@export_category("Ritual")
@export var ritual_damage: int = 1
@export var ritual_interval: float = 30
@export var ritual_scene: PackedScene
@export_category("Life")
@export var health: int = 50
@export var max_health: int = 100
@export var death_prefeb: PackedScene

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sword_area: Area2D = $SwordArea
@onready var hitbox_area: Area2D = $HitBoxArea
@onready var health_progress_bar: ProgressBar = $HealthProgressBar

var input_vector: Vector2 = Vector2(0, 0)
var is_running: bool = false
var was_running: bool = false
var lerp_factor:float = 0.05
var is_attacking: bool = false
var attack_cooldown: float = 0.0
var hitbox_cooldown: float = 0.0
var ritual_cooldown: float = 0.0

signal meat_collected(value: int)


func _ready():
	GameManager.player = self
	meat_collected.connect(func(value: int):
		GameManager.meat_counter += 1
	)


func _process(delta: float) -> void:
	GameManager.player_position = position
	# Ler input
	read_input()
	
	# Processar attack
	update_attack_cooldown(delta)
	if Input.is_action_just_pressed("attack"):
		attack()

	#Processar animação  rotação do sprite
	play_run_idle_aimation()
	if not is_attacking:
		rotate_sprite()
	
	# Processar dano
	update_hitbox_detection(delta)
	
	# Ritual
	update_ritual(delta)
	
	# Atualizar Health Bar
	health_progress_bar.max_value = max_health
	health_progress_bar.value = health


func _physics_process(delta: float) -> void:
	# Modificar velocidade
	var target_velocity = input_vector * speed * 100.0
	if is_attacking:
		target_velocity *= 0.25
		
	# Cria uma suavidade na movimentação
	velocity = lerp(velocity, target_velocity, lerp_factor)
	move_and_slide()


func read_input() -> void:
	# Obter o input_vector
	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Apagar dead_zone do input_vector
	var dead_zone = 0.15
	if abs(input_vector.x) < 0.15:
		input_vector.x = 0.0
	if abs(input_vector.y) < 0.15:
		input_vector.y = 0.0
	
	# Atualizar is_running
	was_running = is_running
	is_running = not input_vector.is_zero_approx()


func update_attack_cooldown(delta: float) -> void:
		# Atualiza temporizador do attack
	if is_attacking:
		attack_cooldown -= delta
		if attack_cooldown <= 0.0:
			is_attacking = false
			is_running = false
			animation_player.play("idle")


func update_ritual(delta: float) -> void:
	# Atualizar temporizador
	ritual_cooldown -= delta
	if ritual_cooldown > 0: return
	
	# Resetar temporizador
	ritual_cooldown = ritual_interval
	
	# Criar ritual
	var ritual = ritual_scene.instantiate()
	ritual.damage_amount = ritual_damage
	# Definir ritual para andar junto do Player
	add_child(ritual)


func  play_run_idle_aimation() -> void:
	# Trocar animação
	if not is_attacking:
		if was_running != is_running:
			if is_running:
				animation_player.play("run")
			else:
				animation_player.play("idle")


func rotate_sprite() -> void:
	# Girar sprite
	if input_vector.x > 0:
		sprite.flip_h = false
	elif input_vector.x < 0:
		sprite.flip_h = true


func attack() -> void:
	# Attack_side_1
	if is_attacking:
		return

	# Trocar animação
	animation_player.play("attack_side_1")
	
	# Configura temporizador
	attack_cooldown = 0.6
	
	# Marcar ataque
	is_attacking = true
	
	# Aplicar dano aos inimigos
	#deal_damage_to_enemies()


func deal_damage_to_enemies() -> void:
	var bodies = sword_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies"):
			var enemy: Enemy = body
			# Chamar a função "damage", com "sword_damage" como primeiro parâmetro
			
			var direction_to_enemy = (enemy.position - position).normalized()
			var attack_direction: Vector2
			if sprite.flip_h:
				attack_direction = Vector2.LEFT
			else:
				attack_direction = Vector2.RIGHT
			
			var dot_product = direction_to_enemy.dot(attack_direction)
			if dot_product >= 0.3:
				enemy.damage(sword_damage)
			
			#print("Dot: ", dot_product)		

	# Acessar todos os inimigos
	#var enemies = get_tree().get_nodes_in_group("enemies")


func update_hitbox_detection(delta: float) -> void:
	# Temporizador
	hitbox_cooldown -= delta
	if hitbox_cooldown > 0: return
	
	# Frequencia
	hitbox_cooldown = 0.5
	
	# Detectar inimigos
	var bodies = hitbox_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies"):
			var enemy: Enemy = body
			var damage_amount = 1
			damage(damage_amount)


func damage(amount: int) -> void:
	if health <= 0: return
	
	health -= amount
	print("Player recebeu dano de: ", amount, "A vida total é de:", health, "/", max_health)
	
	# Piscar o inimigo ao eceber dano
	modulate = Color.RED
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	
	# Processar morte
	if health <= 0:
		die()


func die() -> void:
	GameManager.end_game()
	
	if death_prefeb:
		var death_object = death_prefeb.instantiate()
		death_object.position = position
		get_parent().add_child(death_object)
	
	
	print("Player morreu")
	# Função pra destroir qualquer coisa no Godot
	queue_free()


func heal(amount: int) -> int:
	health += amount
	if health > max_health:
		health = max_health
	print("Player recebeu cura de: ", amount, "A vida total é de:", health, "/", max_health)
	return health
