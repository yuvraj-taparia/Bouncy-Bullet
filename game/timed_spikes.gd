extends Area2D

signal player_touched(body: Node2D)

const CYCLE := 3.0
const WARNING_START := 1.45
const ACTIVE_START := 2.05

@export_range(0.0, 2.99) var cycle_offset := 0.0

@onready var spikes: Polygon2D = $Spikes
@onready var phase := cycle_offset


func _ready() -> void:
	_update_spikes()


func _physics_process(delta: float) -> void:
	phase = fposmod(phase + delta, CYCLE)
	_update_spikes()
	if phase >= ACTIVE_START:
		for body in get_overlapping_bodies():
			if body.is_in_group(&"player"):
				player_touched.emit(body)


func _update_spikes() -> void:
	if phase >= ACTIVE_START:
		spikes.position.y = 0
		spikes.color = Color("#ff6250")
	elif phase >= WARNING_START:
		spikes.position.y = 7
		spikes.color = Color("#ffd26b")
	else:
		spikes.position.y = 10
		spikes.color = Color("#927066")
