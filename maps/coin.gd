extends Area2D

signal collected

var spent := false


func _on_body_entered(body: Node2D) -> void:
	if spent or not body.is_in_group(&"player"):
		return
	spent = true
	hide()
	collected.emit()
	queue_free()
