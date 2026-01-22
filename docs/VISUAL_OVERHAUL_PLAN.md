# Visual Overhaul Plan: Auto-Battle Journey

## Executive Summary

This document outlines a comprehensive visual transformation of Auto-Battle Journey from its current **functional prototype** state to a **production-ready, visually delightful** experience. The game has solid bones—a cohesive fantasy palette, modular components, and clean architecture—but lacks the polish, motion, and visual depth that separates amateur from professional.

**Current State:** Static, state-based UI with instant transitions and flat panels.
**Target State:** Living, breathing interface with fluid motion, depth, particle effects, and satisfying micro-interactions.

---

## Part 1: Motion & Animation System

### 1.1 Scene Transitions

**Problem:** Scenes change instantly, creating jarring user experience.

**Solution:** Implement a transition manager with multiple effect types.

```
Transition Types:
├── Fade (default) - 0.3s fade to black, fade in
├── Slide - New scene slides in from direction
├── Scale - Zoom out old, zoom in new
├── Dissolve - Particle-based magical dissolve
└── Wipe - Radial or linear wipe effect
```

**Implementation:**
- Create `TransitionManager` autoload
- Use `CanvasLayer` at highest z-index for transition effects
- `ColorRect` with shader for complex transitions
- Standardize all `SceneManager.go_to()` calls to use transitions

### 1.2 Panel & Element Entrance Animations

**Problem:** UI elements appear instantly—no sense of arrival or importance.

**Solution:** Staggered entrance animations for all major elements.

```
Animation Patterns:
├── Slide + Fade - Elements slide in while fading (most common)
├── Scale Pop - Elements scale from 0.8→1.0 with overshoot
├── Cascade - Sequential delay (50-100ms per element)
└── Unfold - Panels "unfold" from center
```

**Priority Implementations:**
| Screen | Animation |
|--------|-----------|
| Main Menu | Buttons cascade from bottom, title scales in |
| Collection | Cards cascade in rows, detail panel slides from right |
| Draft | Choice cards fan in from top, team slots pop up from bottom |
| Run View | Stats bar slides down, options unfold, team pops up |
| Combat/Encounter Select | Options cascade, team display slides in |
| Results | Stats count up numerically, rewards pop in sequentially |

### 1.3 Button & Interactive Feedback

**Problem:** Buttons only change color—no satisfying "click" feel.

**Solution:** Multi-layered interaction feedback.

```
Button States:
├── Hover
│   ├── Scale: 1.0 → 1.03 (subtle grow)
│   ├── Glow: Add outer glow shader
│   └── Sound: Soft hover sound
├── Press
│   ├── Scale: 1.0 → 0.95 (compress)
│   ├── Brightness: Darken slightly
│   └── Sound: Satisfying click
└── Release
    ├── Scale: 0.95 → 1.0 with overshoot (bounce)
    └── Ripple: Subtle ripple effect from press point
```

### 1.4 Card Interactions

**Problem:** Cards only modulate brightness—feels flat.

**Solution:** 3D-inspired card interactions.

```
Card Hover Effects:
├── Lift: Y offset -4px (floating effect)
├── Shadow: Drop shadow grows/intensifies
├── Tilt: Subtle rotation toward cursor (±3°)
├── Glow: Rarity-colored edge glow
└── Scale: 1.0 → 1.05

Card Selection:
├── Bounce: Scale overshoot animation
├── Particle Burst: Rarity-colored particles emit
└── Sound: Satisfying selection sound
```

### 1.5 Continuous Ambient Motion

**Problem:** Static screens feel "dead" when nothing is happening.

**Solution:** Subtle ambient animations.

```
Ambient Effects:
├── Background: Slow parallax layers or particle drift
├── Gold Elements: Subtle shimmer/pulse on gold accents
├── Character Portraits: Idle breathing/bob animation
├── Gem Currency: Gentle rotation or sparkle
└── Buttons: Very subtle pulse on primary actions
```

---

## Part 2: Visual Depth & Polish

### 2.1 Panel Enhancement

**Problem:** Panels are flat `StyleBoxFlat` with solid colors—no texture or depth.

**Solution:** Layered panel composition with visual depth.

```
Panel Layer Stack (bottom to top):
├── Base: Dark background color
├── Gradient: Subtle vertical gradient overlay
├── Texture: Very subtle noise/grain texture (5-10% opacity)
├── Inner Shadow: Soft vignette around edges
├── Border: Styled border (current implementation)
├── Highlight: Top edge highlight line (1px lighter)
└── Glow: Optional outer glow for focused/selected panels

Panel Types Upgrade:
├── Standard Panel → Add gradient + texture
├── Card Panel → Add inner glow + bevel effect
├── Button Panel → Add gradient + highlight + pressed shadow
└── Overlay Panel → Add blur backdrop + stronger vignette
```

