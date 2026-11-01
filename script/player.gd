extends CharacterBody3D

@export var speed: float = 5.0
@export var gravity: float = 9.8

@onready var camera = $Camera3D
@onready var joystick = $"../MobileControls/Joystick"


func _ready():
	add_to_group("player")


func _physics_process(delta):
	var input_dir = joystick.direction

	# التحكم بالكيبورد أثناء التجربة
	if input_dir.length() < 0.1:
		input_dir = Input.get_vector(
			"move_left",
			"move_right",
			"move_forward",
			"move_backward"
		)

	# تحويل اتجاه العصاية لاتجاه الكاميرا
	var forward = -camera.global_transform.basis.z
	var right = camera.global_transform.basis.x

	forward.y = 0
	right.y = 0

	forward = forward.normalized()
	right = right.normalized()

	var direction = right * input_dir.x + forward * -input_dir.y
	direction = direction.normalized()

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	# الجاذبية
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	move_and_slide()
