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

## The [member SpriteFrames] resource containing the animation(s). Allows you the option to load, edit, clear, make unique and save the states of the [member SpriteFrames] resource.
@export var sprite_frames: SpriteFrames:
	set(val):
		if sprite_frames == val: return
		
		sprite_frames = val
		sprite_frames_changed.emit()
		_sprite_frames_changed()
		notify_property_list_changed()

@export var animation: StringName = &"default":
	get():
		if sprite_frames != null:
			return animation
		return &"default"
	set(val):
		if animation == val: return
		
		animation = val
		animation_changed.emit()
		queue_redraw()
		notify_property_list_changed()

## The displayed animation frame's index.
@export var frame: int = 0:
	get():
		var _frame: int = frame
		if sprite_frames != null:
			_frame = clampi(_frame, 0, sprite_frames.get_frame_count(animation) - 1)
		
		return _frame
	set(val):
		if val == frame: return
		
		var _frame = val
		if sprite_frames != null:
			_frame = clampi(val, 0, sprite_frames.get_frame_count(animation) - 1)
		
		frame = _frame
		queue_redraw()
		frame_changed.emit()

@export var speed_scale: float = 1.0
@export var offset: Vector2 = Vector2.ZERO:
	get():
		return offset
	set(val):
		if offset == val: return
		offset = val
		queue_redraw()

@export_group("Rect", "rect_")
@export var rect_expand_mode: ExpandMode = ExpandMode.KEEP_SIZE:
	set(val):
		if rect_expand_mode == val: return
		
		rect_expand_mode = val
		queue_redraw()
		update_minimum_size()

@export var rect_stretch_mode: StretchMode = StretchMode.SCALE:
	set(val):
		if rect_stretch_mode == val: return
		
		rect_stretch_mode = val
		queue_redraw()

@export var rect_flip_h: bool = false:
	set(val):
		if rect_flip_h == val: return
		
		rect_flip_h = val
		queue_redraw()

@export var rect_flip_v: bool = false:
	set(val):
		if rect_flip_v == val: return
		
		rect_flip_v = val
		queue_redraw()


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
	if sprite_frames == null:
		return
	
	var frame: Texture2D = sprite_frames.get_frame_texture(animation, frame)
	var rect: Rect2 = get_rect_from_stretch_mode(frame.get_size())
	var tile: bool = rect_stretch_mode == StretchMode.TILE
	
	rect.position += offset
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
			var frame_size: Vector2 = sprite_frames.get_frame_texture(animation, frame).get_size()
			var ratio: float = frame_size.x / frame_size.y
			min_size.x = size.y * ratio
		
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

func _validate_property(property: Dictionary) -> void:
	if property.name == &"animation":
		property.hint = PROPERTY_HINT_ENUM
		property.hint_string = ",".join(_animation_list)
