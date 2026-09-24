# Math Flash

Math flash cards for Android, made in Godot 4.6 for homeschool practice (portrait, touch).

Pick a level. A card shows a problem: tap it and it flips over to show the answer. Then tap
✗ or ✓ to say whether you got it, and the next card comes up. A round is 20 cards and ends with
your score and a list of the facts to practise. Every answer is saved per fact, so the app can
later work out what needs more practice.

## Levels

| Category | Level | Facts |
| --- | --- | --- |
| Addition | 1 | Sums to 5 (0 + 0 … 5 + 0) |
| | 2 | Sums to 10 |
| | 3 | Both numbers 0–10 (up to 10 + 10) |
| | 4 | Two digits + one digit, no carrying (e.g. 23 + 4) |

Levels are defined in `data/categories.gd` by their operand ranges plus optional
`max_result` / `no_regroup` filters. To add a new category (subtraction, multiplication, …), add
an entry there and its operator in `Problems.answer`. The menu picks it up automatically.

## Stats & profiles

`scripts/stats.gd` saves each answer to `user://stats_<profile>.cfg`, with one section per fact
key (`"3+4"`) holding `right`, `wrong`, `recent` (the last 10 answers) and `last_seen`. Each
menu button shows that level's accuracy. For now everything goes to the `"default"` profile;
supporting more students just needs a picker that sets `Stats.profile_id`.

## Project layout

| Path | Role |
| --- | --- |
| `data/config.gd` | **Single source of truth** for tuning: deck size, layout, colors, type sizes, animation timing |
| `data/categories.gd` | Categories and their levels |
| `scripts/problems.gd` | Pure problem generation: every fact in a level, plus the seeded deal. No nodes, so it can be tested headless |
| `scripts/round.gd` | Pure model of one round: the deck, the current card, and the results |
| `scripts/game_state.gd` | Autoload: which screen is up, the current round, and the signals |
| `scripts/stats.gd` | Autoload: per-profile, per-fact answer history |
| `scripts/menu_screen.gd` | Level picker |
| `scripts/play_screen.gd` | Card, ✗ / ✓ buttons, and the end-of-round summary |
| `scripts/card.gd`, `scripts/answer_button.gd` | Placeholder art drawn in code |
| `scripts/ui_theme.gd` | Shared button and label styling |
| `tests/` | Headless logic tests and a bot playtest |

## Run

On a fresh clone, or after adding a script with a new `class_name`, rescan first:

```sh
godot --headless --path . --import
```

```sh
godot --path .                  # play
godot --path . -- --level=3     # jump straight into Addition level 3
godot --headless --path . --script res://tests/test_problems.gd   # logic tests
godot --headless --path . res://tests/Playtest.tscn               # bot plays a round of every level
```

## Phone (Android)

Builds a debug-signed APK using the "Android" preset in `export_presets.cfg`. The SDK and
keystore paths come from the Godot editor settings, which it shares with perch and psyche:

```sh
godot --headless --path . --export-debug "Android" build/math-flash.apk
~/Android/Sdk/platform-tools/adb install -r build/math-flash.apk
```
