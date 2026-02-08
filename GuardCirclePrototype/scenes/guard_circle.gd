extends Sprite2D


const ARROW_LENGTH: int = 9999


@export_group("Arrows")
@export var up_arrow: Line2D
@export var left_arrow: Line2D
@export var right_arrow: Line2D
@export var mouse_arrow: Line2D

@export_group("Attributes")
@export_range(150, 1050, 1) var THRESHOLD: float


var sum_mouse_motion = Vector2.ZERO
var mouse_coords = Vector2.ZERO


func _enter_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)


func _ready() -> void:
	up_arrow.add_point(Vector2(ARROW_LENGTH*cos(PI/2), ARROW_LENGTH*sin(PI/2)), 1)
	left_arrow.add_point(Vector2(ARROW_LENGTH*cos(7*PI/6), ARROW_LENGTH*sin(7*PI/6)), 1)
	right_arrow.add_point(Vector2(ARROW_LENGTH*cos(11*PI/6), ARROW_LENGTH*sin(11*PI/6)), 1)


func _unhandled_input(event: InputEvent) -> void:
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
			mouse_coords = ARROW_LENGTH * temp
			sum_mouse_motion = Vector2.ZERO
		else:
			sum_mouse_motion += temp


func _process(_delta: float) -> void:
	mouse_arrow.set_point_position(1, mouse_coords)