### 2.2 Typography Enhancement

**Problem:** Text is functional but lacks visual interest and hierarchy clarity.

**Solution:** Enhanced text styling with effects.

```
Text Effects:
├── Titles
│   ├── Gradient fill (gold → lighter gold)
│   ├── Drop shadow (stronger, 3px offset)
│   ├── Subtle outer glow
│   └── Optional: Letter-by-letter entrance animation
├── Headers
│   ├── Solid gold with crisp shadow
│   └── Underline decoration option
├── Body Text
│   ├── Improved line spacing
│   └── Better contrast ratios
├── Stat Numbers
│   ├── Animated counting (for changes)
│   ├── Color flash on value changes
│   └── Size pulse on important changes
└── Damage/Heal Numbers
    ├── Float up + fade animation
    ├── Scale pop on appearance
    └── Color-coded (red damage, green heal)
```

### 2.3 Icon & Asset Enhancement

**Problem:** Icons are displayed as flat TextureRects with no visual treatment.

**Solution:** Visual framing and effects for icons.

```
Icon Treatments:
├── Rarity Frame: Colored border frame around items/skills
├── Glow Underlayer: Rarity-colored glow behind icon
├── Shine Effect: Animated diagonal shine across icon (on hover/get)
├── Quality Badge: Small corner badge for rarity
└── Locked/Unavailable: Desaturation + lock overlay
```

### 2.4 Character Portrait Enhancement

**Problem:** Portraits are simple TextureRects in cards.

**Solution:** Framed, lit character presentations.

```
Portrait Effects:
├── Vignette: Soft edge fade into card background
├── Rim Light: Subtle edge lighting effect
├── Background: Class-themed color gradient behind character
├── Idle Animation: Subtle breathing/movement
├── Rarity Border: Ornate frame matching rarity
└── Glow: Rarity-colored glow behind frame
```

---

## Part 3: Particle Effects & Visual Feedback

### 3.1 Particle System Additions

**Problem:** No particle effects anywhere—missing opportunities for visual juice.

**Solution:** Strategic particle implementations.

```
Particle Opportunities:
├── Currency
│   ├── Gems: Sparkle particles around gem icon
│   ├── Gold: Coin particles when spending/gaining
│   └── Collection: Floating particles on rare items
├── Cards
│   ├── Legendary: Continuous golden particle aura
│   ├── Epic: Subtle purple particle wisps
│   ├── Selection: Burst on select
│   └── Hover: Gentle particle rise
├── Buttons
│   ├── Primary Action: Subtle glow particles
│   └── Press: Burst effect from button
├── Screens
│   ├── Main Menu: Floating magical particles in background
│   ├── Victory: Celebratory particle explosion
│   └── Draft: Sparkle trail as cards are selected
└── Combat
    ├── Damage: Impact particles
    ├── Heal: Rising green particles
    └── Special: Skill-specific particle effects
```

### 3.2 Number Pop-ups & Feedback

**Problem:** No visual feedback for value changes.

**Solution:** Floating number system.

```
Floating Number Types:
├── Damage: Red, rises + fades, scale pop
├── Heal: Green, rises + fades, scale pop
├── Gold: Yellow, rises toward currency display
├── XP: Blue/purple, rises with trail
└── Critical: Larger, with shake + particles

Animation: Scale in (0→1.2→1.0), float up 50px, fade out over 1s
```

### 3.3 Screen Shake & Impact

**Problem:** Actions feel weightless.

**Solution:** Subtle screen shake for impactful moments.

```
Shake Triggers:
├── Big damage dealt/received: Medium shake
├── Critical hit: Strong shake
├── Button press (optional): Micro shake
├── Error/invalid action: Quick horizontal shake
└── Victory/defeat: Contextual shake pattern
```

---

## Part 4: Shader Effects

### 4.1 Essential Shaders to Implement

```
Shader Library:
├── Glow Shader
│   └── Configurable outer glow for buttons, cards, icons
├── Gradient Shader
│   └── Multi-stop gradients for panels and text
├── Shine Shader
│   └── Animated diagonal light sweep
├── Dissolve Shader
│   └── Particle-based appear/disappear
├── Blur Shader
│   └── Background blur for modals/overlays
├── Vignette Shader
│   └── Soft edge darkening for panels/cards
├── Outline Shader
│   └── Glowing outline for selected elements
├── Noise/Grain Shader
│   └── Subtle texture overlay
└── Color Adjustment Shader
    └── Saturation, brightness for disabled states
```

### 4.2 Material Presets

