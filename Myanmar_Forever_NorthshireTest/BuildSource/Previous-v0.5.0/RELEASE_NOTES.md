# MyanmarForever v0.5.0-beta

Orc/Troll အစပိုင်း Quest တွေနဲ့ The Barrens က Quest တွေ စုစုပေါင်း 136 ခု
ထပ်ထည့်ထားပါတယ်။ အရင် Quest 474 ခုအပါအဝင် စုစုပေါင်း Quest ID 610 ခုနဲ့
လက်ခံချိန်၊ လုပ်ဆောင်ဆဲအချိန်၊ ပြီးဆုံးချိန်အတွက် စာသားအခြေအနေ 1,676 ခု ပါဝင်ပါတယ်။
ဘာသာပြန်အသစ်တွေကို မြန်မာစာ ပြန်လည်စစ်ဆေးမှုနဲ့ ဂိမ်းထဲ စမ်းသပ်မှု လိုအပ်ပါသေးတယ်။
Font ပြောင်းထားလို့ တင်ပြီးရင် ဂိမ်းကို လုံးဝပိတ်ပြီး ပြန်ဖွင့်ပါ။

## Added

| New coverage | Quest records |
| --- | ---: |
| Valley of Trials | 13 |
| Durotar | 33 |
| The Barrens | 79 |
| Orc/Troll class introductions | 11 |
| **Total added** | **136** |

The new set adds 629 translated fields, including 364 dialogue states.
It covers the selected regional quests through reference level 20 and the
starter class introductions. It does not include every profession, class chain
or higher-level quest. Collector gifts and legacy mount replacements are excluded.

The class introductions cover Orc Warrior, Hunter, Rogue, Shaman and Warlock;
and Troll Warrior, Hunter, Rogue, Shaman, Priest and Mage.

## Preserved

All 474 prior quest records are unchanged. Renderer.lua, QuestBridge.lua,
Controls.lua and Bindings.xml are byte-for-byte identical to v0.4.0-beta.
The draggable/resizable reader, first-open reflow, English names, identity
expansion, six optional bindings, debug controls, automatic local captures,
saved settings and original installation folder remain available.

## Source and review status

Each new quest has an English reference link in `Orc-Troll-Review.html`.
The public reference includes Classic Era records and Forever listing entries;
it is not a live Forever client capture. Content may differ in game.
All new translations are AI-assisted drafts awaiting native Myanmar review.

Two new fields are deliberately held and use the native quest text:

- Quest 842, Crossroads Conscription, completion: the reference combines male
  and female character replies. Each live branch needs confirmation.
- Quest 3083, Encrypted Tablet, progress: the reference contains a fixed player
  name. The live substitution needs confirmation.

Previous holds, including quest 3118 progress and quest 95213 completion,
remain in place. Absent reference fields are not invented. Quest 926 has only
completion text; repeatable turn-ins 889 and 5042–5046 have no offer draft.
Source quirks in 4641, 3065 and 890 are documented for live review.

## Validation

Automated checks passed for all 610 quests across 1,830 dialogue combinations:
1,676 translated states and 154 absent or held states. All 2,884 runtime fields
passed Unicode round-trip and font-glyph coverage checks. Myanmar runs passed
full-run shaping comparison. New fields passed source quantity-digit and
identity-token checks. Prior records, runtime files, reader bindings, fallback
states and deferred close behavior passed the regression checks.

These are offline checks. Native-language review, actual Forever client testing
and controller-hardware testing remain pending. See `TESTING.txt` for the route.
