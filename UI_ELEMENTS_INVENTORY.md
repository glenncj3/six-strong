# UI Elements Inventory

This document lists all UI elements in the game, organized by scene. Use this to identify candidates for replacing with assets from `assets/rpg-icons/`.

---

## Available RPG Icons Categories

For reference, the icon pack contains:
- **Button/** - Circular and rectangular buttons in various colors
- **Chest/** - Treasure chest icons
- **Frame/** - Decorative frames for panels/cards
- **Icon_EquipIcons/** - Equipment icons (axes, swords, hammers, staffs, etc.) in 32/64/128/256/512px
- **Icon_Flag/** - Flag icons
- **Icon_ItemIcons/** - Item icons (coins, potions, books, accessories, etc.) in 32/64/128/256/512px
- **Icon_PictoIcons/** - Pictographic icons
- **IconMisc/** - Miscellaneous icons
- **Label-Title/** - Title/label decorations
- **Popup/** - Popup/dialog decorations
- **Slider/** - Slider UI elements
- **UI_Etc/** - Additional UI elements

---

## Components (Reusable)

### item_slot.tscn
| Element | Type | Current State | Replacement Candidate |
|---------|------|---------------|----------------------|
| ItemSlot | PanelContainer (72x90) | Styled panel | Frame/ |
| ItemIcon | TextureRect (56x56) | Dynamic item images | Icon_EquipIcons/ or Icon_ItemIcons/ |
| ItemName | Label (10px) | Text only | - |

### skill_icon.tscn
| Element | Type | Current State | Replacement Candidate |
|---------|------|---------------|----------------------|
| SkillIcon | PanelContainer (56x70) | Styled panel | Frame/ |
| Icon | TextureRect (40x40) | Dynamic skill images | Icon_PictoIcons/ or IconMisc/ |
| SkillName | Label (9px) | Text only | - |

### character_card.tscn
| Element | Type | Current State | Replacement Candidate |
|---------|------|---------------|----------------------|
| CharacterCard | PanelContainer | Styled panel | Frame/ |
| Portrait | TextureRect (160x160) | Character portraits | - (need character art) |
| NameLabel | Label (14px) | Text only | - |
| HealthLabel | Label (11px) | "HP 100" text | Icon for HP? |
| AttackLabel | Label (11px) | "ATK 10" text | Icon for ATK? |
| DefenseLabel | Label (11px) | "DEF 8" text | Icon for DEF? |
| SpeedLabel | Label (11px) | "SPD 5" text | Icon for SPD? |
| IncomeLabel | Label (11px) | "INC 3" text | Icon for gold? |

### currency_display.tscn
| Element | Type | Current State | Replacement Candidate |
|---------|------|---------------|----------------------|
| GemsLabel | Label (18px) | Uses emoji "0" | Icon_ItemIcons/ (gem icons) |
| RerollTokensLabel | Label (18px) | Uses emoji "0" | Icon_ItemIcons/ (ticket/token icon) |

---

## Main Scenes

### main.tscn
| Element | Type | Current State | Replacement Candidate |
|---------|------|---------------|----------------------|
| TransitionLayer/ColorRect | ColorRect | Black overlay | - |

### main_menu.tscn
| Element | Type | Current State | Replacement Candidate |
|---------|------|---------------|----------------------|
| Background | ColorRect | Solid color (#26263333) | Could use tiled background |
| Title | Label (48px) | "AUTO BATTLER" text | Label-Title/ decorations |
| Subtitle | Label (20px) | "A Roguelike Journey" | - |
| PlayButton | Button (280x60) | Default Godot button | Button/ |
| CollectionButton | Button (280x60) | Default Godot button | Button/ |
| QuitButton | Button (280x60) | Default Godot button | Button/ |
| GemsLabel | Label (18px) | Emoji text | Icon_ItemIcons/ (gem) |
| RerollTokensLabel | Label (18px) | Emoji text | Icon_ItemIcons/ (ticket) |

### collection.tscn
| Element | Type | Current State | Replacement Candidate |
|---------|------|---------------|----------------------|
| Background | ColorRect | Solid color | Could use tiled background |
| Title | Label (24px) | "CHARACTER COLLECTION" | Label-Title/ |
| CharacterGrid | GridContainer | Container only | - |
| CharacterDetailsPanel | Panel | Overlay panel | Frame/ or Popup/ |
| BackButton | Button | "< BACK" text | Button/ |
| CloseDetailsButton | Button | "< BACK" text | Button/ |

### character_details.tscn
| Element | Type | Current State | Replacement Candidate |
|---------|------|---------------|----------------------|
| Panel (root) | Panel | Full-screen overlay | Frame/ |
| Portrait | TextureRect (100x100) | Character image | - |
| NameLabel | Label (20px) | Text | - |
| RankLabel | Label (12px) | "Rank 1" text | - |
| RankProgressBar | ProgressBar | Default bar | Slider/ |
| HSeparator (x4) | HSeparator | Default lines | UI_Etc/ decorative lines |
| StatsTitle | Label (14px) | "STATS" | - |
| StatsGrid | GridContainer | HP/ATK/DEF/SPD/INC labels | Icon_PictoIcons/ for stat icons |
| EquipmentTitle | Label (14px) | "EQUIPPED ITEMS" | - |
| EquippedItemsContainer | HBoxContainer | Contains item_slot instances | - |
| ItemsTitle | Label (14px) | "AVAILABLE ITEMS" | - |
| ItemsGrid | GridContainer | Contains item_slot instances | - |
| SkillsTitle | Label (14px) | "UNLOCKED SKILLS" | - |
| SkillsGrid | GridContainer | Contains skill_icon instances | - |
| BackButton | Button | "< BACK" | Button/ |

### draft.tscn
| Element | Type | Current State | Replacement Candidate |
|---------|------|---------------|----------------------|
| Background | ColorRect | Solid color (#1E1C2E) | Could use background texture |
| InstructionLabel | Label (20px) | "SELECT CHARACTER 1 OF 3" | - |
| SelectedTitle | Label (12px) | "YOUR TEAM" | - |
| SelectedDisplay | HBoxContainer | Team slot display | - |
| HSeparator | HSeparator | Default line | UI_Etc/ |
| OptionsTitle | Label (14px) | "AVAILABLE CHARACTERS" | - |
| OptionsContainer | VBoxContainer | Character options | - |
| RerollButton | Button (44px height) | "REROLL (0 tokens)" | Button/ |
| ConfirmButton | Button (44px height) | "START RUN" | Button/ |
| BackButton | Button | "< BACK" | Button/ |

### run_view.tscn
| Element | Type | Current State | Replacement Candidate |
|---------|------|---------------|----------------------|
| Background | ColorRect | Solid color | Background texture |
| TopBar | Panel | Stats display area | Frame/ |
| RoundLabel | Label (20px) | "ROUND 1" | - |
| ReputationLabel | Label (14px) | Emoji text | Icon for heart/reputation |
| WinsLabel | Label (14px) | Emoji text | Icon for star/wins |
| GoldLabel | Label (14px) | Emoji text | Icon_ItemIcons/ (coins) |
| TeamPanel | Panel | Team display area | Frame/ |
| TeamTitle | Label (18px) | "YOUR TEAM" | - |
| TeamContainer | HBoxContainer | Character cards | - |
| CenterPanel | Panel | Action area | Frame/ |
| PhaseLabel | Label (22px) | "ENCOUNTER PHASE" | - |
| PhaseDescription | Label (14px) | Instructions | - |
| ActionButton | Button (50px height) | "CHOOSE ENCOUNTER" | Button/ |
| MenuButton | Button | "MENU" | Button/ |
| ConcedeButton | Button | "CONCEDE" | Button/ (red variant) |
| ConcedeConfirmDialog | ConfirmationDialog | Default dialog | Popup/ |

### encounter_select.tscn
| Element | Type | Current State | Replacement Candidate |
|---------|------|---------------|----------------------|
| Background | ColorRect | Solid color | Background texture |
| Title | Label (24px) | "CHOOSE AN ENCOUNTER" | Label-Title/ |
| Subtitle | Label (14px) | "Select one to proceed" | - |
| ScrollContainer | ScrollContainer | Options list | - |
| OptionsContainer | VBoxContainer | Encounter cards | - |
| BackButton | Button (hidden) | Debug only | Button/ |

### encounter_execute.tscn
| Element | Type | Current State | Replacement Candidate |
|---------|------|---------------|----------------------|
| Background | ColorRect | Solid color | Background texture |
| TitleLabel | Label (28px) | "Encounter Title" | Label-Title/ |
| ContentContainer | Control | Dynamic content | - |
| SkipButton | Button | "SKIP" | Button/ |
| CompleteButton | Button | "COMPLETE ENCOUNTER" | Button/ |

### combat_select.tscn
| Element | Type | Current State | Replacement Candidate |
|---------|------|---------------|----------------------|
| Background | ColorRect | Solid color | Background texture |
| Title | Label (24px) | "CHOOSE A BATTLE" | Label-Title/ |
| Subtitle | Label (14px) | "Select your opponent" | - |
| ScrollContainer | ScrollContainer | Options list | - |
| OptionsContainer | VBoxContainer | Combat options | - |
| BackButton | Button (hidden) | Debug only | Button/ |

### combat_stub.tscn
| Element | Type | Current State | Replacement Candidate |
|---------|------|---------------|----------------------|
| Background | ColorRect | Solid red-tinted color | Background texture |
| Title | Label (36px) | "COMBAT" | Label-Title/ |
| OpponentLabel | Label (20px) | "Opponent: Unknown" | - |
| StubNotice | Label (14px) | Warning text | - |
| InstructionLabel | Label (16px) | "Choose the outcome:" | - |
| WinButton | Button (120x60) | "WIN" | Button/ (green variant) |
| LoseButton | Button (120x60) | "LOSE" | Button/ (red variant) |
| ResultLabel | Label (28px) | Dynamic result | - |

### run_results.tscn
| Element | Type | Current State | Replacement Candidate |
|---------|------|---------------|----------------------|
| Background | ColorRect | Solid color | Background texture |
| ResultTitle | Label (48px) | "VICTORY!" or "DEFEAT" | Label-Title/ |
| StatsPanel | PanelContainer | Custom StyleBoxFlat | Frame/ |
| StatsTitle | Label (20px) | "RUN STATISTICS" | - |
| RoundsLabel | Label (16px) | "Rounds Completed: 0" | - |
| WinsLabel | Label (16px) | "Victories: 0" | Icon for victories |
| LossesLabel | Label (16px) | "Defeats: 0" | Icon for defeats |
| GoldEarnedLabel | Label (16px) | "Gold Earned: 0" | Icon_ItemIcons/ (coins) |
| ReputationLabel | Label (16px) | "Final Reputation: 0/20" | Icon for reputation |
| RewardsPanel | PanelContainer | Custom StyleBoxFlat | Frame/ |
| RewardsTitle | Label (20px) | "REWARDS" | - |
| GemsLabel | Label (24px) | "+100 Gems" emoji | Icon_ItemIcons/ (gem) |
| RankUpsPanel | PanelContainer | Custom StyleBoxFlat | Frame/ |
| RankUpsTitle | Label (24px) | "RANK UPS!" | Label-Title/ |
| ContinueButton | Button (280x60) | "CONTINUE" | Button/ |

### debug_menu.tscn
| Element | Type | Current State | Replacement Candidate |
|---------|------|---------------|----------------------|
| Background | ColorRect | Semi-transparent black | - |
| Panel | PanelContainer | Default panel | Popup/ or Frame/ |
| Title | Label (28px) | "DEBUG MENU" | - |
| HSeparator (x4) | HSeparator | Default lines | UI_Etc/ |
| Various Buttons | Button | Default buttons | Button/ |
| CloseButton | Button (50px height) | "CLOSE" | Button/ |

---

## Emoji Usage (Replace with Icons)

The following emojis are used in code (via `GameConstants`):

| Emoji | Usage | Replacement Candidate |
|-------|-------|----------------------|
| `EMOJI_GEM` | Currency display | Icon_ItemIcons/ (gem/crystal) |
| `EMOJI_REROLL` | Reroll tokens | Icon_ItemIcons/ (ticket/scroll) |
| `EMOJI_HEART` | Reputation | Icon_PictoIcons/ or IconMisc/ (heart) |
| `EMOJI_STAR` | Win counter | Icon_PictoIcons/ or IconMisc/ (star) |
| `EMOJI_GOLD` | Gold currency | Icon_ItemIcons/ (coins/pouch) |

---

## Priority Recommendations

### High Priority (Most Visual Impact)
1. **Buttons** - Replace all Button nodes with styled textures from `Button/`
2. **Panels/Frames** - Replace PanelContainer styling with `Frame/` decorations
3. **Currency Icons** - Replace emojis with proper gem/coin/token icons from `Icon_ItemIcons/`
4. **Item Icons** - Already dynamic, ensure proper icons from `Icon_EquipIcons/` and `Icon_ItemIcons/`

### Medium Priority
5. **Stat Icons** - Add small icons next to HP/ATK/DEF/SPD/INC labels
6. **Title Decorations** - Use `Label-Title/` for section headers
7. **Separators** - Replace HSeparator with decorative lines from `UI_Etc/`
8. **Progress Bars** - Style with `Slider/` assets

### Lower Priority
9. **Backgrounds** - Consider tiled or textured backgrounds
10. **Dialogs** - Style confirmation dialogs with `Popup/` assets
11. **Chests** - Use `Chest/` icons for reward displays

---

## Notes

- Icon sizes should match: 56px for items, 40px for skills, 18px inline with text
- The `NoShadow/64` or `NoShadow/128` folders are best for crisp scaling
- Consider creating a theme resource to apply button styles globally
- Character portraits are NOT included in this icon pack (need separate art)