```
Shader Materials:
├── mat_gold_glow: Gold outer glow (for legendary items)
├── mat_epic_glow: Purple outer glow
├── mat_button_shine: Animated button shine
├── mat_card_hover: Lift + glow combination
├── mat_panel_gradient: Vertical gradient overlay
├── mat_blur_backdrop: Background blur for overlays
└── mat_disabled: Desaturated + darkened
```

---

## Part 5: Screen-by-Screen Polish Pass

### 5.1 Main Menu

```
Current: Static buttons, plain background
Target:
├── Background: Animated particle field or subtle parallax
├── Title: Animated entrance, gradient fill, glow
├── Buttons: Staggered entrance, hover glow, press bounce
├── Currency Display: Gem sparkle, animated counters
└── Ambient: Slow floating particles, subtle UI pulse
```

### 5.2 Collection Screen

```
Current: Grid of cards, slide-in detail panel
Target:
├── Cards: Cascade entrance, hover lift + glow
├── Rarity Effects: Legendary cards have particle aura
├── Detail Panel: Slide in with blur backdrop behind
├── Stats: Animated bar fills, number count-up
├── Equipment Slots: Glow when empty, shine when filled
└── Navigation: Smooth scroll with momentum
```

### 5.3 Draft Screen

```
Current: Three static card choices
Target:
├── Card Reveal: Cards flip/unfold into view
├── Hover: 3D tilt effect, rarity glow intensifies
├── Selection: Card scales up, particles burst, flies to team
├── Team Slots: Pop up animation, glow when expecting card
├── Confirmation: Satisfying button feedback
└── Transition: Cards scatter/dissolve on completion
```

### 5.4 Run View (Core Loop)

```
Current: Stats bar, options list, team display
Target:
├── Stats Bar: Slide down entrance, numbers animate on change
├── Options: Cascade in, hover highlights entire row
├── Team Display: Character idle animations, health bar pulses if low
├── Gold Counter: Coin particles on gain/spend
├── Day/Stage: Animated counter, visual progress indicator
└── Ambient: Subtle background movement, UI breathes
```

### 5.5 Combat/Encounter Select

```
Current: Options scroll, team display
Target:
├── Enemy Display: Dramatic entrance, threat-level glow
├── Options: Cascade with difficulty color coding
├── Team Display: Ready stance, anticipation animation
├── Selection: Option highlights, confirmation feedback
└── Transition: Battle whoosh/wipe transition
```

### 5.6 Results Screen

```
Current: Static stats display
Target:
├── Title: Victory/Defeat with appropriate fanfare
├── Stats: Animated count-up with delays between stats
├── Rewards: Pop in sequentially with sparkle
├── XP Bar: Animated fill with particles at fill point
├── Level Up: Special celebration effect
└── Continue Button: Pulse to draw attention
```

---

## Part 6: Implementation Architecture

### 6.1 New Files to Create

```
autoloads/
├── transition_manager.gd      # Scene transitions
├── animation_manager.gd       # Reusable animation presets
├── particle_manager.gd        # Particle system manager
└── feedback_manager.gd        # Screen shake, sounds coordination

scripts/effects/
├── floating_number.gd         # Number pop-up controller
├── floating_number.tscn       # Number pop-up scene
├── button_effects.gd          # Button hover/press effects
├── card_effects.gd            # Card interaction effects
├── panel_effects.gd           # Panel entrance/ambient effects
└── particle_presets.gd        # Common particle configurations

shaders/
├── glow.gdshader              # Outer glow effect
├── gradient.gdshader          # Multi-stop gradient
├── shine.gdshader             # Animated shine sweep
├── dissolve.gdshader          # Particle dissolve
├── blur.gdshader              # Gaussian blur
├── vignette.gdshader          # Edge darkening
├── outline.gdshader           # Glowing outline
└── grain.gdshader             # Noise texture overlay

themes/
├── materials/                 # Shader material presets
│   ├── mat_gold_glow.tres
│   ├── mat_button_shine.tres
│   └── ...
└── enhanced_game_theme.tres   # Enhanced theme resource
```

### 6.2 Modification Priority Order

```
Phase 1: Foundation (Core Systems)
├── 1. TransitionManager - Scene transitions
├── 2. AnimationManager - Tween presets and utilities
├── 3. Core shaders - Glow, gradient, shine
└── 4. Button effects - Hover/press/release

Phase 2: Cards & Panels
├── 5. Panel enhancements - Gradients, depth
├── 6. Card effects - Hover, selection, rarity
├── 7. Particle system - Basic particle presets
└── 8. Floating numbers - Value change feedback

Phase 3: Screen Polish
├── 9. Main Menu polish
├── 10. Collection polish
├── 11. Draft polish
├── 12. Run View polish
├── 13. Combat/Encounter polish
└── 14. Results polish

Phase 4: Ambient & Details
├── 15. Background animations
├── 16. Idle character animations
├── 17. Currency sparkle effects
├── 18. Sound integration points
└── 19. Final tweaking pass
```

