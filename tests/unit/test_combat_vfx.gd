extends "res://tests/base_test.gd"


func _init():
	test_name = "Combat VFX Tests"
	super()


func _run_tests():
	section("SpriteSheetVFX Setup")
	_test_setup_initializes_sprite()
	_test_setup_sets_region_rect()
	_test_setup_frame_parameters()

	section("SpriteSheetVFX Frame Calculation")
	_test_set_frame_first()
	_test_set_frame_mid_row()
	_test_set_frame_next_row()
	_test_set_frame_last()

	section("SpriteSheetVFX place_between")
	_test_place_between_positions_at_source()
	_test_place_between_scales_to_distance()
	_test_place_between_rotates_toward_target()

	section("SpriteSheetVFX travel_to")
	_test_travel_to_positions_at_source()
	_test_travel_to_sets_traveling_state()
	_test_travel_to_calculates_duration()
	_test_travel_to_centers_sprite()
	_test_travel_to_sets_additive_blend()
	_test_travel_to_no_blend_by_default()
	_test_travel_to_applies_scale()

	section("CombatVFX Factory - Burn Jet")
	_test_create_burn_jet_returns_vfx()
	_test_burn_jet_constants()

	section("CombatVFX Factory - Attack Projectile")
	_test_create_attack_projectile_returns_vfx()
	_test_attack_projectile_constants()
	_test_attack_projectile_uses_travel()

	section("CombatVFX Factory - Poison Projectile")
	_test_create_poison_projectile_returns_vfx()
	_test_poison_projectile_constants()
	_test_poison_projectile_uses_travel()
	_test_poison_projectile_no_additive_blend()


# --- SpriteSheetVFX Setup ---

func _test_setup_initializes_sprite():
	var vfx = SpriteSheetVFX.new()
	root.add_child(vfx)
	var tex = PlaceholderTexture2D.new()
	tex.size = Vector2(256, 256)
	vfx.setup(tex, Vector2i(64, 64), 16, 4, 30.0)
	assert_not_null(vfx._sprite, "Setup creates a Sprite2D child")
	assert_true(vfx._sprite is Sprite2D, "Child is Sprite2D")
	vfx.queue_free()


func _test_setup_sets_region_rect():
	var vfx = SpriteSheetVFX.new()
	root.add_child(vfx)
	var tex = PlaceholderTexture2D.new()
	tex.size = Vector2(256, 256)
	vfx.setup(tex, Vector2i(64, 64), 16, 4, 30.0)
	assert_true(vfx._sprite.region_enabled, "Region mode is enabled")
	assert_eq(vfx._sprite.region_rect, Rect2(0, 0, 64, 64), "Initial region rect is first frame")
	vfx.queue_free()


func _test_setup_frame_parameters():
	var vfx = SpriteSheetVFX.new()
	root.add_child(vfx)
	var tex = PlaceholderTexture2D.new()
	tex.size = Vector2(256, 256)
	vfx.setup(tex, Vector2i(64, 64), 16, 4, 30.0)
	assert_eq(vfx._frame_size, Vector2i(64, 64), "Frame size stored")
	assert_eq(vfx._total_frames, 16, "Total frames stored")
	assert_eq(vfx._columns, 4, "Columns stored")
	assert_eq(vfx._fps, 30.0, "FPS stored")
	vfx.queue_free()


# --- Frame Calculation ---

func _test_set_frame_first():
	var vfx = _make_vfx(16, 4, Vector2i(64, 64))
	vfx._set_frame(0)
	assert_eq(vfx._sprite.region_rect, Rect2(0, 0, 64, 64), "Frame 0 at col=0, row=0")
	vfx.queue_free()


func _test_set_frame_mid_row():
	var vfx = _make_vfx(16, 4, Vector2i(64, 64))
	vfx._set_frame(2)
	assert_eq(vfx._sprite.region_rect, Rect2(128, 0, 64, 64), "Frame 2 at col=2, row=0")
	vfx.queue_free()


func _test_set_frame_next_row():
	var vfx = _make_vfx(16, 4, Vector2i(64, 64))
	vfx._set_frame(5)
	assert_eq(vfx._sprite.region_rect, Rect2(64, 64, 64, 64), "Frame 5 at col=1, row=1")
	vfx.queue_free()


