extends RefCounted

## SINGLE SOURCE OF TRUTH for tuning. Edit values HERE — the rest of the app reads from here.
## (Referenced via `preload`, so changes apply on the next `godot --path .` with no re-import.)
##
## NOT here, by design: the categories and their levels (which problems each one deals) live in
## `data/categories.gd`.

# --- Rounds ------------------------------------------------------------------
const DECK_SIZE := 20             # cards per round (a smaller level uses each fact once)
const RECENT_HISTORY := 10        # most recent right/wrong answers kept per fact

# --- Layout ------------------------------------------------------------------
const VIEWPORT_W := 720.0
const VIEWPORT_H := 1280.0
const CARD_SIZE := Vector2(600, 440)
const CARD_CENTER_Y := 560.0      # the card's vertical centre on screen
const CARD_RADIUS := 36
const ANSWER_BUTTON_SIZE := Vector2(260, 160)
const ANSWER_BUTTON_Y := 1040.0   # vertical centre of the ✗ / ✓ buttons

# --- Type sizes --------------------------------------------------------------
const FONT_TITLE := 64
const FONT_HEADER := 34
const FONT_BUTTON := 34
const FONT_CARD := 120            # the problem on the card
const FONT_CARD_ANSWER := 150     # the answer on the flipped card
const FONT_ANSWER_ICON := 96      # ✗ / ✓

# --- Colors ------------------------------------------------------------------
const BACKGROUND := Color("dfeaf5")
const INK := Color("24324a")
const CARD_FRONT := Color("fffaf0")
const CARD_BACK := Color("fff2c4")
const CARD_EDGE := Color("c9b98f")
const ANSWER_INK := Color("3a6fd8")
const RIGHT := Color("3fae5a")
const WRONG := Color("e0503a")

# --- Feel / animation --------------------------------------------------------
const FLIP_TIME := 0.28           # seconds for the whole flip (half to edge-on, half back)
const DEAL_TIME := 0.22           # seconds for the next card to slide in
const BUTTON_DISABLED_ALPHA := 0.25