### 6.3 Constants Additions

```gdscript
# Animation timing constants (add to GameConstants.gd)
const ANIM_DURATION_INSTANT = 0.1
const ANIM_DURATION_FAST = 0.2
const ANIM_DURATION_NORMAL = 0.3
const ANIM_DURATION_SLOW = 0.5
const ANIM_DURATION_DRAMATIC = 0.8

const ANIM_EASE_STANDARD = Tween.EASE_OUT
const ANIM_TRANS_STANDARD = Tween.TRANS_CUBIC
const ANIM_TRANS_BOUNCE = Tween.TRANS_BACK

const CASCADE_DELAY = 0.05  # Delay between cascade elements

# Visual effect constants
const HOVER_SCALE = 1.03
const PRESS_SCALE = 0.95
const CARD_HOVER_LIFT = 4.0
const CARD_HOVER_SCALE = 1.05

const GLOW_COLOR_LEGENDARY = Color("#FFD700")
const GLOW_COLOR_EPIC = Color("#9932CC")
const GLOW_COLOR_RARE = Color("#4169E1")
const GLOW_COLOR_UNCOMMON = Color("#32CD32")

const PARTICLE_RATE_SUBTLE = 5
const PARTICLE_RATE_NORMAL = 15
const PARTICLE_RATE_INTENSE = 30

const SHAKE_INTENSITY_MICRO = 2.0
const SHAKE_INTENSITY_LIGHT = 5.0
const SHAKE_INTENSITY_MEDIUM = 10.0
const SHAKE_INTENSITY_HEAVY = 20.0
```

---

## Part 7: Quality Benchmarks

### 7.1 Visual Quality Checklist

```
□ No instant scene changes - all transitions animated
□ No instant element appearances - all entrances animated
□ All buttons have hover + press + release feedback
□ All cards have hover effects with depth
□ All panels have gradient/texture depth
□ Rarity system is visually distinct (particles, glow)
□ Numbers animate when changing
□ Currency has sparkle/particle effects
□ At least one ambient animation per screen
□ Results screen has celebration effects
□ Loading states have visual feedback
□ Error states have appropriate feedback
```

### 7.2 Performance Targets

```
Target: 60 FPS on mobile devices
├── Limit simultaneous particles to 100-200
├── Use object pooling for floating numbers
├── Shader complexity appropriate for mobile
├── Disable expensive effects on low-end option
└── Profile and optimize hot paths
```

### 7.3 Consistency Standards

```
Animation Timing:
├── Fast actions: 0.1-0.2s
├── Standard transitions: 0.3s
├── Emphasis animations: 0.5s
├── Dramatic reveals: 0.8s
└── Always use easing (never linear)

Visual Language:
├── Gold = valuable, important, action
├── Glow = interactive, attention
├── Particles = reward, magic, rarity
├── Shake = impact, error
└── Scale = importance, selection
```

---

## Part 8: Reference & Inspiration

### 8.1 Games to Reference

```
Visual Polish References:
├── Hearthstone - Card reveals, pack opening, gold usage
├── Slay the Spire - Card effects, combat feedback, map flow
├── Monster Train - UI animations, card upgrades, layer depth
├── Legends of Runeterra - Premium feel, smooth animations
├── Clash Royale - Punchy feedback, celebration effects
└── Genshin Impact - Menu polish, character presentations
```

### 8.2 Specific Effects to Study

```
Must-Have Effects:
├── Card flip/reveal animation (Hearthstone)
├── Victory celebration particles (any mobile game)
├── Number pop-ups with juice (RPGs)
├── Button press satisfaction (iOS/Material design)
├── Progress bar fills (XP, health, loading)
└── Rarity glow and particles (gacha games)
```

---

## Summary

This overhaul transforms Auto-Battle Journey from a **functional game** into a **delightful experience**. The focus areas are:

1. **Motion** - Everything moves with purpose and polish
2. **Depth** - Panels and cards feel dimensional, not flat
3. **Feedback** - Every interaction has satisfying response
4. **Particles** - Magic and reward moments sparkle
5. **Consistency** - Unified visual language throughout

The implementation follows a phased approach, starting with foundational systems (transitions, animation manager) before moving to component polish and finally ambient details. Each phase builds on the previous, allowing for iterative improvement and testing.

**End goal:** A game that feels premium, polished, and professionally produced—where the visual presentation matches the quality of the underlying gameplay systems.
