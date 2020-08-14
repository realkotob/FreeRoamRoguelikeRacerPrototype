extends ViewportContainer


# Declare member variables here. Examples:
var cam = null
var mouse = Vector2()
var mmap_offset 
var player
var map
var nav_result

# Called when the node enters the scene tree for the first time.
func _ready():
	cam = get_node("Viewport/Camera2D")
	#the camera seems to be offset by this value from minimap center
	# experimentally determined
	mmap_offset = Vector2(70,85)

	player = get_parent()
	map = get_node("/root/Navigation").get_node("map")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

# zoom in
func _on_ButtonPlus_pressed():
	# any closer and it's too blurry
	if cam.zoom.x > 0.75:
		cam.zoom.x -= 0.25
		cam.zoom.y -= 0.25

# zoom out
func _on_ButtonMinus_pressed():
	cam.zoom.x += 0.25
	cam.zoom.y += 0.25


# detect clicks
func _draw():
	if mouse != null:
		draw_rect(Rect2(mouse, Vector2(8,8)), Color(1,0,0))

## inverse of pos3dtominimap from map_texture.gd
#func point2d_to3d(pos):
#	var middle = Vector2(500,500)
#	return pos+middle

# returns id of closest intersection
func find_closest_intersection(pos):
	# list of intersection global positions
	var intersections = get_parent().get_node("Viewport_root/Viewport/minimap").intersections
	
	# pos is flipped for some reason, so unflip it
	pos = -pos
	
	# sort by distance
	var dists = []
	var tmp = []
	#for inter in intersections:
	for i in range(intersections.size()-1):
		var inter = intersections[i]
		# pretend it's 2d
		var inter_pos = Vector2(inter.x, inter.z)
		var dist = inter_pos.distance_to(pos)
		tmp.append([dist, i])
		dists.append(dist)

	dists.sort()
	
	for t in tmp:
		if t[0] == dists[0]:
			#print("Target is : " + t[1].get_parent().get_name())
			
			return t[1]

func player_nav(target):
	# look up the closest intersection
	var map_loc = map.to_local(player.get_global_transform().origin)
	#print("global: " + str(get_global_transform().origin) + ", map_loc: " + str(map_loc))
		
	# this operates on child ids
	var sorted = map.sort_intersections_distance(map_loc, true)
	var closest_ind = sorted[0][1]
	var closest = map.get_child(closest_ind)
	#print("Closest: " + str(closest.get_name()))
	
	# this operates on ids, therefore we subtract 3 from child id
	var int_path = map.get_node("nav").ast.get_id_path(closest_ind-3, target)
	print("Intersections path: " + str(int_path))
func _on_MapView_gui_input(event):
	if event is InputEventMouseButton:
		mouse = event.position
		print("Clicked mouse in map viewport @ ", event.position)
		# camera position is half viewport width and half viewport height
		var rel_pos = get_node("center").get_transform().xform_inv(event.position)
		#print("Relative to camera: ", rel_pos)
		# somehow, this fits the intersection positions sent to minimap (just flipped signs)
		# before transforming to 2d
		var rel_mmap = rel_pos-mmap_offset
		#print("Relative to mmap centre: ", rel_mmap)
		#print("Converted to 3d", point2d_to3d(rel_pos-mmap_offset))
		var clicked_inter = find_closest_intersection(rel_mmap)
		print("Clicked inter: ", clicked_inter)
		player_nav(clicked_inter)

		
		# draw
		update()

