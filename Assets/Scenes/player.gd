extends CharacterBody2D

@export_category("Horizontal Movement")
@export var soft_max_velocity: float = 300
@export var hard_max_velocity: float = 600
@export var acceleration: float = 50
@export var horizontal_dampening = 20

@export_category("Vertical Movement")
@export var gravity: float = 25
@export var jump_force: float = 500
@export var jump_remember_time: float = 0.15
@export var coyote_time: float = 0.2
@export var jump_delay: float = 0.2

var time_since_grounded: float = coyote_time
var time_since_jump_input: float = jump_remember_time
var time_since_last_jump: float = jump_delay

func _physics_process(delta: float) -> void:
    
    process_horizontal()
    
    process_jump(delta)
    
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

func process_jump(delta: float) -> void:
    time_since_grounded += delta
    time_since_jump_input += delta
    time_since_last_jump += delta
    
    if $Grounded.get_overlapping_bodies().size() > 0:
        time_since_grounded = 0
    
    if time_since_jump_input < jump_remember_time and time_since_grounded < coyote_time and time_since_last_jump > jump_delay:
        jump()
        
func jump() -> void:
    velocity.y = -jump_force
    time_since_last_jump = 0

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("jump"):
        time_since_jump_input = 0
