extends KinematicBody

export(NodePath) onready var turret = $Turret

var velocity = Vector3.ZERO
var speed = 20
var ground_acc = 5.0
var air_acc = 1

var jump_power = 30

var puppet_position = Vector3()
var puppet_velocity = Vector3()
var puppet_rotaion = Vector3()

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$Turret/Camera.current = is_network_master()
	
func _physics_process(delta):
	if is_network_master():
		print("ye")
		var movement = _get_movement()
		var _acc = ground_acc
	
		if is_on_floor():
			print("ye2")
			_acc = ground_acc
		else:
			print("ye3")
			_acc = air_acc
		
		velocity.x = lerp(velocity.x, movement.x * speed, _acc * delta)
		velocity.z = lerp(velocity.z, movement.z * speed, _acc * delta)
		velocity.y += Globals.gravity * delta
		print('g')
	else:
		global_transform.origin = puppet_position
		velocity.x = puppet_velocity.x
		velocity.z = puppet_velocity.z
		velocity.y = puppet_velocity.y
		$Turret.rotation.x = puppet_rotaion.x
		
	velocity = move_and_slide(velocity, Vector3.UP)
		
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		_handle_camera_rotation(event)
		
func _handle_camera_rotation(event):
	if Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		rotate_y(deg2rad(-event.relative.x) * Globals.camera_sensitivity)
		$Turret.rotate_x(deg2rad(-event.relative.y) * Globals.camera_sensitivity)
		$Turret.rotation.x = clamp($Turret.rotation.x, deg2rad(Globals.MIN_CAMERA_ANGLE), deg2rad(Globals.MAX_CAMERA_ANGLE))
		
func _get_movement():
	var dir = Vector3.DOWN
	
	if Input.is_action_pressed("forward"):
		print("f")
		dir -= transform.basis.z
	if Input.is_action_pressed("backward"):
		dir += transform.basis.z
	if Input.is_action_pressed("left"):
		dir -= transform.basis.x
	if Input.is_action_pressed("right"):
		dir += transform.basis.x
		
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_power
		
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			
	return dir.normalized()

puppet func update_state(p_pos, p_vel, p_rot):
	puppet_position = p_pos
	puppet_velocity = p_vel
	puppet_rotaion = p_rot
	$Tween.interpolate_property(self, "global_transform", global_transform.origin, velocity, Vector2($Turret.rotation.x, rotation.y))
	$Tween.start()
	
func _on_network_timer_timeout():
	if is_network_master() and name == str(get_tree().get_network_unique_id()):
		rpc_unreliable("update_state", global_transform.origin, velocity, Vector2($Turret.rotation.x, rotation.y))
