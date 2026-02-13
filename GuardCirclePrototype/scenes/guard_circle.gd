extends Sprite2D


const LINE_LENGTH: int = 9999


@export_group("Arrows")
@export var left_line: Line2D
@export var right_line: Line2D
@export var down_line: Line2D
@export var mouse_line: Line2D

@export_group("GuardUI")
@export var up_guard_button: Button
@export var left_guard_button: Button
@export var right_guard_button: Button

@export_group("StateMachine")
@export var state_machine: StateChart

@export_group("Attributes")
@export_range(150, 1050, 1) var THRESHOLD: float


var sum_mouse_motion = Vector2.ZERO
var mouse_coords = Vector2.ZERO

var left_vec = Vector2(1*cos(7*PI/6), 1*sin(7*PI/6))
var right_vec = Vector2(1*cos(11*PI/6), 1*sin(11*PI/6))
var down_vec = Vector2(1*cos(PI/2), 1*sin(PI/2))

var dot_left: float
var dot_right: float
var dot_down: float

var current_guard: int


func _enter_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)


func _ready() -> void:
	left_line.add_point(Vector2(LINE_LENGTH*cos(7*PI/6), LINE_LENGTH*sin(7*PI/6)), 1)
	right_line.add_point(Vector2(LINE_LENGTH*cos(11*PI/6), LINE_LENGTH*sin(11*PI/6)), 1)
	down_line.add_point(Vector2(LINE_LENGTH*cos(PI/2), LINE_LENGTH*sin(PI/2)), 1)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Pause"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	###############################################
	## handling mouse input for the guard circle ##
	###############################################
	## if temp ("instantaneous relative mouse motion")
	##		exceeds threshold alone or with previous sum:
	##	=> main segment so it's assigned to mouse_coords
	## else accumulated in the sum and we wait for next cicle
	if event is InputEventMouseMotion:
		var temp = Vector2(event.relative.x, event.relative.y)
		if temp.length() > THRESHOLD || (sum_mouse_motion + temp).length() > THRESHOLD:
			mouse_coords = LINE_LENGTH * temp
			sum_mouse_motion = Vector2.ZERO
		else:
			sum_mouse_motion += temp

 
func _process(_delta: float) -> void:
	mouse_line.set_point_position(1, mouse_coords)
	
	dot_left = mouse_coords.normalized().dot(left_vec)
	dot_right = mouse_coords.normalized().dot(right_vec)
	dot_down = mouse_coords.normalized().dot(down_vec)


func is_guarding_up() -> bool:
	return dot_left > cos(15*PI/24) && dot_right > cos(15*PI/24)

func is_guarding_left() -> bool:
	return dot_left > cos(15*PI/24) && dot_down > cos(15*PI/24)

func is_guarding_right() -> bool:
	return dot_right > cos(15*PI/24) && dot_down > cos(15*PI/24)


func _on_up_guard_state_processing(_delta: float) -> void:
	up_guard_button.show()
	if is_guarding_left():
		up_guard_button.hide()
		state_machine.send_event("left_guard")
	if is_guarding_right():
		up_guard_button.hide()
		state_machine.send_event("right_guard")


func _on_left_guard_state_processing(delta: float) -> void:
	left_guard_button.show()
	## guard up
	if is_guarding_up():
		left_guard_button.hide()
		state_machine.send_event("up_guard")
	## guard right
	if is_guarding_right():
		left_guard_button.hide()
		state_machine.send_event("right_guard")


func _on_right_guard_state_processing(delta: float) -> void:
	right_guard_button.show()
	if is_guarding_up():
		right_guard_button.hide()
		state_machine.send_event("up_guard")
	if is_guarding_left():
		right_guard_button.hide()
		state_machine.send_event("left_guard")
