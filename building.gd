class_name Building
extends Node2D

@export var building_data: BaseNode
@export var grid_size: int = 64 
@onready var sprite = $Sprite2D

func _ready() -> void:
	if building_data:
		setup_building()
		
func setup_building():
	sprite.texture = building_data.texture
	
	scale_sprite_to_grid()

func scale_sprite_to_grid():
	# Make sure we have a texture to work with
	if not sprite.texture:
		return
	
	# Get the original texture dimensions
	var texture_size = sprite.texture.get_size()
	
	# Calculate scale factors for both width and height
	# We want the sprite to fit entirely within the grid cell
	var scale_x = float(grid_size) / texture_size.x
	var scale_y = float(grid_size) / texture_size.y
	
	# Use the smaller scale factor to ensure the sprite fits completely
	# This maintains the aspect ratio and prevents overflow
	var uniform_scale = min(scale_x, scale_y)
	
	# Apply the calculated scale to the sprite
	sprite.scale = Vector2(uniform_scale, uniform_scale)
	
	# Optional: If you want to fill the entire grid cell regardless of aspect ratio,
	# uncomment the following line instead of using uniform_scale:
	# sprite.scale = Vector2(scale_x, scale_y)	
func set_building_data(data: BaseNode):
	building_data = data
	if sprite:
		setup_building()
