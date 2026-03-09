extends CharacterBody3D


enum AnimDir {
	BACKWARDS,
	BACKWARDS_LEFT,
	BACKWARDS_RIGHT,
	FORWARD,
	FORWARD_LEFT,
	FORWARD_RIGHT,
	LEFT,
	RIGHT,
}


## because MOUSE_SENS is *100 for easier user adjustments
const _MOUSE_ADJ: float = 1000.0
## to adjust for less x-axis rotation
const _MOUSE_Y_ADJ: float = 2.0


@export_group("Camera")
@export_range(0.0, 100.0, 1.0) var MOUSE_SENS: float = 30
@export_range(-90.0, 0.0, 0.1, "radians_as_degrees") var MIN_CAM_ANGLE: float = -60.0
@export_range(0.0, 90.0, 0.1, "radians_as_degrees") var MAX_CAM_ANGLE: float = 30.0
@export_range(1.0, 100.0, 0.1) var LOCK_ON_MAX_DIST: float = 20.0

@export_group("Movement")
@export var move_speed: float = 8.0
@export var move_accelleration: float = 20.0
@export var model_rot_speed: float = 12.0
@export_range(-100, 0) var gravity_accel: float = -9.81
@export_range(0, 100) var jump_speed: float = 5.0

@export_group("Nodes")
@export var camera_controller: Node3D
@export var camera: Camera3D
@export var model: Node3D
@export var state_chart: StateChart
@export var anim_player: AnimationPlayer


@onready var _mouse_sens_y: float = MOUSE_SENS / _MOUSE_Y_ADJ
@onready var _mouse_sens_x: float = MOUSE_SENS
@onready var _last_move_dir:= Vector3.ZERO


var _mouse_motion: Vector2
var _raw_move_input: Vector2
var _last_y_velocity: float
var _model_general_dir: int

var is_locked_on: bool = false

var curr_animation: String = "Idle/Idle"


#func _process(_delta: float) -> void:
	#anim_player.play(curr_animation, 0.9)


#func _physics_process(_delta: float) -> void:
	#print(anim_player.current_animation)
	#print(velocity)


## updates the _mouse_motion and applies the mouse sensitivity
## to call on _unhandled_input
func _camera_unhandled_input(event: InputEvent) -> void:
	_mouse_motion.x = event.relative.x * _mouse_sens_x / _MOUSE_ADJ
	_mouse_motion.y = event.relative.y * _mouse_sens_y / _MOUSE_ADJ


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Problema! Funge smooth col trackpad, ma scatticchia col mouse				  #
# Testare che non sia perchè la camera si muove solo 1 volta per ogni frame	  #
# Testare che non ci sia bisogno di lerp di camera attaccata col ray-cast	  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
## moves the camera when unlocked;
## to call on _process.
func _camera_free_move_process(delta: float) -> void:
	camera_controller.rotation.y -= _mouse_motion.x * delta
	camera_controller.rotation.x -= _mouse_motion.y * delta
	## to reset _mouse_motion else it continues to apply => continues to move camera
	_mouse_motion = Vector2.ZERO
	camera_controller.rotation.x =\
			clampf(camera_controller.rotation.x, MIN_CAM_ANGLE, MAX_CAM_ANGLE)


# #
#	BACO! forse quando Vector3.UP e la look dir giacciono sulla stessa retta,
#	il minchia si stende per terra come se Vector3.FORWARD fosse invece la mia
#	normale
#
## moves the camera when locked on;
## to call on _process.
func _camera_locked_move_proces(global_target_pos: Vector3) -> void:
	# var cam_up_dir: Vector3 = (global_target_pos - camera_controller.global_basis.z)\
	# 							.normalized().rotated(Vector3.FORWARD, 90)
	camera_controller.look_at(global_target_pos, Vector3.UP)


## gets movement input;
## to call on _physics_process for Grounded state.
func get_move_input() -> void:
	_raw_move_input = Input.get_vector("move_left", "move_right", "move_forward", "move_backwards")
	_model_general_dir = get_model_general_direction()
	#if _raw_move_input != Vector2.ZERO:
		#print_anim_dir(_model_general_dir)


## chooses the right root-motion animation... direciton
## to call on _physics_process for Physics State Machine
func get_model_general_direction() -> int:
	## forward dir, the normal one
	var f_input_dir: Vector2 = _raw_move_input.normalized()
	## left dir, rotated by +90 degrees
	var l_input_dir: Vector2 = _raw_move_input.normalized().rotated(PI/2)
	
	var cam_dir_3: Vector3 = camera.basis.z
	cam_dir_3.y = 0
	cam_dir_3 = cam_dir_3.normalized()
	var cam_dir: Vector2 = Vector2(cam_dir_3.x, cam_dir_3.z)
	
	var f_dot_cam: float = f_input_dir.dot(cam_dir)
	var l_dot_cam: float = l_input_dir.dot(cam_dir)
	if f_dot_cam > cos(PI/8):
		return AnimDir.BACKWARDS
	elif f_dot_cam < cos(7*PI/8):
		return AnimDir.FORWARD
	else:
		## facing left relative to camera <=> l_dot_cam in lower half of graph
										##<=> l_dot_cam < cos(PI/2)
		if f_dot_cam > cos(3*PI/8):
			if l_dot_cam < cos(PI/2):
				return AnimDir.BACKWARDS_LEFT
			else:
				return AnimDir.BACKWARDS_RIGHT
		elif f_dot_cam > cos(5*PI/8):
			if l_dot_cam < cos(PI/2):
				return AnimDir.LEFT
			else:
				return AnimDir.RIGHT
		else:
			if l_dot_cam < cos(PI/2):
				return AnimDir.FORWARD_LEFT
			else:
				return AnimDir.FORWARD_RIGHT


