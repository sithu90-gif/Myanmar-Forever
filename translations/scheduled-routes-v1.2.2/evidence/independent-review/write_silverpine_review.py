import datetime
import hashlib
import json
import re
from pathlib import Path

base = Path(__file__).resolve().parent.parent
partition = base / 'silverpine'
english_path = partition / 'english-sources.json'
myanmar_path = partition / 'edited.json'
sources = json.loads(english_path.read_text(encoding='utf-8'))
edited = json.loads(myanmar_path.read_text(encoding='utf-8'))
maintained = json.loads((base / 'maintained-pronunciations.json').read_text(encoding='utf-8'))


def sha(text):
    return hashlib.sha256(text.encode('utf-8')).hexdigest() if text is not None else None


notes = {
    '437': ['All five states read. The old farm is north; small attacks are routed by Nightlash, not annihilated. The conditional kill-until-appearance sequence and dust as proof remain intact.', 'The objective has three sequential actions and the correct item/recipient. Progress depends on her destruction; completion retains loss of Scourge ground and growing value to the Forsaken.'],
    '438': ['Four available states read; unavailable progress remains null. Ferry east of Sepulcher, heavy patrols, and reason-for-occupation investigation are preserved.', 'Completion describes wrapped corpses inside this boat, an eastward view across the lake, the opposite dock on Fenris Isle and an inference rather than established certainty about the corpses. Lowercase <name> follows the primary English source.'],
    '439': ['All five states read. The protruding unwrapped hand belongs to a relatively fresh plague-pockmarked woman; the ring inscription is a dedication to Deliah.', 'Hadrec asks whether the investigation bore fruit and infers transport from Tirisfal mass graves to Fenris Isle. Deliah\'s Ring and the correct recipient remain recognizable.'],
    '443': ['All five states read. Pre-assault investigation, Fenris Isle east of the ferry, collection from gnolls and Renferrel stationed outside Sepulcher are preserved.', 'Objective retains 8 bottles; completion retains the dry uncertainty that the rot hides might have no weakness.'],
    '444': ['All five states read. Reduction/separation is a laboratory process, findings remain inconclusive, and warlock/necromantic creation is established.', 'Bethor is explicitly not an apothecary, his knowledge may help, Magic Quarter is retained, and the concentration warning/divination pause fit the source speaker. Sample Ichor is the handover item.'],
    '446': ['All five states read. Thule is the old colleague, promising prewar mage who betrayed his fellows and joined Scourge at the Lich King\'s rise. His survival and Rot Hide leadership surprise the speaker.', 'Scroll incantations enable a counter-potion; completion preserves powerful mixture and conditional attack on his Fenris Isle stronghold. Align Thule pronunciation with the existing maintained ranked name.'],
    '448': ['Four available states read; progress remains null. Reporting to Hadrec happens before the assault; additional information/equipment is only possible.', 'Completion is conditional on Bethor being correct, demands urgent action and permits something from the arsenal. Align Thule pronunciation with the maintained core.'],
    '477': ['Four available states read; progress remains null. Dalaran supports human opposition, the backwater\'s significance is inferred, and the plan remains unknown.', 'Shipments originate in Hillsbrad; the camp is north of Pyrewood while the objective separately puts the village south. The bracketed crate/map/pendant observation remains a stage direction. Correct many supplies, which is presently narrowed to most supplies.'],
    '478': ['All five states read. The short bracketed action removes the pendant quickly and replaces the lid.', 'The pendant goes to Shadow Priest Allister, and his curious hesitation and uncertainty remain; Dalar may know how the objects are used.'],
    '481': ['All five states read. Rune-inscribed pendant destination, exact <class> token and terse query remain intact.', 'Kirin Tor machinations are tentative; artifact channeling, inference from many pendants and intention to try piercing shields are preserved.'],
    '482': ['Four available states read; progress remains null. The forgotten dormant ley node is at a Kirin Tor earmarked site; reactivation is an inference.', 'Large power requirement, pendant removal as a delay, Allister\'s decision, confidence in Dalar and interim action all remain.'],
    '479': ['All five states read. This is the later Ambermill task after 482, with 8 Dalaran Pendants and conjurer/mage/protector targets.', 'The route goes south on the main road and then east at the fork. Completion describes advanced magical weaving despite setback and a powerful guiding wizard. Progress must retain possible loss of control, not state it as certain.'],
    '447': ['All five states read. This same-title step collects spider blood and bear hearts, distinct from the later journal and moss/tumor steps.', 'Objective retains 6 hearts and 6 blood samples; detail preserves northwest Skittering Dark, bears throughout Silverpine and Faranell in Undercity. Callous anti-human rhetoric, <class>/<name>, toxic and contaminable properties remain.'],
    '450': ['All five states read, including the worker\'s final aquatic-life correction from animals to living things. Arugal curses the promising apothecary into a mindless servant; his findings are still only potentially useful.', 'This step retrieves the journal from Berard\'s study in Pyrewood Village Inn and delivers it to Renferrel. Madness in completion, primary lowercase <name> and all aquatic life killed long ago are preserved.'],
    '451': ['All five states read. Distinct final recipe step requests 6 Lake Creeper Moss, 6 Lake Skulker Moss and one Hardened Tumor.', 'Moss may help the new-plague effort; creatures inhabit islands in the lake east; the rare tumor was found on Vile Fin murloc and Berard obtained only one. Completion preserves diligent research, the Dark Lady\'s plight, near breakthrough and conditional recruitment compliment.'],
    '6321': ['All five states read. Hadrec orders stock-taking, general stores are adequate but replacement weapons are needed after field losses.', 'Order goes to bat master Karos Razok first for transport discussion, with weapon dealer Gordon Wendham in Undercity the downstream destination. Official-business observation and urgency are preserved.'],
    '6323': ['All five states read. Bats are correctly translated as လင်းနို့; fare is small and readiness requires speaking again.', 'Objective buys the bat trip from Karos before delivering Podrig\'s Order to Gordon. Trade Quarter and same-quarter landing, clean ready weapons and honor serving the Dark Lady\'s servants remain.'],
    '6322': ['All five states read. Supplies are in Gordon\'s Crate; riding back requires previously visiting Sepulcher and speaking to its bat master.', 'Michael Garrett is the Undercity bat master; bats are correctly named throughout, daily flights and long-distance usefulness remain.'],
    '6324': ['All five states read. Always-available Undercity flights are distinguished from remote routes requiring a prior visit and bat-master conversation.', 'Karos has already been met; speaking again when ready, buying from Michael, then handing Gordon\'s Crate to Deathguard Podrig remain. Weapons prevent being unprepared.'],
    '435': ['All five states read. Hungry wolves watching Erland and the grim worth-eating joke remain; he must report to teammate Rane.', 'Escort passes through wolves to Rane, friends improve chances without becoming a new requirement, progress urges brevity and completion acknowledges fear he had fallen to Silverpine\'s dangers.'],
    '449': ['All five states read. Quinn\'s wounds are healing, but report delivery remains urgent because of information vital to maintaining control.', 'Recipient and report identity remain; Hadrec admits underestimating Scourge numbers/scouting trouble and promises commendation.'],
    '440': ['All five states read. Husband or beloved remains unresolved, Sevren may identify Deliah through death records, and the speaker remains bleak about survival/undead indifference.', 'The body theft conclusion is conditional on the report; mass grave, Brill/Silverpine, and destruction of Rot Hides/Scourge remain. Ordinary descriptive title is translated semantically.'],
    '441': ['All five states read. The Deliah identity is conditional; husband Raleigh lives in Undercity Trade Quarter.', 'Raleigh confirms the ring, feels no grief or shock about body abduction, describes cold feelings and a still-burning desire for revenge. Three-paragraph emotional progression and blunt query remain.'],
    '460': ['All five states read. Title keeps pieces/rest wordplay; Alaric was head servant and bodyguard, his ironic protection becomes inescapable unlife, and his severed head is a gnoll plaything.', 'The body\'s location is a belief: unmarked grave near stable in Fenris Keep. Objective takes head to grave; progress is the hastily dug grave; completion expresses relief the body survives. Align Thule pronunciation.'],
    '461': ['All five states read. Hidden alcove stores something valued by Thule and old colleagues, plus an item useful to the player. Correct Myanmar possessive/dative wording to retain the latter meaning.', 'Southwestern tower, behind dusty shelf, body transport, leaving boots because they never fit, comfort from best days, closing tightly to hide from Rot Hides and earned gift all remain. Align Thule pronunciation.'],
}

