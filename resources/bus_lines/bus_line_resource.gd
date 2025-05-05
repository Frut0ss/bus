@tool
class_name BusLineResource
extends Resource

@export var id: String
@export var display_name: String
@export var color: Color
@export var stops : Array[BusStopResource]
@export var frequency: float = 5.0  # Seconds between buses
@export var travel_time_between_stops: float = 2.0  # Seconds
@export var variants = []

func add_stop(stop_resource):
	if stop_resource not in stops:
		stops.append(stop_resource)
		# Also connect this line to the stop
		stop_resource.add_line(self)

func remove_stop(stop_resource):
	if stop_resource in stops:
		stops.erase(stop_resource)
		# Also disconnect this line from the stop
		stop_resource.remove_line(self)

func get_stop_ids():
	var ids = []
	for stop in stops:
		ids.append(stop.id)
	return ids