#func print_anim_dir(anim_dir: int) -> void:
	#match anim_dir:
		#AnimDir.BACKWARDS:
			#print("BACKWARDS")
		#AnimDir.BACKWARDS_LEFT:
			#print("BACKWARDS_LEFT")
		#AnimDir.BACKWARDS_RIGHT:
			#print("BACKWARDS_RIGHT")
		#AnimDir.FORWARD:
			#print("FORWARD")
		#AnimDir.FORWARD_LEFT:
			#print("FORWARD_LEFT")
		#AnimDir.FORWARD_RIGHT:
			#print("FORWARD_RIGHT")
		#AnimDir.LEFT:
			#print("LEFT")
		#AnimDir.RIGHT:
			#print("RIGHT")


## moves the player;
## to call on _physics_process for Grounded state.
func move_physics_process(delta: float) -> void:
	## to move according to camera direction
	var camera_forward: Vector3 = camera.global_basis.z
	var camera_right: Vector3 = camera.global_basis.x
	## calculating direction
	var move_dir: Vector3\
			= (camera_forward * _raw_move_input.y) + (camera_right * _raw_move_input.x)
	_raw_move_input = Vector2.ZERO
	move_dir.y = 0.0
	move_dir = move_dir.normalized()
	## saving previous velocity.y to later account for gravity
	_last_y_velocity = velocity.y
	## resetting velocity.y to 0 to move horizontally without problems
	velocity.y = 0.0
	## applying direction and velocity
	velocity = velocity.move_toward(move_dir * move_speed, move_accelleration * delta)
	
	if move_dir.length() > 0.2:
		_last_move_dir = move_dir


###########################
## Physics state machine ##
###########################

### UnlockedCamMotion calls ###

func _on_unlocked_cam_motion_state_unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_camera_unhandled_input(event)


func _on_unlocked_cam_motion_state_processing(delta: float) -> void:
	if Input.is_action_just_pressed("lock_on"):
		is_locked_on = true
		state_chart.send_event("camera_is_locked")
	_camera_free_move_process(delta)


func _on_unlocked_cam_motion_state_physics_processing(delta: float) -> void:
	get_move_input()
	move_physics_process(delta)
	## calculating skin turning angle, adjusted to face forward
	var target_angle :=\
			Vector3.BACK.signed_angle_to(_last_move_dir, Vector3.UP) ## + deg_to_rad(-90)
	model.global_rotation.y = lerp_angle(model.rotation.y, target_angle, model_rot_speed * delta)
	## gravity
	velocity.y = _last_y_velocity + gravity_accel * delta
	move_and_slide()


### LockedCamMotion calls ###

func _on_locked_cam_motion_state_processing(_delta: float) -> void:
	if Input.is_action_just_pressed("lock_on"):
		is_locked_on = false
		state_chart.send_event("camera_is_unlocked")
	_camera_locked_move_proces(Vector3.ZERO)


func _on_locked_cam_motion_state_physics_processing(delta: float) -> void:
	get_move_input()
	move_physics_process(delta)
	model.look_at(Vector3.ZERO, Vector3.UP, true)
	## gravity
	velocity.y = _last_y_velocity + gravity_accel * delta
	move_and_slide()


##############################
## Animations state machine ##
##############################

### Idle calls ###

func _on_idle_state_processing(_delta: float) -> void:
	if velocity != Vector3.ZERO:
		state_chart.send_event("is_walking")
	curr_animation = "Idle/Idle"


### Walking calls ###

func _on_walking_state_processing(_delta: float) -> void:
	if velocity == Vector3.ZERO:
		state_chart.send_event("is_idle")
	if !is_locked_on:
		curr_animation = "Walk/Walk_Forward"
	else:
		match _model_general_dir:
			AnimDir.BACKWARDS:
				curr_animation = "Walk/Walk_Backwards"
			AnimDir.BACKWARDS_LEFT:
				curr_animation = "Walk/Walk_BackwardsLeft"
			AnimDir.BACKWARDS_RIGHT:
				curr_animation = "Walk/Walk_BackwardsRight"
			AnimDir.FORWARD:
				curr_animation = "Walk/Walk_Forward"
			AnimDir.FORWARD_LEFT:
				curr_animation = "Walk/Walk_ForwardLeft"
			AnimDir.FORWARD_RIGHT:
				curr_animation = "Walk/Walk_ForwardRight"
			AnimDir.LEFT:
				curr_animation = "Walk/Walk_Left"
			AnimDir.RIGHT:
				curr_animation = "Walk/Walk_Right"