func _test_set_frame_last():
	var vfx = _make_vfx(16, 4, Vector2i(64, 64))
	vfx._set_frame(15)
	assert_eq(vfx._sprite.region_rect, Rect2(192, 192, 64, 64), "Frame 15 at col=3, row=3")
	vfx.queue_free()


# --- place_between ---

func _test_place_between_positions_at_source():
	var vfx = _make_vfx(16, 4, Vector2i(64, 64))
	vfx.place_between(Vector2(100, 200), Vector2(100, 400))
	assert_eq(vfx.global_position, Vector2(100, 200), "Positioned at source")
	vfx.queue_free()


func _test_place_between_scales_to_distance():
	var vfx = _make_vfx(16, 4, Vector2i(64, 64))
	vfx.place_between(Vector2(0, 0), Vector2(0, 200))
	var expected_s = 200.0 / 64.0 * 1.2
	assert_eq(vfx.scale.x, expected_s, "Scale X matches distance")
	assert_eq(vfx.scale.y, expected_s, "Scale Y matches distance")
	vfx.queue_free()


func _test_place_between_rotates_toward_target():
	var vfx = _make_vfx(16, 4, Vector2i(64, 64))
	# Target directly to the right: angle = 0, rotation = 0 + PI/2
	vfx.place_between(Vector2(0, 0), Vector2(100, 0))
	var expected_rot = PI / 2.0
	assert_true(absf(vfx.rotation - expected_rot) < 0.01, "Rotation points toward target (right)")
	vfx.queue_free()


# --- travel_to ---

func _test_travel_to_positions_at_source():
	var vfx = _make_vfx(64, 8, Vector2i(512, 512))
	vfx.travel_to(Vector2(50, 100), Vector2(300, 100), 0.35)
	assert_eq(vfx.global_position, Vector2(50, 100), "Starts at source position")
	vfx.queue_free()


func _test_travel_to_sets_traveling_state():
	var vfx = _make_vfx(64, 8, Vector2i(512, 512))
	assert_false(vfx._traveling, "Not traveling before travel_to")
	vfx.travel_to(Vector2.ZERO, Vector2(100, 0), 0.35)
	assert_true(vfx._traveling, "Traveling after travel_to")
	vfx.queue_free()


func _test_travel_to_calculates_duration():
	var vfx = _make_vfx(64, 8, Vector2i(512, 512), 256.0)
	vfx.travel_to(Vector2.ZERO, Vector2(100, 0), 0.35)
	assert_eq(vfx._travel_duration, 0.25, "Duration = 64 frames / 256 FPS = 0.25s")
	vfx.queue_free()


func _test_travel_to_centers_sprite():
	var vfx = _make_vfx(64, 8, Vector2i(512, 512))
	vfx.travel_to(Vector2.ZERO, Vector2(100, 0), 0.35)
	assert_eq(vfx._sprite.offset, Vector2.ZERO, "Sprite offset centered")
	vfx.queue_free()


func _test_travel_to_sets_additive_blend():
	var vfx = _make_vfx(64, 8, Vector2i(512, 512))
	vfx.travel_to(Vector2.ZERO, Vector2(100, 0), 0.35, true)
	assert_not_null(vfx._sprite.material, "Material assigned with additive=true")
	assert_eq(vfx._sprite.material.blend_mode, CanvasItemMaterial.BLEND_MODE_ADD, "Additive blend mode set")
	vfx.queue_free()


func _test_travel_to_no_blend_by_default():
	var vfx = _make_vfx(64, 8, Vector2i(512, 512))
	vfx.travel_to(Vector2.ZERO, Vector2(100, 0), 0.35)
	assert_null(vfx._sprite.material, "No material when additive_blend=false")
	vfx.queue_free()


func _test_travel_to_applies_scale():
	var vfx = _make_vfx(64, 8, Vector2i(512, 512))
	vfx.travel_to(Vector2.ZERO, Vector2(100, 0), 0.35)
	assert_eq(vfx.scale, Vector2(0.35, 0.35), "Scale applied correctly")
	vfx.queue_free()


# --- CombatVFX Factory: Burn Jet ---

func _test_create_burn_jet_returns_vfx():
	var vfx = CombatVFX.create_burn_jet(Vector2(0, 0), Vector2(0, 200))
	root.add_child(vfx)
	assert_not_null(vfx, "create_burn_jet returns a VFX instance")
	assert_true(vfx is SpriteSheetVFX, "Returns SpriteSheetVFX")
	vfx.queue_free()


