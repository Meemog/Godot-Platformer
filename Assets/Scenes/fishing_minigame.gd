extends Node2D

enum Fish_State {Lost, Won, Ongoing, Idle}
signal game_completed(won: bool)

@export var delay_time: float = 3

var _drain_speed: float
var _fish_power: float
var _game_state = Fish_State.Idle
var _bar: Node2D
var _sprite: Node2D

var _time_since_state_change = 0

func _ready() -> void:
    _bar = $BarAnchor
    
    visible = false
    
func start(drain_speed: float = 0.005, start_position: float = 0.3, fish_power: float = 0.15):
    if _game_state == Fish_State.Idle:
        _drain_speed = drain_speed
        _fish_power = fish_power
        _bar.scale.y = start_position
        _game_state = Fish_State.Ongoing
        _time_since_state_change = 0
        
        visible = true
    
func _process(delta: float) -> void:
    if _game_state == Fish_State.Ongoing:
        _game_state = change_progress(-_drain_speed)
        if _game_state == Fish_State.Lost:
            game_completed.emit(true)
    if _game_state == Fish_State.Lost or _game_state == Fish_State.Won:
        _time_since_state_change += delta
        if _time_since_state_change > delay_time:
            _game_state = Fish_State.Idle
            visible = false
            
func process_fish() -> void:
    if _game_state != Fish_State.Ongoing:
        return
    _game_state = change_progress(_fish_power)
    if _game_state == Fish_State.Won:
        game_completed.emit(false)

func change_progress(modifier: float) -> Fish_State:
    var scale: float = _bar.scale.y
    var state: Fish_State = Fish_State.Ongoing
    
    scale += modifier
    
    if scale < 0:
        scale = 0
        state = Fish_State.Lost
    if scale > 1:
        scale = 1
        state = Fish_State.Won
    
    _bar.scale.y = scale
    return state
    

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("fish"):
        process_fish()
