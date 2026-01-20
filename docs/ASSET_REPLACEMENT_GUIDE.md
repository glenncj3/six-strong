# Asset Replacement Guide for Auto-Battle Journey

This guide explains how the visual asset system works and how to safely replace placeholder graphics with production art.

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Asset Categories](#asset-categories)
3. [Current File Structure](#current-file-structure)
4. [How Assets Are Loaded](#how-assets-are-loaded)
5. [Replacement Strategies](#replacement-strategies)
6. [The Manifest System](#the-manifest-system)
7. [9-Slice Textures Explained](#9-slice-textures-explained)
8. [Step-by-Step Replacement Process](#step-by-step-replacement-process)
9. [Safety Checklist](#safety-checklist)
10. [Troubleshooting](#troubleshooting)

---

## System Overview

Auto-Battle Journey uses **Godot 4.5** with a data-driven asset architecture. This means:

- **No hardcoded asset paths** in game logic
- **JSON files** define what assets exist and where they're located
- **Centralized loading** through helper functions that handle missing files gracefully
- **Programmatic UI styling** that can be converted to texture-based styling

### Key Principle

```
Game Code → Requests data by ID → JSON provides asset path → Helper loads texture safely
```

This separation means you can swap assets without touching game logic.

---

## Asset Categories

There are two fundamentally different types of visual assets:

### 1. Content Sprites (Easy to Replace)

These are the actual game content images:

| Type | Location | Referenced By |
|------|----------|---------------|
| Character portraits | `assets/characters/` | `data/characters/characters.json` |
| Item icons | `assets/items/` | `data/items/items.json` |
| Skill icons | `assets/skills/` | `data/skills/skills.json` |
| Encounter images | `assets/encounters/` | `data/encounters/encounter_types.json` |
| Combat sprites | `assets/combat/` | Various combat scripts |

**Replacement method:** Drop in new PNGs with same filenames, or update JSON paths.

### 2. UI Chrome (Requires Code Changes)

These are the interface elements currently drawn programmatically:

| Element | Current Implementation | File |
|---------|----------------------|------|
| Panel backgrounds | `StyleBoxFlat` with colors | `scripts/utils/ui_styles.gd` |
| Panel borders | `StyleBoxFlat` border properties | `scripts/utils/ui_styles.gd` |
| Buttons (all states) | `StyleBoxFlat` variations | `scripts/utils/ui_styles.gd` |
| Progress bars | `StyleBoxFlat` | `scripts/utils/ui_styles.gd` |
| Card rarity borders | `StyleBoxFlat` with rarity colors | `scripts/utils/ui_styles.gd` |

**Replacement method:** Convert to `StyleBoxTexture` using 9-slice sprites.

---

## Current File Structure

```
auto-battle-journey/
├── assets/
│   ├── characters/          # Character portrait PNGs
│   │   ├── knight.png
│   │   ├── mage.png
│   │   ├── rogue.png
│   │   └── ... (10 files)
│   │
│   ├── items/               # Item icon PNGs
│   │   ├── sword_iron.png
│   │   ├── staff_oak.png
│   │   └── ... (19 files)
│   │
│   ├── skills/              # Skill icon PNGs
│   │   ├── fireball.png
│   │   ├── heal.png
│   │   └── ... (12 files)
│   │
│   ├── encounters/          # Encounter type images
│   │   ├── combat.png
│   │   ├── shop.png
│   │   └── ... (7 files)
│   │
│   ├── combat/              # Combat-specific sprites
│   │   ├── ai_enemy.png
│   │   └── player_ghost.png
│   │
│   └── ui/                  # UI elements (to be expanded)
│       └── (future UI textures go here)
│
├── data/
│   ├── characters/
│   │   └── characters.json  # Character definitions with image_path
│   ├── items/
│   │   └── items.json       # Item definitions with image_path
│   ├── skills/
│   │   └── skills.json      # Skill definitions with image_path
│   └── encounters/
│       └── encounter_types.json
│
└── scripts/
    └── utils/
        ├── ui_styles.gd     # Programmatic styling (to be modified)
        ├── ui_helpers.gd    # Safe texture loading utilities
        └── ui_scaler.gd     # Responsive sizing
```

---

## How Assets Are Loaded

### Content Sprites Loading Flow

```gdscript
# 1. Game requests character data by ID
var char_data = GameData.get_character_by_id("char_warrior_001")

# 2. char_data contains the image path from JSON:
# { "id": "char_warrior_001", "image_path": "res://assets/characters/knight.png", ... }

# 3. UI component uses safe loader:
UIHelpers.set_texture_safe(portrait_texture_rect, char_data["image_path"])

# 4. Inside set_texture_safe():
static func set_texture_safe(texture_rect: TextureRect, path: String) -> bool:
    if path.is_empty():
        return false
    if not ResourceLoader.exists(path):
        push_warning("Texture not found: %s" % path)
        return false
    texture_rect.texture = load(path)
    return true
```

### Why This Is Safe

- **Missing files don't crash** - they log a warning and continue
- **Empty paths are handled** - no null reference errors
- **Centralized loading** - one place to add error handling or fallbacks

### UI Chrome Loading (Current)

```gdscript
# Currently in UIStyles.gd - creates colors programmatically:
static func create_dark_panel() -> StyleBoxFlat:
    var style = StyleBoxFlat.new()
    style.bg_color = Color("#2E2420")           # Dark brown
    style.border_color = Color("#D9A621")        # Gold
    style.set_border_width_all(2)
    style.set_corner_radius_all(8)
    return style
```

This will change to texture-based loading (see Manifest System below).

---

## Replacement Strategies

### Strategy A: Direct File Replacement (Simplest)

**When to use:** Replacing content sprites with same dimensions and purpose.

**Process:**
1. Create new PNG with exact same filename
2. Overwrite the file in `assets/` folder
3. Done - no code or JSON changes needed

**Example:**
```
Old: assets/characters/knight.png (placeholder)
New: assets/characters/knight.png (production art)
```

**Risks:** None if dimensions are similar. Very large or very small replacements may look odd in fixed-size containers.

---

### Strategy B: JSON Path Update (Moderate)

**When to use:** Adding new assets or changing organizational structure.

**Process:**
1. Add new PNG to appropriate `assets/` subfolder
2. Update the JSON file to point to new path
3. Optionally remove old file

**Example:**
```json
// Before in characters.json:
{
  "id": "char_warrior_001",
  "image_path": "res://assets/characters/knight.png"
}

// After:
{
  "id": "char_warrior_001",
  "image_path": "res://assets/characters/warriors/knight_v2.png"
}
```

**Risks:** Typos in paths cause missing textures (but won't crash due to safe loading).

---

### Strategy C: Manifest-Based Automation (Recommended for Bulk)

**When to use:** Replacing many assets at once, or replacing UI chrome.

**Process:**
1. Create manifest JSON mapping old → new assets
2. Run automation script to update all references
3. Verify changes in-game

See [The Manifest System](#the-manifest-system) for details.

---

### Strategy D: UI Chrome Conversion (Complex)

**When to use:** Replacing programmatic StyleBoxFlat with textured StyleBoxTexture.

**Process:**
1. Create 9-slice compatible PNG textures
2. Modify `UIStyles.gd` to load textures instead of creating flat colors
3. Define 9-slice margins for proper scaling

See [9-Slice Textures Explained](#9-slice-textures-explained) for details.

---

## The Manifest System

The manifest is a JSON file that maps asset identifiers to file paths. This enables automated bulk replacement.

### Manifest File Location

```
assets/manifest.json
```

### Manifest Structure

```json
{
  "version": "1.0",
  "description": "Asset mapping for Auto-Battle Journey",

  "content_sprites": {
    "characters": {
      "char_warrior_001": "res://assets/characters/knight.png",
      "char_mage_001": "res://assets/characters/mage.png",
      "char_rogue_001": "res://assets/characters/rogue.png",
      "char_cleric_001": "res://assets/characters/cleric.png",
      "char_ranger_001": "res://assets/characters/ranger.png",
      "char_paladin_001": "res://assets/characters/paladin.png",
      "char_necromancer_001": "res://assets/characters/necromancer.png",
      "char_berserker_001": "res://assets/characters/berserker.png",
      "char_elementalist_001": "res://assets/characters/elementalist.png",
      "char_assassin_001": "res://assets/characters/assassin.png"
    },
    "items": {
      "item_weapon_sword_001": "res://assets/items/sword_iron.png",
      "item_weapon_staff_001": "res://assets/items/staff_oak.png",
      "item_weapon_dagger_001": "res://assets/items/dagger_steel.png",
      "item_weapon_bow_001": "res://assets/items/bow_hunting.png",
      "item_weapon_mace_001": "res://assets/items/mace_iron.png",
      "item_armor_plate_001": "res://assets/items/armor_plate.png",
      "item_armor_leather_001": "res://assets/items/armor_leather.png",
      "item_armor_robe_001": "res://assets/items/armor_robe.png",
      "item_accessory_ring_001": "res://assets/items/ring_power.png",
      "item_accessory_amulet_001": "res://assets/items/amulet_protection.png"
    },
    "skills": {
      "skill_fireball": "res://assets/skills/fireball.png",
      "skill_heal": "res://assets/skills/heal.png",
      "skill_shield": "res://assets/skills/shield.png",
      "skill_backstab": "res://assets/skills/backstab.png",
      "skill_multishot": "res://assets/skills/multishot.png",
      "skill_smite": "res://assets/skills/smite.png"
    },
    "encounters": {
      "combat": "res://assets/encounters/combat.png",
      "elite_combat": "res://assets/encounters/elite_combat.png",
      "boss": "res://assets/encounters/boss.png",
      "shop": "res://assets/encounters/shop.png",
      "treasure": "res://assets/encounters/treasure.png",
      "rest": "res://assets/encounters/rest.png",
      "event": "res://assets/encounters/event.png"
    }
  },

  "ui_chrome": {
    "panels": {
      "dark_panel": {
        "texture": "res://assets/ui/panels/panel_dark.png",
        "margins": { "left": 12, "top": 12, "right": 12, "bottom": 12 }
      },
      "warm_panel": {
        "texture": "res://assets/ui/panels/panel_warm.png",
        "margins": { "left": 12, "top": 12, "right": 12, "bottom": 12 }
      },
      "card_panel_common": {
        "texture": "res://assets/ui/cards/card_common.png",
        "margins": { "left": 8, "top": 8, "right": 8, "bottom": 8 }
      },
      "card_panel_uncommon": {
        "texture": "res://assets/ui/cards/card_uncommon.png",
        "margins": { "left": 8, "top": 8, "right": 8, "bottom": 8 }
      },
      "card_panel_rare": {
        "texture": "res://assets/ui/cards/card_rare.png",
        "margins": { "left": 8, "top": 8, "right": 8, "bottom": 8 }
      },
      "card_panel_epic": {
        "texture": "res://assets/ui/cards/card_epic.png",
        "margins": { "left": 8, "top": 8, "right": 8, "bottom": 8 }
      },
      "card_panel_legendary": {
        "texture": "res://assets/ui/cards/card_legendary.png",
        "margins": { "left": 8, "top": 8, "right": 8, "bottom": 8 }
      }
    },
    "buttons": {
      "primary": {
        "normal": {
          "texture": "res://assets/ui/buttons/btn_primary_normal.png",
          "margins": { "left": 8, "top": 8, "right": 8, "bottom": 8 }
        },
        "hover": {
          "texture": "res://assets/ui/buttons/btn_primary_hover.png",
          "margins": { "left": 8, "top": 8, "right": 8, "bottom": 8 }
        },
        "pressed": {
          "texture": "res://assets/ui/buttons/btn_primary_pressed.png",
          "margins": { "left": 8, "top": 8, "right": 8, "bottom": 8 }
        },
        "disabled": {
          "texture": "res://assets/ui/buttons/btn_primary_disabled.png",
          "margins": { "left": 8, "top": 8, "right": 8, "bottom": 8 }
        }
      },
      "secondary": {
        "normal": {
          "texture": "res://assets/ui/buttons/btn_secondary_normal.png",
          "margins": { "left": 8, "top": 8, "right": 8, "bottom": 8 }
        },
        "hover": {
          "texture": "res://assets/ui/buttons/btn_secondary_hover.png",
          "margins": { "left": 8, "top": 8, "right": 8, "bottom": 8 }
        },
        "pressed": {
          "texture": "res://assets/ui/buttons/btn_secondary_pressed.png",
          "margins": { "left": 8, "top": 8, "right": 8, "bottom": 8 }
        },
        "disabled": {
          "texture": "res://assets/ui/buttons/btn_secondary_disabled.png",
          "margins": { "left": 8, "top": 8, "right": 8, "bottom": 8 }
        }
      }
    },
    "progress_bars": {
      "health": {
        "background": {
          "texture": "res://assets/ui/bars/bar_health_bg.png",
          "margins": { "left": 4, "top": 4, "right": 4, "bottom": 4 }
        },
        "fill": {
          "texture": "res://assets/ui/bars/bar_health_fill.png",
          "margins": { "left": 4, "top": 4, "right": 4, "bottom": 4 }
        }
      },
      "experience": {
        "background": {
          "texture": "res://assets/ui/bars/bar_xp_bg.png",
          "margins": { "left": 4, "top": 4, "right": 4, "bottom": 4 }
        },
        "fill": {
          "texture": "res://assets/ui/bars/bar_xp_fill.png",
          "margins": { "left": 4, "top": 4, "right": 4, "bottom": 4 }
        }
      }
    }
  },

  "fallbacks": {
    "missing_character": "res://assets/ui/placeholder_character.png",
    "missing_item": "res://assets/ui/placeholder_item.png",
    "missing_skill": "res://assets/ui/placeholder_skill.png",
    "missing_panel": null
  }
}
```

### Using the Manifest for Automation

When you provide updated assets:

1. **Update manifest paths** to point to new files
2. **Run automation** which:
   - Reads manifest
   - Updates all JSON data files with new paths
   - Modifies UIStyles.gd for UI chrome changes
3. **Verify** in-game

---

## 9-Slice Textures Explained

### What is 9-Slice?

9-slice (also called 9-patch) is a technique for scaling UI textures without distorting corners or edges.

```
┌─────┬───────────────┬─────┐
│  1  │       2       │  3  │  ← Corners (1,3,7,9) never scale
├─────┼───────────────┼─────┤
│     │               │     │
│  4  │       5       │  6  │  ← Edges (2,4,6,8) scale in one direction
│     │               │     │
├─────┼───────────────┼─────┤
│  7  │       8       │  9  │  ← Center (5) scales in both directions
└─────┴───────────────┴─────┘
```

### Why It Matters

Without 9-slice, scaling a panel texture stretches the corners:

```
Original:        Stretched (ugly):     9-Slice (correct):
┌──────┐         ┌────────────────┐    ┌────────────────┐
│ ╭──╮ │         │ ╭────────────╮ │    │ ╭──────────╮   │
│ │  │ │    →    │ │            │ │    │ │          │   │
│ ╰──╯ │         │ ╰────────────╯ │    │ ╰──────────╯   │
└──────┘         └────────────────┘    └────────────────┘
  Rounded          Corners stretched     Corners preserved
  corners
```

### Creating 9-Slice Compatible Art

**Requirements:**

1. **Consistent corner regions** - all 4 corners should be the same size
2. **Tileable edges** - the edge regions should tile seamlessly
3. **Sufficient resolution** - minimum 3x the margin size (e.g., 12px margins → 36px minimum)

**Recommended dimensions:**

| Asset Type | Minimum Size | Recommended Size | Typical Margins |
|------------|--------------|------------------|-----------------|
| Panel | 48x48 | 64x64 or 96x96 | 12-16px |
| Button | 32x24 | 48x32 | 8px |
| Card border | 64x64 | 96x96 or 128x128 | 8-12px |
| Progress bar | 24x12 | 32x16 | 4px |

**Example panel texture (64x64 with 12px margins):**

```
         12px        40px        12px
       ┌──────┬──────────────┬──────┐
  12px │corner│    edge      │corner│
       ├──────┼──────────────┼──────┤
       │      │              │      │
  40px │ edge │   center     │ edge │
       │      │              │      │
       ├──────┼──────────────┼──────┤
  12px │corner│    edge      │corner│
       └──────┴──────────────┴──────┘
```

### Godot StyleBoxTexture Setup

```gdscript
# How 9-slice is configured in Godot:
var style = StyleBoxTexture.new()
style.texture = load("res://assets/ui/panels/panel_dark.png")

# These margins define where to "cut" the 9 regions:
style.texture_margin_left = 12
style.texture_margin_top = 12
style.texture_margin_right = 12
style.texture_margin_bottom = 12

# Content margins (padding inside the panel):
style.content_margin_left = 8
style.content_margin_top = 8
style.content_margin_right = 8
style.content_margin_bottom = 8
```

---

## Step-by-Step Replacement Process

### Process A: Replacing a Single Content Sprite

**Scenario:** You have new art for the Knight character.

**Steps:**

1. **Prepare the new image**
   - Format: PNG with transparency
   - Recommended size: 256x256 or larger (will be scaled down)
   - Name: `knight.png` (same as existing)

2. **Backup the original** (optional but recommended)
   ```
   assets/characters/knight.png → assets/characters/knight_backup.png
   ```

3. **Replace the file**
   ```
   Copy new knight.png to assets/characters/knight.png
   ```

4. **Test in-game**
   - Launch the game
   - View the character in Collection screen
   - Check it appears correctly in Draft and Combat

**No code changes needed.**

---

### Process B: Bulk Content Sprite Replacement

**Scenario:** You have new art for all characters.

**Steps:**

1. **Prepare the manifest**
   - Create or update `assets/manifest.json`
   - List all character IDs and their new paths

2. **Add new files to assets folder**
   ```
   assets/characters/knight_v2.png
   assets/characters/mage_v2.png
   ... etc
   ```

3. **Run automation** (I will do this)
   - Updates `data/characters/characters.json` with new paths
   - Optionally removes old files

4. **Test all characters in-game**

---

### Process C: UI Chrome Replacement

**Scenario:** You want to replace the flat-colored panels with textured panels.

**Steps:**

1. **Create 9-slice compatible textures**
   ```
   assets/ui/panels/panel_dark.png      (64x64, 12px margins)
   assets/ui/panels/panel_warm.png      (64x64, 12px margins)
   assets/ui/cards/card_common.png      (96x96, 8px margins)
   assets/ui/cards/card_rare.png        (96x96, 8px margins)
   ... etc
   ```

2. **Update the manifest**
   - Add entries to `ui_chrome.panels` section
   - Specify correct margin values for each texture

3. **Run automation** (I will do this)
   - Modifies `scripts/utils/ui_styles.gd`
   - Changes `StyleBoxFlat` creation to `StyleBoxTexture`
   - Adds safe loading with fallback to flat colors

4. **Test all screens**
   - Main menu, Collection, Draft, Run View, Encounter Select, Combat

---

### Process D: Adding New Content

**Scenario:** Adding a new character that doesn't exist yet.

**Steps:**

1. **Create the character art**
   ```
   assets/characters/dragon_knight.png
   ```

2. **Add to manifest** (optional, for tracking)
   ```json
   "char_dragon_knight_001": "res://assets/characters/dragon_knight.png"
   ```

3. **Add JSON entry** in `data/characters/characters.json`
   ```json
   {
     "id": "char_dragon_knight_001",
     "name": "Dragon Knight",
     "image_path": "res://assets/characters/dragon_knight.png",
     "base_stats": {
       "health": 100,
       "basic_attack_damage": 15,
       "basic_attack_speed": 1.0,
       "special_attack_damage": 25,
       "special_attack_speed": 0.5
     },
     "rarity": "epic",
     "rank_rewards": []
   }
   ```

4. **Test**
   - Character should appear in Collection
   - Should be available for drafting

---

## Safety Checklist

### Before Making Changes

- [ ] **Backup original files** - Copy to a `_backup` folder or use git
- [ ] **Verify image format** - Must be PNG (or supported format)
- [ ] **Check dimensions** - Very large images may impact performance
- [ ] **Validate 9-slice margins** - For UI textures, ensure margins don't exceed image size
- [ ] **Test in isolation** - Replace one asset first, verify it works

### After Making Changes

- [ ] **No console errors** - Check Godot output for warnings
- [ ] **Visual inspection** - Check all screens where asset appears
- [ ] **Different sizes** - Assets may appear at different scales (card sizes)
- [ ] **Edge cases** - Empty states, disabled states, hover states

### Common Mistakes to Avoid

| Mistake | Consequence | Prevention |
|---------|-------------|------------|
| Wrong file path in JSON | Missing texture warning | Double-check paths start with `res://` |
| Typo in asset ID | Asset not found | Copy-paste IDs, don't retype |
| 9-slice margins too large | Texture won't scale | Margins must be < half the image size |
| Missing button states | Broken hover/press effects | Always provide all 4 states |
| JPEG instead of PNG | No transparency | Always use PNG for game assets |
| Very large files | Memory/performance issues | Keep under 512x512 for icons, 1024x1024 for portraits |

---

## Troubleshooting

### "Texture not found" Warning

**Symptom:** Console shows `UIHelpers: Texture not found: res://assets/...`

**Causes:**
1. File doesn't exist at that path
2. Typo in the path
3. Wrong file extension
4. File not imported by Godot yet

**Solutions:**
1. Verify file exists in FileSystem dock
2. Check JSON for typos
3. Ensure extension matches exactly (`.png` not `.PNG`)
4. Reimport: right-click file → Reimport

---

### UI Element Looks Wrong After Texture Replacement

**Symptom:** Panel corners are stretched or distorted

**Causes:**
1. 9-slice margins are incorrect
2. Texture doesn't have consistent corners
3. Margins exceed image dimensions

**Solutions:**
1. Measure actual corner size in image editor
2. Update margin values in manifest
3. Ensure margins < (image_size / 2)

---

### Asset Appears But Wrong Size

**Symptom:** Character portrait is tiny or huge

**Causes:**
1. `TextureRect` expand mode not set correctly
2. Container sizing constraints

**Solutions:**
1. Check expand mode is `EXPAND_FIT_WIDTH_PROPORTIONAL` or similar
2. Verify parent container has correct minimum size

---

### Changes Don't Appear In-Game

**Symptom:** Replaced file but old image still shows

**Causes:**
1. Godot caching the old resource
2. Didn't save the scene/resource
3. Running an old build

**Solutions:**
1. In Godot: Scene → Reload Current Scene
2. Or restart Godot entirely
3. Check you're running from editor, not exported build

---

## Appendix: Asset Specifications Summary

### Content Sprites

| Type | Dimensions | Format | Transparency |
|------|------------|--------|--------------|
| Character portrait | 256x256 recommended | PNG | Yes |
| Item icon | 64x64 or 128x128 | PNG | Yes |
| Skill icon | 64x64 or 128x128 | PNG | Yes |
| Encounter image | 128x128 or 256x256 | PNG | Yes |

### UI Chrome (9-Slice)

| Type | Dimensions | Margins | States Needed |
|------|------------|---------|---------------|
| Panel (dark/warm) | 64x64 | 12px | 1 |
| Card border | 96x96 | 8px | 5 (per rarity) |
| Button (primary) | 48x32 | 8px | 4 (normal/hover/pressed/disabled) |
| Button (secondary) | 48x32 | 8px | 4 |
| Progress bar BG | 32x16 | 4px | 1 |
| Progress bar fill | 32x16 | 4px | 1 per type |

### Color Reference (Current Theme)

For creating art that matches the existing style:

```
Background colors:
  - Deep purple: #1E1C2E
  - Mid purple: #292438
  - Light purple: #383148

Panel colors:
  - Dark mahogany: #2E2420
  - Warm mahogany: #3D2E24
  - Elevated: #4D3E34

Accent colors:
  - Gold (primary): #D9A621
  - Gold (bright): #F4C430
  - Silver: #BFC4D1

Rarity colors:
  - Common: #9CA3AF (gray)
  - Uncommon: #22C55E (green)
  - Rare: #3B82F6 (blue)
  - Epic: #A855F7 (purple)
  - Legendary: #F59E0B (orange/gold)

Status colors:
  - Health (emerald): #2DD4BF
  - Damage (ruby): #F87171
  - Magic (amethyst): #C084FC

Text colors:
  - Primary (parchment): #F2EBD9
  - Secondary (tan): #B8A88A
  - Muted: #6B6B7B
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Initial | Initial documentation |

---

## Need Help?

If you encounter issues not covered here:

1. Check the Godot console for specific error messages
2. Verify the asset exists and path is correct
3. Ensure you've saved all changes
4. Try restarting Godot to clear caches

For automation assistance, provide:
- The manifest file with your desired mappings
- The new asset files in the correct locations
- Which replacement strategy you want to use
