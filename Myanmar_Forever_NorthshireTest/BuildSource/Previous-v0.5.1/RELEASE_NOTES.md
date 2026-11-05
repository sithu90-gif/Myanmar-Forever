# MyanmarForever v0.5.1-beta

အရင်ဘာသာပြန်ထားတဲ့ Quest တွေအပါအဝင် စုစုပေါင်း Quest 610 ခုကို English
ရည်ညွှန်းစာသားတွေနဲ့ UA_Forever 0.18.5-beta နဲ့ ပြန်တိုက်စစ်ထားပါတယ်။
အရင်စာသား 8 နေရာမှာ နေရာအမည်၊ ပစ္စည်းအမည်၊ ရာထူးနဲ့ Class အသုံးအနှုန်းတွေကို
ပိုတိကျအောင် ပြင်ထားပါတယ်။ Quest အသစ် ထပ်မထည့်ထားပါဘူး။

ဂိမ်းထဲက Quest အမည်နဲ့ သိမ်းထားတဲ့အမည် မကိုက်ရင် မြန်မာစာအမှား မပြမိအောင်
English စာသားကိုပဲ ဆက်သုံးနိုင်စေမယ့် စစ်ဆေးမှု ထည့်ထားပါတယ်။
Native မြန်မာစာစစ်ဆေးမှုနဲ့ ဂိမ်းထဲ လက်တွေ့စမ်းသပ်မှု လိုအပ်ပါသေးတယ်။

## Catalog audit

- Checked all 610 records: 474 earlier quests and 136 Orc/Troll/Barrens additions.
- Matched every ID to UA_Forever release tag 0.18.5. Titles have 604 exact matches,
  three capitalization differences, and three documented Sanders/Sander aliases.
- Checked all 2,884 enabled fields against English reference evidence for numeric
  digits and player name/class/race tokens, field presence and encoding.
- Screened cardinal directions and objective names, then reviewed the flagged
  passages. This is a source audit with targeted meaning review, not a complete
  native-language proofread of every sentence.
- Recovered public English evidence for 11 existing book-chain dialogue fields
  absent from UA and the main reference listing. No fields were newly invented.

## Changes

- Restored Darkshire in quest 58's objective and Northshire Abbey in quest 91752.
- Retained clearer English item/title labels in objectives 71, 130, 160, 178, 230.
- Used literal Warrior in quest 3100 completion, following the English reference.
  UA uses a class marker; this is a precision change, not a demonstrated live bug.
- Added English title validation for live NPC dialogue and quest-log reads.
  Unknown, mismatched, missing, secret or unreadable titles keep native English.
- Captures now record the expected title, match result and fallback reason.
- Explicit catalog previews still work. Toggle revalidates live/log titles.
- Added only three documented title aliases (138, 139, 140); no fuzzy matching.

Eight fields in eight older quests changed. The other 602 quest records and
Renderer.lua, Controls.lua and Bindings.xml are unchanged. Saved variables and
the original installation folder remain compatible. All 610 quests and 1,676
available dialogue states are retained.

## Reference differences and holds

UA is a comparison reference, not automatic authority over English source text.
Quest 258 remains at 5 boars: English references support 5, while UA says 6.
Check the live objective counter. Other reference variations in 56 progress,
1002 progress and 96626's title are documented; English-backed wording is retained.

The five existing holds remain: 98021 completion, 95213 completion, 3118 progress,
842 completion and 3083 progress. They concern racial/gender branches or fixed
player names. Neither this audit nor a working preview counts as live verification.

Automated source, font and Lua 5.1 runtime checks passed. Native Myanmar review,
in-game validation and controller-hardware testing remain pending.
See `Translation-Audit.html`, `BuildSource/test-results.json` and `TESTING.txt`.
Fully restart the client after installing the matching font/catalog pair.
