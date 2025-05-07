# scripts/stops/base_stop.gd
extends Node2D
class_name BaseStop

var stop_id = ""
var stop_resource = null

func _ready():
	# Register with TransitSystem
	if stop_id != "":
		TransitSystem.register_stop(self, stop_id)

func set_stop_data(stop_res):
	stop_resource = stop_res
	update_display()
	
func update_display():
	# Common display logic
	if stop_resource:
		$Label.text = stop_resource.display_name