field_notes = {
    'title': 'Read independently as a displayed title; ordinary wording versus identifying names checked.',
    'detail': 'Read against full English offer: meaning, speaker, identities, direction, conditions and written quantities checked.',
    'objective': 'Read as a separate task state; actor, target, item, destination, order and quantities checked.',
    'progress': 'Read against the English progress state: voice, question/condition and placeholders checked.',
    'complete': 'Read against full English completion: inference, uncertainty, humor, stage instructions and narrative outcome checked.',
}

replacements = []


def propose(qid, field, old, new, code, reason, severity='required'):
    current = edited[qid][field]
    assert old in current, (qid, field, old)
    replacements.append({
        'id': int(qid), 'field': field, 'issue': code, 'severity': severity,
        'oldMyanmar': old, 'newMyanmar': new,
        'englishSHA256': sha(sources[qid]['english'][field]),
        'reviewedMyanmarSHA256': sha(current),
        'sourceRationale': reason,
    })


propose('477', 'detail', 'ထောက်ပံ့ရေးပစ္စည်းအများစုက', 'ထောက်ပံ့ရေးပစ္စည်းအတော်များများက',
        'many_not_most', 'English says many of those supplies, which does not establish a majority. အများစု asserts most; အတော်များများ retains the non-majority quantity.')
