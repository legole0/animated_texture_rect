@tool
@icon("AnimatedTextureRect.svg")
extends Control
class_name AnimatedTextureRect

enum ExpandMode {
	KEEP_SIZE,
	IGNORE_SIZE,
	FIT_WIDTH,
	FIT_WIDTH_PROPORTIONAL,
	FIT_HEIGHT,
	FIT_HEIGHT_PROPORTIONAL
}

enum StretchMode {
	SCALE,
	TILE,
	KEEP,
	KEEP_CENTERED,
	KEEP_ASPECT,
	KEEP_ASPECT_CENTERED,
	KEEP_ASPECT_COVERED
}

@export_group("Rect", "rect_")
@export var rect_expand_mode: ExpandMode = ExpandMode.KEEP_SIZE:
	set(val):
		rect_expand_mode = val
		queue_redraw()
		update_minimum_size()

@export var rect_stretch_mode: StretchMode = StretchMode.SCALE:
	set(val):
		rect_stretch_mode = val
		queue_redraw()

@export var rect_flip_h: bool = false:
	set(val):
		rect_flip_h = val
		queue_redraw()

@export var rect_flip_v: bool = false:
	set(val):
		rect_flip_v = val
		queue_redraw()

## The [member SpriteFrames] resource containing the animation(s). Allows you the option to load, edit, clear, make unique and save the states of the [member SpriteFrames] resource.
@export var sprite_frames: SpriteFrames:
	set(val):
		sprite_frames = val
		sprite_frames_changed.emit()
		_sprite_frames_changed()
		notify_property_list_changed()

@export_storage var animation: StringName = _animation_list[0]:
	get():
		if sprite_frames != null:
			return animation
		return &"default"
	set(val):
		animation = val
		animation_changed.emit()
		notify_property_list_changed()

## The displayed animation frame's index.
@export_storage var frame: int = 0:
	get():
		var _frame: int = frame
		if sprite_frames != null:
			_frame = clampi(_frame, 0, sprite_frames.get_frame_count(animation) - 1)
		
		return _frame
	set(val):
		if val == frame:
			return
		
		var _frame = val
		if sprite_frames != null:
			_frame = clampi(val, 0, sprite_frames.get_frame_count(animation) - 1)
		
		frame = _frame
		queue_redraw()
		frame_changed.emit()

@export_storage var speed_scale: float = 1.0
@export_storage var offset: Vector2 = Vector2.ZERO

@export_storage var _minimum_size_cache: Vector2 = Vector2.ZERO

var _animation_list: PackedStringArray:
	get():
		if sprite_frames != null:
			var anims: PackedStringArray = sprite_frames.get_animation_names()
			if !anims.is_empty():
				return anims
		
		return [&"default"]

signal animation_changed
signal animation_finished
signal animation_looped
signal frame_changed
signal sprite_frames_changed

func _sprite_frames_changed() -> void:
	if sprite_frames != null and !sprite_frames.has_animation(animation):
		animation = sprite_frames.get_animation_names()[0]

func _draw() -> void:
	var frame: Texture2D = sprite_frames.get_frame_texture(animation, frame)
	var rect: Rect2 = get_rect_from_stretch_mode(frame.get_size())
	var tile: bool = rect_stretch_mode == StretchMode.TILE
	
	draw_texture_rect(frame, rect, tile)

func _get_minimum_size() -> Vector2:
	if sprite_frames == null:
		return _minimum_size_cache
	
	var min_size: Vector2 = Vector2.ZERO
	
	match rect_expand_mode:
		ExpandMode.KEEP_SIZE:
			min_size = sprite_frames.get_frame_texture(animation, frame).get_size()
		
		ExpandMode.FIT_WIDTH:
			min_size.x = sprite_frames.get_frame_texture(animation, frame).get_size().x
		
		ExpandMode.FIT_WIDTH_PROPORTIONAL:
			#unimplemented yet, this is just FIT_WIDTH
			min_size.x = sprite_frames.get_frame_texture(animation, frame).get_size().x
		
		ExpandMode.FIT_HEIGHT:
			min_size.y = sprite_frames.get_frame_texture(animation, frame).get_size().y
		
		ExpandMode.FIT_HEIGHT_PROPORTIONAL:
			#unimplemented yet, this is just FIT_HEIGHT
			min_size.y = sprite_frames.get_frame_texture(animation, frame).get_size().y
	
	_minimum_size_cache = min_size
	return min_size

func get_rect_from_stretch_mode(frame_size: Vector2) -> Rect2:
	var rect: Rect2 = Rect2()
	
	match rect_stretch_mode:
		StretchMode.SCALE:
			rect.size = get_rect().size
		
		StretchMode.TILE:
			# unimplemented yet
			rect.size = get_rect().size
		
		StretchMode.KEEP:
			rect.size = frame_size
		
		StretchMode.KEEP_CENTERED:
			rect.position = (get_rect().size / 2) - (frame_size / 2)
			rect.size = frame_size
		
		StretchMode.KEEP_ASPECT:
			pass
		
		StretchMode.KEEP_ASPECT_CENTERED:
			pass
		
		StretchMode.KEEP_ASPECT_COVERED:
			pass
	
	return rect

func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary]
	
	properties.append({
		name = &"animation",
		usage = PROPERTY_USAGE_EDITOR,
		hint = PROPERTY_HINT_ENUM,
		type = TYPE_STRING_NAME,
		hint_string = ",".join(_animation_list)
	})
	
	properties.append({
		name = &"frame",
		usage = PROPERTY_USAGE_EDITOR,
		type = TYPE_INT,
	})
	
	properties.append({
		name = &"speed_scale",
		usage = PROPERTY_USAGE_EDITOR,
		type = TYPE_FLOAT,
	})
	
	properties.append({
		name = &"offset",
		usage = PROPERTY_USAGE_EDITOR,
		type = TYPE_VECTOR2,
	})
	
	return properties

func _property_can_revert(property: StringName) -> bool:
	if property == &"animation" and animation == &"default":
		return true
	
	return false

func _property_get_revert(property: StringName) -> Variant:
	if property == &"animation":
		return &"default"
	
	return null
