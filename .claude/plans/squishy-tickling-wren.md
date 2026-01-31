# Plan: PurchasableTile embeds CharacterTile for character offerings

## Goal
When a PurchasableTile displays a character, embed a real CharacterTile inside it so the display (portrait, name, stat badges) is identical to team tiles. The PurchasableTile adds only the cost badge and shop logic on top.

## Files to modify

1. **`scenes/components/purchasable_tile.gd`** — Add character-aware setup
2. **`scenes/components/purchasable_tile.tscn`** — No changes needed (CharacterTile added at runtime)
3. **`scripts/encounters/types/character_shop_encounter_ui.gd`** — Pass `CharacterInstance` or enough data for CharacterTile to render

## Approach

### In `purchasable_tile.gd`:

- Add a `const CharacterTileScene = preload(...)`
- In `_apply_setup()`, detect `offering_type == "character"` in tile_data
- When it's a character:
  - Hide the default Icon and NameLabel (they're for generic items)
  - Instantiate a CharacterTile, add it as a child below the cost overlay
  - Call `CharacterTile.setup_from_instance_data()` or use existing `setup()` / `set_character()` with the character data from tile_data
  - CharacterTile handles portrait, name, stat badges automatically
  - Disable CharacterTile click handling (PurchasableTile owns clicks)
- When it's not a character: current behavior unchanged

### CharacterTile setup path:

The tile_data from `character_shop_encounter_ui.gd` already contains `base_stats`, `image_path`, `name`, and `id`. We can use `CharacterTile.setup_from_data()` which accepts a dictionary — it just needs an `id` field to look up master data. This already exists in tile_data.

So the flow is:
1. Instantiate CharacterTile scene
2. Add as child of PurchasableTile (inserted before BorderOverlay so it layers correctly)
3. Call `char_tile.setup_from_data(tile_data, tile_size)` — this loads portrait, name, stats from master data
4. Set `char_tile.clickable = false` and `char_tile.mouse_filter = MOUSE_FILTER_IGNORE`
5. Hide PurchasableTile's own Icon and NameLabel
6. GoldCostIcon remains visible on top

### In `character_shop_encounter_ui.gd`:

Minimal changes — tile_data already has `id` which is all `setup_from_data` needs. No changes required if the existing tile_data structure works.

## Verification

- Run the game, enter a mercenary camp / character shop encounter
- Purchasable character tiles should show stat badges identical to team tiles at top
- Cost badge still visible in top-right
- Click and drag-to-purchase still work
- Non-character PurchasableTiles (health restore, skill trainer, etc.) unchanged