propose('479', 'progress', 'ငါတို့ထိန်းချုပ်ထားနိုင်တော့မှာ မဟုတ်ဘူး။', 'ငါတို့ လက်လွှတ်ဆုံးရှုံးရနိုင်တယ်။',
        'retain_possible_outcome', 'English says we may lose our hold on Silverpine Forest. The original Myanmar made loss certain; လက်လွှတ်ဆုံးရှုံးရနိုင်တယ် restores the possible outcome.')
propose('461', 'detail', 'မင်းအသုံးဝင်နိုင်တဲ့ ပစ္စည်းတစ်ခုလည်း', 'မင်းအတွက် အသုံးဝင်နိုင်တဲ့ ပစ္စည်းတစ်ခုလည်း',
        'useful_to_player', 'English something you might find useful means the item may be useful to the player. Without အတွက် the Myanmar wording attaches useful directly to you.')

assert 'Thule Ravenclaw' not in maintained and 'Thule' not in maintained
assert maintained['Necromancer Thule Ravenclaw'] == 'နက်ခရိုမန်ဆာ သူလ် ရေးဗန်ကလော'
for qid, fields in edited.items():
    for field, value in fields.items():
        if value and 'သူးလ်' in value:
            propose(qid, field, 'သူးလ်', 'သူလ်', 'maintained_thule_core',
                    'No standalone maintained Thule/Thule Ravenclaw exists. Existing maintained Necromancer Thule Ravenclaw fixes the core as သူလ်; whole-name compound pronunciation must preserve the maintained core. This is consistency with existing assisted terms, not native pronunciation certification.')

