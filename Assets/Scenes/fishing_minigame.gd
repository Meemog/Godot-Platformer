extends Node2D
## Script containing the functionality of the fishing minigame

@export var delay_time: float = 3 ## Time before game closes after it ends

enum Fish_State {Lost, Won, Ongoing, Idle}
signal game_completed(won: bool) ## Emitted when the game is finished with a boolean of if the player won or not

var _drain_speed: float ## Speed at which the fishing bar decreases
var _fish_power: float ## Step at which fishing bar increases
var _bar: Node2D ## Reference to anchor point for the internal bar

var _game_state: Fish_State = Fish_State.Idle ## Current state of the game
var _time_since_state_change: float = 0 ## Timer for hiding the sprite at the end of the game

func _ready() -> void:
    _bar = $BarAnchor
    visible = false

## Sets attribues to default state and starts the game
func start(drain_speed: float = 0.005, start_position: float = 0.3, fish_power: float = 0.15) -> void:
    if _game_state == Fish_State.Idle: # Cannot restart while game is active
        _drain_speed = drain_speed
        _fish_power = fish_power
        _bar.scale.y = start_position
        _game_state = Fish_State.Ongoing
        _time_since_state_change = 0
        
        visible = true

## Stops the game early if needed
func stop() -> void:
    if _game_state != Fish_State.Idle:
        _game_state = Fish_State.Idle
        visible = false
    
func _process(delta: float) -> void:
    if _game_state == Fish_State.Ongoing:
        _game_state = change_progress(-_drain_speed) # Lower the bar fill by the drain speed
        if _game_state == Fish_State.Lost:
            game_completed.emit(true) 
    if _game_state == Fish_State.Lost or _game_state == Fish_State.Won: # Increase timer if game has just ended
        _time_since_state_change += delta
        if _time_since_state_change > delay_time:
            _game_state = Fish_State.Idle
            visible = false

## Increases fishing bar by the fishing power
func process_fish_input() -> void:
    if _game_state != Fish_State.Ongoing:
        return
    _game_state = change_progress(_fish_power) # Fill the bar by the fishing power
    if _game_state == Fish_State.Won:
        game_completed.emit(false)

## Changes the progress of the bar by a relative modifier
func change_progress(modifier: float) -> Fish_State:
    var temp_scale: float = _bar.scale.y
    var state: Fish_State = Fish_State.Ongoing
    
    temp_scale += modifier
    
    if temp_scale < 0:
        temp_scale = 0
        state = Fish_State.Lost
    if temp_scale > 1:
        temp_scale = 1
        state = Fish_State.Won
    
    _bar.scale.y = temp_scale # Change scale in one step
    return state

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("fish"):
        process_fish_input()