func _test_burn_jet_constants():
	assert_eq(CombatVFX.BURN_FRAME_SIZE, Vector2i(512, 512), "Burn frame size is 512x512")
	assert_eq(CombatVFX.BURN_COLUMNS, 8, "Burn columns is 8")
	assert_eq(CombatVFX.BURN_TOTAL_FRAMES, 48, "Burn total frames is 48")
	assert_eq(CombatVFX.BURN_FPS, 192.0, "Burn FPS is 192")


# --- CombatVFX Factory: Attack Projectile ---

func _test_create_attack_projectile_returns_vfx():
	var vfx = CombatVFX.create_attack_projectile(Vector2(0, 0), Vector2(200, 0))
	root.add_child(vfx)
	assert_not_null(vfx, "create_attack_projectile returns a VFX instance")
	assert_true(vfx is SpriteSheetVFX, "Returns SpriteSheetVFX")
	vfx.queue_free()


func _test_attack_projectile_constants():
	assert_eq(CombatVFX.BLADE_FRAME_SIZE, Vector2i(512, 512), "Blade frame size is 512x512")
	assert_eq(CombatVFX.BLADE_COLUMNS, 8, "Blade columns is 8")
	assert_eq(CombatVFX.BLADE_TOTAL_FRAMES, 64, "Blade total frames is 64")
	assert_eq(CombatVFX.BLADE_FPS, 256.0, "Blade FPS is 256")


func _test_attack_projectile_uses_travel():
	var vfx = CombatVFX.create_attack_projectile(Vector2(10, 20), Vector2(300, 20))
	root.add_child(vfx)
	assert_true(vfx._traveling, "Attack projectile uses travel mode")
	assert_eq(vfx._travel_from, Vector2(10, 20), "Travel from source")
	assert_eq(vfx._travel_to, Vector2(300, 20), "Travel to target")
	assert_eq(vfx.scale, Vector2(0.35, 0.35), "Projectile scale is 0.35")
	vfx.queue_free()


# --- CombatVFX Factory: Poison Projectile ---

func _test_create_poison_projectile_returns_vfx():
	var vfx = CombatVFX.create_poison_projectile(Vector2(0, 0), Vector2(200, 0))
	root.add_child(vfx)
	assert_not_null(vfx, "create_poison_projectile returns a VFX instance")
	assert_true(vfx is SpriteSheetVFX, "Returns SpriteSheetVFX")
	vfx.queue_free()


func _test_poison_projectile_constants():
	assert_eq(CombatVFX.POISON_FRAME_SIZE, Vector2i(512, 512), "Poison frame size is 512x512")
	assert_eq(CombatVFX.POISON_COLUMNS, 8, "Poison columns is 8")
	assert_eq(CombatVFX.POISON_TOTAL_FRAMES, 64, "Poison total frames is 64")
	assert_eq(CombatVFX.POISON_FPS, 256.0, "Poison FPS is 256")


func _test_poison_projectile_uses_travel():
	var vfx = CombatVFX.create_poison_projectile(Vector2(10, 20), Vector2(300, 20))
	root.add_child(vfx)
	assert_true(vfx._traveling, "Poison projectile uses travel mode")
	assert_eq(vfx._travel_from, Vector2(10, 20), "Travel from source")
	assert_eq(vfx._travel_to, Vector2(300, 20), "Travel to target")
	assert_eq(vfx.scale, Vector2(0.35, 0.35), "Projectile scale is 0.35")
	vfx.queue_free()


func _test_poison_projectile_no_additive_blend():
	var vfx = CombatVFX.create_poison_projectile(Vector2.ZERO, Vector2(100, 0))
	root.add_child(vfx)
	assert_null(vfx._sprite.material, "Poison projectile has no additive blend (has alpha)")
	vfx.queue_free()


# --- Helpers ---

func _make_vfx(total_frames: int = 16, columns: int = 4, frame_size: Vector2i = Vector2i(64, 64), fps: float = 24.0) -> SpriteSheetVFX:
	var vfx = SpriteSheetVFX.new()
	root.add_child(vfx)
	var tex = PlaceholderTexture2D.new()
	tex.size = Vector2(frame_size.x * columns, frame_size.y * (total_frames / columns))
	vfx.setup(tex, frame_size, total_frames, columns, fps)
	return vfx