proposed = {qid: dict(fields) for qid, fields in edited.items()}
for change in replacements:
    qid, field = str(change['id']), change['field']
    proposed[qid][field] = proposed[qid][field].replace(change['oldMyanmar'], change['newMyanmar'])

changed_fields = []
for qid, fields in edited.items():
    for field, value in fields.items():
        if value != proposed[qid][field]:
            changed_fields.append({
                'id': int(qid), 'field': field,
                'englishSHA256': sha(sources[qid]['english'][field]),
                'oldMyanmar': value, 'newMyanmar': proposed[qid][field],
                'oldMyanmarSHA256': sha(value),
                'newMyanmarSHA256': sha(proposed[qid][field]),
                'issues': [c['issue'] for c in replacements if c['id'] == int(qid) and c['field'] == field],
            })

integrity_errors = []
quests = []
for qid, fields in edited.items():
    affected = {c['field'] for c in replacements if c['id'] == int(qid)}
    semantic_issues = [c for c in replacements if c['id'] == int(qid) and c['issue'] != 'maintained_thule_core']
    field_review = {}
    for field, value in fields.items():
        source = sources[qid]['english'][field]
        # Supported substitution markers only: prose stage directions are not tokens.
        source_tokens = re.findall(r'<(?:name|Name|class|Class|race|Race)>', source or '')
        translated_tokens = re.findall(r'<(?:name|Name|class|Class|race|Race)>', value or '')
        if source_tokens != translated_tokens:
            integrity_errors.append({'id': int(qid), 'field': field, 'issue': 'placeholder sequence', 'english': source_tokens, 'myanmar': translated_tokens})
        if (source is None) != (value is None):
            integrity_errors.append({'id': int(qid), 'field': field, 'issue': 'null/source-state mismatch'})
        field_review[field] = {
            'status': 'unavailable as sourced' if value is None else ('correction requested' if field in affected else 'reviewed'),
            'decision': 'unavailable_source_retained_null' if value is None else ('correction_required' if field in affected else 'pass_assisted_review'),
            'englishSHA256': sha(source), 'reviewedMyanmarSHA256': sha(value),
            'myanmarSHA256': sha(value),
            'proposedMyanmarSHA256': sha(proposed[qid][field]),
            'note': 'Unavailable in the supplied primary source; no text invented.' if value is None else field_notes[field],
        }
    quest_issues = []
    for change in semantic_issues:
        current = edited[qid][change['field']]
        quest_issues.append({
            'field': change['field'], 'severity': 'editorial correction requested',
            'englishEvidence': sources[qid]['english'][change['field']],
            'reason': change['sourceRationale'],
            'englishSHA256': change['englishSHA256'],
            'reviewedMyanmarSHA256': change['reviewedMyanmarSHA256'],
            'old': change['oldMyanmar'], 'new': change['newMyanmar'],
            'proposedFullField': current.replace(change['oldMyanmar'], change['newMyanmar']),
            'status': 'pending guarded integration by root',
        })
    quests.append({
        'id': int(qid), 'en': sources[qid]['en'], 'sourceURL': sources[qid]['sourceURL'],
        'sourceHTMLSHA256': sources[qid]['htmlSHA256'],
        'decision': 'pass_after_listed_corrections' if affected else 'pass_assisted_review',
        'fieldsReviewed': list(fields),
        'enabledFieldsReviewed': [f for f, v in fields.items() if v is not None],
        'fields': field_review, 'notes': ' '.join(notes[qid]), 'issues': quest_issues,
    })

