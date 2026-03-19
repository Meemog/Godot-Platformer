extends CharacterBody2D

@export_category("Horizontal Movement")
@export var soft_max_velocity: float = 300
@export var hard_max_velocity: float = 600
@export var acceleration: float = 50
@export var horizontal_dampening = 20

@export_category("Vertical Movement")
@export var gravity: float = 25
@export var jump_force: float = 500

var grounded: bool = false

func _physics_process(delta: float) -> void:
    grounded = $Grounded.get_overlapping_bodies().size() > 0
    
    process_horizontal()
    
    velocity.y += gravity
    
    move_and_slide()

func process_horizontal() -> void:
    var horizontal_scalar = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
    var sign = velocity.x / abs(velocity.x)
    
    # Stop acceleration past soft speed cap
    if horizontal_scalar == sign and abs(velocity.x) > soft_max_velocity:
        horizontal_scalar = 0
    
    # If a movememnt key is pressed, apply acceleration
    if horizontal_scalar != 0:
        velocity.x += horizontal_scalar * acceleration
    # Otherwise apply dampening
    elif velocity.x != 0:
        var current_vel = abs(velocity.x)
        current_vel -= horizontal_dampening
        if current_vel < 0:
            current_vel = 0
        velocity.x = current_vel * sign
    
    # Prevent velocity from exceeding max velocity
    if abs(velocity.x) > hard_max_velocity:
        velocity.x = hard_max_velocity * sign

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("jump") and grounded:
        velocity.y = -jump_force
