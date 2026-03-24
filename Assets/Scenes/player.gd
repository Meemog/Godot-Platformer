extends CharacterBody2D

enum Wall_State {None, Left, Right}

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
@export var cut_jump_mult: float = 0.45

@export_category("Wall Jump")
@export var w_jump_vector: Vector2 = Vector2(1.5, -1)
@export var w_jump_force: float = 700
@export var wall_slip_speed = 100

var current_horizontal_scalar: float = 0

# Jump Timers
var time_since_grounded: float
var time_since_jump_input: float
var time_since_last_jump: float

# Wall Jump
var w_jump_vector_normal: Vector2
var wall_state: Wall_State

var tps_adjustment: float

func _ready() -> void:
    time_since_grounded = coyote_time
    time_since_jump_input = jump_remember_time
    time_since_last_jump = jump_delay

    w_jump_vector_normal = w_jump_vector.normalized()
    wall_state = Wall_State.None
    
    $AnimationPivot/AnimatedSprite2D.play("Idle")


func _physics_process(delta: float) -> void:
    tps_adjustment = Engine.physics_ticks_per_second * delta
    
    process_horizontal()
    
    process_jump(delta)
    
    process_walls()
    
    process_gravity()
    
    move_and_slide()

func _process(delta: float) -> void:
    if velocity.x == 0 or time_since_grounded > 0.2:
        $AnimationPivot/AnimatedSprite2D.play("Idle")
    else:
        $AnimationPivot/AnimatedSprite2D.play("Walk")
        
    if current_horizontal_scalar == 1:
        $AnimationPivot.scale.x = 1
    elif current_horizontal_scalar == -1:
        $AnimationPivot.scale.x = -1

func process_horizontal() -> void:
    var horizontal_scalar = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
    current_horizontal_scalar = horizontal_scalar
    
    var sign = velocity.x / abs(velocity.x)
    
    # Stop acceleration past soft speed cap
    if horizontal_scalar == sign and abs(velocity.x) > soft_max_velocity:
        horizontal_scalar = 0
    
    # If a movememnt key is pressed, apply acceleration
    if horizontal_scalar != 0:
        velocity.x += horizontal_scalar * acceleration * tps_adjustment
    # Otherwise apply dampening
    elif velocity.x != 0:
        var current_vel = abs(velocity.x)
        current_vel -= horizontal_dampening * tps_adjustment
        if current_vel < 0:
            current_vel = 0
        velocity.x = current_vel * sign
    
    # Prevent velocity from exceeding max velocity
    if abs(velocity.x) > hard_max_velocity:
        velocity.x = hard_max_velocity * sign
    

func process_walls():
    # Doesn't account for if the player is on 2 walls at once
    if ($WallLeft.get_overlapping_bodies().size() > 0):
        wall_state = Wall_State.Left
    elif ($WallRight.get_overlapping_bodies().size() > 0):
        wall_state = Wall_State.Right
    else:
        wall_state = Wall_State.None

func process_jump(delta: float) -> void:
    time_since_grounded += delta
    time_since_jump_input += delta
    time_since_last_jump += delta
    
    if $Grounded.get_overlapping_bodies().size() > 0:
        time_since_grounded = 0
    
    if time_since_jump_input < jump_remember_time and time_since_last_jump > jump_delay:
        if time_since_grounded < coyote_time:
            jump()
        elif wall_state != Wall_State.None:
            wall_jump()
        
func jump() -> void:
    velocity.y = -jump_force
    time_since_last_jump = 0

func wall_jump() -> void:
    velocity = w_jump_force * w_jump_vector_normal
    if wall_state == Wall_State.Right:
        velocity.x *= -1
        
    time_since_last_jump = 0

func process_gravity() -> void:
    if wall_state != Wall_State.None and velocity.y > wall_slip_speed and current_horizontal_scalar != 0:
        velocity.y = wall_slip_speed
    else:
        velocity.y += gravity * tps_adjustment

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("jump"):
        time_since_jump_input = 0
    if event.is_action_released("jump"):
        if velocity.y < 0:
            velocity.y *= cut_jump_mult
