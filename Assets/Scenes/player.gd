extends CharacterBody2D
## Script determining the behaviours of the player

enum Wall_State {None, Left, Right}

@export_category("Horizontal Movement")
@export var soft_max_velocity: float = 300 ## Horizontal velocity at which accelleration will no longer apply.
@export var hard_max_velocity: float = 600 ## Horizontal velocity that player cannot exceed.
@export var acceleration: float = 50 ## Step at which velocity is increased each tick while accelerating.
@export var horizontal_dampening = 20 ## Step at which velocity is decreased each tick when not accelerating.

@export_category("Vertical Movement")
@export var gravity: float = 25 ## Step at which vertical velocity is increased each tick.
@export var jump_force: float = 500 ## Vertical velocity player is set to on jump.
@export var jump_buffer_time: float = 0.15 ## Time in seconds that a jump input is buffered if the player is not currently grounded when pressed.
@export var coyote_time: float = 0.2 ## Time in seconds that the player remembers being grounded for after leaving ledge.
@export var jump_delay: float = 0.2 ## Minimum time in seconds between jumps
@export var cut_jump_mult: float = 0.45 ## Multiplier applied to upward velocity after jump key is released

@export_category("Wall Jump")
@export var w_jump_vector: Vector2 = Vector2(1.5, -1) ## Vector descriping the direction of a wall jump
@export var w_jump_force: float = 700 ## Multiplier that is applied to the normalized [constant w_jump_vector]
@export var wall_slip_speed = 100 ## Vertical velocity the player moves at while moving into a wall

var _current_horizontal_scalar: float = 0 ## Value between -1 and 1 storing current horizontal input data

# Jump Timers
var _time_since_grounded: float ## Time in seconds since player was grounded
var _time_since_jump_input: float ## Time in seconds since jump input was pressed
var _time_since_last_jump: float ## Time in seconds since player jumped

# Wall Jump
var _w_jump_vector_normal: Vector2 ## Normalised wall jump direction vector
var _wall_state: Wall_State ## Stores which side of the player is touching a wall if any

# Misc Physics
var _tps_adjustment: float ## Physics adjustment to ensure forces are calculated correctly when physics ticks are inconsistant

# Children
var _sprite: AnimatedSprite2D ## Sprite of the player
var _sprite_pivot: Node2D ## Pivot point of the player sprite
var _area_grounded: Area2D ## Area used to check if the player is grounded
var _area_wall_left: Area2D ## Area used to check if the player is touching a wall to their left
var _area_wall_right: Area2D ## Area used to check if the player is touching a wall to their left

func _ready() -> void:
    _time_since_grounded = coyote_time
    _time_since_jump_input = jump_buffer_time
    _time_since_last_jump = jump_delay

    _w_jump_vector_normal = w_jump_vector.normalized()
    _wall_state = Wall_State.None
    
    _sprite = $AnimationPivot/AnimatedSprite2D
    _sprite_pivot = $AnimationPivot
    _area_grounded = $Grounded
    _area_wall_left = $WallLeft
    _area_wall_right = $WallRight
    
    _sprite.play("Idle")


func _physics_process(delta: float) -> void:
    _tps_adjustment = Engine.physics_ticks_per_second * delta
    
    process_horizontal()
    
    process_jump(delta)
    
    process_walls()
    
    process_gravity()
    
    move_and_slide()

func _process(_delta: float) -> void:
    if velocity.x == 0 or _time_since_grounded > 0.2:
        _sprite.play("Idle")
    else:
        _sprite.play("Walk")
        
    if _current_horizontal_scalar == 1:
        _sprite_pivot.scale.x = 1
    elif _current_horizontal_scalar == -1:
        _sprite_pivot.scale.x = -1
        
## Called on each [method Node._physics_process] and determines what the horizontal velocity of the player should be
func process_horizontal() -> void:
    var horizontal_scalar = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
    _current_horizontal_scalar = horizontal_scalar
    
    var direction = velocity.x / abs(velocity.x)
    
    # Stop acceleration past soft speed cap
    if horizontal_scalar == sign and abs(velocity.x) > soft_max_velocity:
        horizontal_scalar = 0
    
    # If a movememnt key is pressed, apply acceleration
    if horizontal_scalar != 0:
        velocity.x += horizontal_scalar * acceleration * _tps_adjustment
    # Otherwise apply dampening
    elif velocity.x != 0:
        var current_vel = abs(velocity.x)
        current_vel -= horizontal_dampening * _tps_adjustment
        if current_vel < 0:
            current_vel = 0
        velocity.x = current_vel * sign
    
    # Prevent velocity from exceeding max velocity
    if abs(velocity.x) > hard_max_velocity:
        velocity.x = hard_max_velocity * direction
    
## Called on each [method Node._physics_process] and determines what walls the player is currently on if any
func process_walls():
    # Doesn't account for if the player is on 2 walls at once
    if (_area_wall_left.get_overlapping_bodies().size() > 0):
        _wall_state = Wall_State.Left
    elif (_area_wall_right.get_overlapping_bodies().size() > 0):
        _wall_state = Wall_State.Right
    else:
        _wall_state = Wall_State.None

## Called on each [method Node._physics_process] and checks if the player should be jumping this physics tick
func process_jump(delta: float) -> void:
    _time_since_grounded += delta
    _time_since_jump_input += delta
    _time_since_last_jump += delta
    
    if _area_grounded.get_overlapping_bodies().size() > 0:
        _time_since_grounded = 0
    
    if _time_since_jump_input < jump_buffer_time and _time_since_last_jump > jump_delay:
        if _time_since_grounded < coyote_time:
            jump()
        elif _wall_state != Wall_State.None:
            wall_jump()

## Causes the player to jump
func jump() -> void:
    velocity.y = -jump_force
    _time_since_last_jump = 0

## Causes the player to wall jump
func wall_jump() -> void:
    velocity = w_jump_force * _w_jump_vector_normal
    if _wall_state == Wall_State.Right:
        velocity.x *= -1
        
    _time_since_last_jump = 0
    
## Called on each [method Node._physics_process] and applies acceleration via gravity if applicable
func process_gravity() -> void:
    if _wall_state != Wall_State.None and velocity.y > wall_slip_speed and _current_horizontal_scalar != 0:
        velocity.y = wall_slip_speed
    else:
        velocity.y += gravity * _tps_adjustment

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("jump"):
        _time_since_jump_input = 0
    if event.is_action_released("jump"):
        if velocity.y < 0:
            velocity.y *= cut_jump_mult
