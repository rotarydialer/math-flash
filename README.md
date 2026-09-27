# Math Flash

Math flash cards for Android, made in Godot 4.6 for homeschool practice (portrait, touch).

Pick a category and a level. A card shows a problem: tap it and it flips over to show the answer. Then tap
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
| | 5 | Two digits + one digit, with carrying (e.g. 27 + 5) |
| | 6 | Two digits + two digits, no carrying (e.g. 23 + 45) |
| Subtraction | 1 | From 5 or less (5 − 0 … 0 − 0) |
| | 2 | From 10 or less |
| | 3 | Up to 20 − 10, answers 0–10 (reverse of Addition 3) |
| | 4 | Two digits − one digit, no borrowing (e.g. 47 − 3) |
| Multiplication | 1 | Times 0, 1, 2 (both ways round: 7 × 2 and 2 × 7) |
| | 2 | Times 3, 4, 5 (both ways round) |
| | 3 | Times 6 to 9 (both ways round) |
| | 4 | Everything up to 12 × 12, except × 1 |
| Division | 1 | Divide by 1 and 2 (answers 0–10) |
| | 2 | Divide by 3, 4, 5 |
| | 3 | Divide by 6 to 9 |
| | 4 | Everything up to 144 ÷ 12, except ÷ 1 and answers of 1 |

Answers are never negative, and division always comes out even (no remainders, never ÷ 0).

Levels are defined in `data/categories.gd` by their operand ranges plus optional
`max_result` / `no_regroup` / `regroup_only` / `both_orders` / `skip_numbers` options. To add a new category, add an entry
there and its operator in `Problems.answer` / `Problems.SYMBOLS`. The menu picks it up
automatically.

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
| `scripts/menu_screen.gd` | Two-page picker: categories, then that category's levels |
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
godot --path . -- --category=subtraction --level=2   # ...or another category's level
godot --headless --path . --script res://tests/test_problems.gd   # logic tests
godot --headless --path . res://tests/Playtest.tscn               # bot plays a round of every level of every category
```

## Phone (Android)

Builds a debug-signed APK using the "Android" preset in `export_presets.cfg`. The SDK and
keystore paths come from the Godot editor settings, which it shares with perch and psyche:

```sh
godot --headless --path . --export-debug "Android" build/math-flash.apk
~/Android/Sdk/platform-tools/adb install -r build/math-flash.apk
```
