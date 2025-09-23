class_name GridPlacementSystem
extends Node2D

# Grid configuration
@export var grid_size: int = 64  # Size of each grid cell in pixels
@export var grid_width: int = 30  # Number of cells horizontally
@export var grid_height: int = 20  # Number of cells vertically

# Visual settings for the modern fade effect
@export var grid_line_color: Color = Color(1, 1, 1, 0.3)  # White with transparency
@export var hover_color: Color = Color(0.2, 0.8, 1.0, 0.4)  # Cyan highlight
@export var fade_radius: float = 300.0  # How far from mouse the grid is visible
@export var fade_softness: float = 100.0  # How gradual the fade is

# Building placement
@export var building_scene: PackedScene = preload("res://building.tscn")
@export var test_building_data: BaseNode  # Assign in inspector for testing

# Internal state tracking
var mouse_grid_position: Vector2i = Vector2i.ZERO
var placed_buildings: Dictionary = {}  # Key: Vector2i grid pos, Value: Building instance
var is_placement_valid: bool = true

func _ready() -> void:
	# Make sure we redraw every frame for the fade effect
	set_process(true)

func _process(_delta: float) -> void:
	# Update mouse grid position and trigger redraw for the fade effect
	var mouse_pos = get_local_mouse_position()
	mouse_grid_position = world_to_grid(mouse_pos)
	
	# Check if current position is valid for placement
	is_placement_valid = is_grid_position_valid(mouse_grid_position) and \
						 not is_position_occupied(mouse_grid_position)
	
	# Force redraw to update grid visualization
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	# Handle building placement on left click
	if event.is_action_pressed("ui_accept") or \
	   (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		if is_placement_valid:
			place_building(mouse_grid_position)

func _draw() -> void:
	# Get mouse position for fade calculations
	var mouse_pos = get_local_mouse_position()
	
	# Draw grid lines with distance-based fading
	draw_grid_lines(mouse_pos)
	
	# Draw hover highlight if position is valid
	if is_placement_valid:
		draw_hover_cell(mouse_grid_position, hover_color)
	else:
		# Draw red tint if position is invalid
		draw_hover_cell(mouse_grid_position, Color(1, 0.2, 0.2, 0.3))

func draw_grid_lines(mouse_pos: Vector2) -> void:
	# Draw vertical lines
	for x in range(grid_width + 1):
		var start_pos = Vector2(x * grid_size, 0)
		var end_pos = Vector2(x * grid_size, grid_height * grid_size)
		
		# Draw line segments with varying opacity based on distance to mouse
		draw_faded_line(start_pos, end_pos, mouse_pos)
	
	# Draw horizontal lines
	for y in range(grid_height + 1):
		var start_pos = Vector2(0, y * grid_size)
		var end_pos = Vector2(grid_width * grid_size, y * grid_size)
		
		draw_faded_line(start_pos, end_pos, mouse_pos)

func draw_faded_line(start: Vector2, end: Vector2, mouse_pos: Vector2) -> void:
	# Sample points along the line to create fade effect
	var segments = 20  # Number of segments to break the line into
	
	for i in range(segments):
		var t1 = float(i) / float(segments)
		var t2 = float(i + 1) / float(segments)
		
		var seg_start = start.lerp(end, t1)
		var seg_end = start.lerp(end, t2)
		
		# Calculate distance from segment midpoint to mouse
		var midpoint = (seg_start + seg_end) * 0.5
		var distance = midpoint.distance_to(mouse_pos)
		
		# Calculate fade alpha based on distance
		var alpha = 1.0 - smoothstep(fade_radius - fade_softness, fade_radius + fade_softness, distance)
		alpha *= grid_line_color.a  # Multiply by base alpha
		
		if alpha > 0.01:  # Only draw if visible
			var color = Color(grid_line_color.r, grid_line_color.g, grid_line_color.b, alpha)
			draw_line(seg_start, seg_end, color, 1.0)

func draw_hover_cell(grid_pos: Vector2i, color: Color) -> void:
	# Calculate world position of the grid cell
	var world_pos = grid_to_world(grid_pos)
	
	# Draw filled rectangle for hover effect
	var rect = Rect2(world_pos, Vector2(grid_size, grid_size))
	draw_rect(rect, color)
	
	# Draw border for clarity
	var border_color = Color(color.r, color.g, color.b, min(1.0, color.a * 2))
	draw_rect(rect, border_color, false, 2.0)

func place_building(grid_pos: Vector2i) -> void:
	# Don't place if position is invalid or occupied
	if not is_placement_valid:
		return
	
	# Create building instance
	var building = building_scene.instantiate()
	add_child(building)
	
	# Set building data (for testing, use the exported test data)
	if test_building_data:
		building.set_building_data(test_building_data)
	
	# Position building at grid cell center
	building.position = grid_to_world(grid_pos) + Vector2(grid_size, grid_size) * 0.5
	
	# Store reference to track occupied cells
	placed_buildings[grid_pos] = building
	
	print("Building placed at grid position: ", grid_pos)

# Utility functions for grid conversion
func world_to_grid(world_pos: Vector2) -> Vector2i:
	# Convert world coordinates to grid coordinates
	return Vector2i(int(world_pos.x / grid_size), int(world_pos.y / grid_size))

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	# Convert grid coordinates to world coordinates (top-left of cell)
	return Vector2(grid_pos.x * grid_size, grid_pos.y * grid_size)

func is_grid_position_valid(grid_pos: Vector2i) -> bool:
	# Check if position is within grid bounds
	return grid_pos.x >= 0 and grid_pos.x < grid_width and \
		   grid_pos.y >= 0 and grid_pos.y < grid_height

func is_position_occupied(grid_pos: Vector2i) -> bool:
	# Check if a building already exists at this position
	return placed_buildings.has(grid_pos)

func remove_building(grid_pos: Vector2i) -> void:
	# Remove building at specified grid position
	if placed_buildings.has(grid_pos):
		placed_buildings[grid_pos].queue_free()
		placed_buildings.erase(grid_pos)
