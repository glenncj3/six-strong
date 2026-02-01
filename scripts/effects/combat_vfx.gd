extends RefCounted
class_name CombatVFX
## Static factory for creating combat visual effects.

const BURN_TEXTURE = preload("res://assets/external-assets/ultimate-megapack/Jet_Fire_v11_spritesheet.png")
const BURN_FRAME_SIZE = Vector2i(512, 512)
const BURN_COLUMNS = 8
const BURN_TOTAL_FRAMES = 48
const BURN_FPS = 192.0


const BLADE_TEXTURE = preload("res://assets/external-assets/ultimate-megapack/Projectile_Spinning_Blade_spritesheet.png")
const BLADE_FRAME_SIZE = Vector2i(512, 512)
const BLADE_COLUMNS = 8
const BLADE_TOTAL_FRAMES = 64
const BLADE_FPS = 256.0


static func create_attack_projectile(source_pos: Vector2, target_pos: Vector2) -> SpriteSheetVFX:
	var vfx = SpriteSheetVFX.new()
	vfx.setup(BLADE_TEXTURE, BLADE_FRAME_SIZE, BLADE_TOTAL_FRAMES, BLADE_COLUMNS, BLADE_FPS)
	vfx.travel_to(source_pos, target_pos, 0.35)
	return vfx


static func create_burn_jet(source_pos: Vector2, target_pos: Vector2) -> SpriteSheetVFX:

	var vfx = SpriteSheetVFX.new()
	vfx.setup(BURN_TEXTURE, BURN_FRAME_SIZE, BURN_TOTAL_FRAMES, BURN_COLUMNS, BURN_FPS)
	vfx.place_between(source_pos, target_pos)
	return vfx