report = {
    'partition': 'silverpine', 'reviewedAtUTC': datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'reviewer': 'daily_silverpine_review agent; independent from partition author',
    'reviewType': 'Independent agent-assisted direct English/Myanmar semantic review of all enabled fields, separate from the translation worker; no native proofreading or live-client testing',
    'nativeMyanmarProofreading': 'pending', 'liveClientVerification': 'not tested',
    'reviewScope': '25 quest records, 121 enabled fields; all five states per quest inspected, including four unavailable progress states retained null. Direct semantic reading performed before supplementary integrity comparison.',
    'inputArtifacts': {
        'englishSources': str(english_path.relative_to(base.parent.parent)).replace('\\', '/'),
        'englishSourcesSHA256': hashlib.sha256(english_path.read_bytes()).hexdigest(),
        'edited': str(myanmar_path.relative_to(base.parent.parent)).replace('\\', '/'),
        'editedSHA256': hashlib.sha256(myanmar_path.read_bytes()).hexdigest(),
    },
    'upstreamScope': 'The root/worker pins current official UA and English source provenance for this shared batch. This independent review consumes the supplied English snapshots; it does not claim a separate network refresh or current live availability.',
    'decision': 'conditional_pass_after_listed_corrections_and_root_revalidation',
    'questCount': len(edited),
    'enabledFieldCount': sum(v is not None for q in edited.values() for v in q.values()),
    'correctionFieldCount': 3,
    'sourceFiles': {
        'english-sources.json': hashlib.sha256(english_path.read_bytes()).hexdigest(),
        'edited.json': hashlib.sha256(myanmar_path.read_bytes()).hexdigest(),
    },
    'counts': {
        'quests': len(edited), 'enabledFieldsRead': sum(v is not None for q in edited.values() for v in q.values()),
        'unavailableFields': sum(v is None for q in edited.values() for v in q.values()),
        'semanticCorrections': 3, 'pronunciationConsistencyOccurrences': 6,
        'changedFields': len(changed_fields), 'integrityErrors': len(integrity_errors),
    },
    'pronunciationMapUpdates': [
        {'term': 'Thule', 'old': 'သူးလ်', 'new': 'သူလ်'},
        {'term': 'Thule Ravenclaw', 'old': 'သူးလ် ရေးဗန်ကလော', 'new': 'သူလ် ရေးဗန်ကလော'},
    ],
    'pronunciationUpdates': {
        'maintainedEvidence': {'term': 'Necromancer Thule Ravenclaw', 'pronunciation': maintained['Necromancer Thule Ravenclaw']},
        'canonicalCore': 'သူလ်',
        'mapUpdates': [
            {'term': 'Thule', 'old': 'သူးလ်', 'new': 'သူလ်'},
            {'term': 'Thule Ravenclaw', 'old': 'သူးလ် ရေးဗန်ကလော', 'new': 'သူလ် ရေးဗန်ကလော'},
        ],
        'affectedFields': [c for c in replacements if c['issue'] == 'maintained_thule_core'],
    },
    'pronunciationUpdateTargets': ['silverpine/pronunciations.json', 'silverpine/proposed-pronunciations.json', 'combined release term map when root integrates'],
    'replacementInstructions': 'The reviewer changed no worker/shared source files. Root should apply each exact changedFields replacement only when oldMyanmarSHA256 still matches, update pronunciation maps, regenerate semantic/provenance hashes, and run package validation. The shorter replacements explain individual issues; changedFields contains the combined final replacement for fields with multiple issues.',
    'issues': replacements, 'changedFields': changed_fields, 'quests': quests,
    'supplementaryIntegrityErrors': integrity_errors,
    'sourceLimitations': [
        '438.detail and 450.detail primary <name> differ from secondary <Name>; supplied primary lowercase case preserved exactly, with no claimed live confirmation.',
        '451 and 6323 secondary-source fetch timeouts remain documented by the worker; complete primary English snapshots and installed metadata support the reviewed text.',
        'New pronunciations and the lexical/register choices, including the concealed alcove and grim Undead humor, still require native Myanmar review. Live UI behavior, current quest availability and hardware/controller behavior were not tested.',
    ],
}
out = Path(__file__).with_name('silverpine.json')
out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'path': str(out), 'counts': report['counts'], 'integrityErrors': integrity_errors}, ensure_ascii=False))
