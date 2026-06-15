extends Node

## Static color getters for the light/dark UI theme toggle.
## Registered as an autoload named "UITheme" so every script can call
## UITheme.bg(), UITheme.gold(), etc. without any preload.
## Every UI file reads from here so theme changes require only one place.
##
## Light theme: panels are warm cream/parchment; text is dark brown.
## Dark theme:  panels are near-black; text is gold (the original default look).
##
## Semantic colors (red HP fill, green complete, purple goop, etc.) are
## intentionally excluded — those carry meaning and should not flip.


## Panel / card background.
static func bg(alpha: float = 1.0) -> Color:
	if SceneManager.light_mode:
		return Color(1.000, 0.984, 0.949, alpha)   # #FFFBF2
	return Color(0.078, 0.059, 0.039, alpha)        # #140F0A


## Full-screen dimming overlay (behind modal panels).
static func overlay(alpha: float = 0.88) -> Color:
	if SceneManager.light_mode:
		return Color(0.882, 0.859, 0.796, alpha)   # #E1DBCB
	return Color(0.0, 0.0, 0.0, alpha)             # #000000


## Panel / widget border.
static func border() -> Color:
	if SceneManager.light_mode:
		return Color(0.659, 0.573, 0.420, 0.90)   # #A8926B
	return Color(0.50, 0.40, 0.20, 0.90)           # #806633


## Lighter border variant used on small HUD widgets.
static func border_dim() -> Color:
	if SceneManager.light_mode:
		return Color(0.737, 0.675, 0.569, 0.65)   # #BCAC91
	return Color(0.40, 0.30, 0.14, 0.65)           # #664D24


## Accent / selected / title text.
static func gold() -> Color:
	if SceneManager.light_mode:
		return Color(0.078, 0.059, 0.039, 1.0)    # #140F0A  stark charcoal
	return Color(0.95, 0.85, 0.45, 1.0)            # #F2D973


## Primary body / NPC text.
static func text() -> Color:
	if SceneManager.light_mode:
		return Color(0.231, 0.204, 0.157, 1.0)    # #3B3428
	return Color(0.82, 0.76, 0.64, 1.0)            # #D1C2A3


## Dimmed / unselected / secondary text.
static func dim(alpha: float = 1.0) -> Color:
	if SceneManager.light_mode:
		return Color(0.388, 0.349, 0.282, alpha)   # #635948
	return Color(0.60, 0.55, 0.45, alpha)           # #998C73


## Hint / footer text (smallest, most subdued).
static func hint() -> Color:
	if SceneManager.light_mode:
		return Color(0.541, 0.486, 0.392, 1.0)    # #8A7C64
	return Color(0.42, 0.38, 0.30, 1.0)            # #6B614D


## Section / category header text.
static func section() -> Color:
	if SceneManager.light_mode:
		return Color(0.478, 0.380, 0.192, 1.0)    # #7A6131
	return Color(0.60, 0.50, 0.28, 1.0)            # #998047
