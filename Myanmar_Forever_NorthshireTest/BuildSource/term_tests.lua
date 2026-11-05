
-- First-introduction meanings: real Lua 5.1 state and renderer lifecycle tests.
-- Appended to tests.lua so these exercise the same WoW mocks and actual modules.
do
  local T=A.TermIntroductions
  assert(T and A.termGlossary and A.termAliases)
  local horde=A.termGlossary['faction.horde']
  local warrior=A.termGlossary['class.warrior']
  assert(horde and warrior and horde.intro~=horde.short and warrior.intro~=warrior.short)
  assert(horde.intro:find(' — ',1,true) and warrior.intro:find(' — ',1,true),'Meaning text is required, not only pronunciation')
  local original7=A.quests[7]
  local oldName,oldClass,oldRace,oldSex=UnitName,UnitClass,UnitRace,UnitSex
  local function emptySeen()
    assert(next(MMNorthshireTermSeen.seen)==nil,'A non-visible/non-live view consumed a meaning')
  end
  local function fresh()
    debugCommand('off');command('hide');fire('QUEST_FINISHED');flush()
    MMNorthshireTermSeen={version=1,seen={}};T.Invalidate()
    titleOverride=nil;titleUnavailable=false;titleError=false;titleSecret=false
    logTitleOverride=nil;logTitleUnavailable=false;fontFailure=false;coldLayout=false
    UnitName=function() return 'Test%Hero' end
    UnitClass=function() return 'Warrior','WARRIOR' end
    UnitRace=function() return 'Orc','Orc' end
    UnitSex=function() return 2 end
  end
  local function liveShow(id,event)
    questID=id;fire(event or 'QUEST_DETAIL');flush()
  end
  local function hasMeaning(record) return shown.text:find(record.intro,1,true)~=nil end
  local function learned(record) return MMNorthshireTermSeen.seen[record.key]==true end
  local function fixture(title,detail,objective,progress,complete)
    A.quests[7]={en=original7.en,title=title or 'Title',detail=detail or '<class>',objective=objective,progress=progress,complete=complete}
  end
  fresh();liveShow(4641,'QUEST_COMPLETE')
  assert(A.window:IsShown() and hasMeaning(horde) and hasMeaning(warrior),'Quest 4641 must actually explain Horde and Warrior')
  assert(plainCount(shown.text,horde.intro)==1 and plainCount(shown.text,warrior.intro)==1)
  assert(learned(horde) and learned(warrior),'Successful live body did not persist introductions')
  local firstBody=shown.text
  fire('QUEST_COMPLETE');flush();assert(shown.text==firstBody,'Same active stage lost its introduction')
  A.ChangeFont(2);A.ChangeFont(-2);assert(shown.text==firstBody)
  command('hide');command('toggle');assert(shown.text==firstBody,'Close/reopen changed the active snapshot')
  command('reset');assert(shown.text==firstBody and learned(horde),'Window geometry reset should preserve learned meanings')
  debugCommand('on');clickDebug('english');assert(not hasMeaning(horde))
  clickDebug('english');assert(shown.text==firstBody,'English debug switch consumed the active introduction')
  command('783');clickDebug('live');assert(shown.text==firstBody,'Preview overwrote the active LIVE snapshot')
  debugCommand('off')
  fire('QUEST_FINISHED');liveShow(4641,'QUEST_COMPLETE')
  assert(not hasMeaning(horde) and not hasMeaning(warrior),'Finished/reopened encounter repeated a learned meaning')
  assert(shown.text:find(horde.short,1,true) and shown.text:find(warrior.short,1,true),'Learned labels lost pronunciation')
  fresh();liveShow(4641,'QUEST_DETAIL');assert(hasMeaning(horde) and hasMeaning(warrior))
  fire('QUEST_COMPLETE');flush();assert(not hasMeaning(horde) and not hasMeaning(warrior),'New stage reused an old learning snapshot')
  print('PASS: Quest 4641 displays actual Horde/Warrior meanings once; stable current-stage redraw, sizing, close, reset, debug switches and preview return; learned pronunciation persists in new stages/encounters.')

  fresh();command('4641 complete');assert(hasMeaning(horde) and hasMeaning(warrior));emptySeen()
  command('4641 complete');assert(hasMeaning(horde));emptySeen()
  liveShow(4641,'QUEST_COMPLETE');assert(hasMeaning(horde) and learned(horde))
  command('4641 complete');assert(hasMeaning(horde),'A stateless review preview should show a fresh introduction')
  fresh();fixture('Title',horde.short..' <class>',nil,horde.short..' <class>',horde.short..' <class>')
  liveShow(7);assert(hasMeaning(horde));liveShow(4641,'QUEST_COMPLETE')
  assert(not hasMeaning(horde) and not hasMeaning(warrior),'A new quest repeated a learned term')
  local characterOne=MMNorthshireTermSeen
  MMNorthshireTermSeen={version=1,seen={}}
  fire('QUEST_COMPLETE');flush();assert(hasMeaning(horde) and learned(horde),'Saved table replacement shared another character snapshot')
  assert(characterOne~=MMNorthshireTermSeen and characterOne.seen['faction.horde']==true)
  MMNorthshireTermSeen.seen={};fire('QUEST_COMPLETE');flush();assert(hasMeaning(horde),'Explicit seen-table reset kept a stale cache')
  T.Invalidate();fire('QUEST_COMPLETE');flush();assert(not hasMeaning(horde),'Reload-style empty session cache forgot persisted learning')
  MMNorthshireTermSeen={version=77,seen={['faction.horde']=true}};T.Invalidate()
  fire('QUEST_COMPLETE');flush();assert(MMNorthshireTermSeen.version==1 and hasMeaning(horde),'Invalid saved schema was not safely reset')
  MMNorthshireTermSeen='corrupt';T.Invalidate();fire('QUEST_COMPLETE');flush();assert(type(MMNorthshireTermSeen)=='table' and hasMeaning(horde))
  assert(not MMNorthshireTermSeen.player and not MMNorthshireTermSeen.realm,'Character identity must come from SavedVariablesPerCharacter, not a global user map')
  print('PASS: stateless previews; new quest/stage learning; per-character saved-table isolation, seen reset, reload-style cache reset, invalid-schema recovery; no player identity strings stored.')

  fresh();A.quests[7]=original7
  for _,mode in ipairs({'mismatch','missing','error','secret'}) do
    titleOverride=mode=='mismatch' and 'Different quest' or nil
    titleUnavailable=mode=='missing';titleError=mode=='error';titleSecret=mode=='secret'
    liveShow(4641,'QUEST_COMPLETE');assert(not A.window:IsShown());emptySeen()
  end
  titleOverride=nil;titleUnavailable=false;titleError=false;titleSecret=false
  liveShow(98021,'QUEST_COMPLETE');assert(not A.window:IsShown());emptySeen()
  questID=0;fire('QUEST_DETAIL');flush();emptySeen()
  questID=4641;fire('QUEST_COMPLETE');fire('QUEST_FINISHED');flush();emptySeen()
  questID=4641;fire('QUEST_COMPLETE');command('hide');flush();emptySeen()
  debugCommand('on');clickDebug('auto');liveShow(4641,'QUEST_COMPLETE');assert(not A.window:IsShown());emptySeen()
  command('4641 complete');clickDebug('english');clickDebug('auto')
  liveShow(4641,'QUEST_COMPLETE');assert(shown.text:find('Live completion.',1,true));emptySeen()
  clickDebug('english');assert(hasMeaning(horde) and learned(horde));debugCommand('off')
  fresh();fontFailure=true;liveShow(4641,'QUEST_COMPLETE');assert(A.window:IsShown() and not body:IsShown());emptySeen()
  fontFailure=false;A.ChangeFont(2);assert(body:IsShown() and learned(horde),'Recovery did not learn after successful rendering')
  fresh();fontFailure=true;liveShow(4641,'QUEST_COMPLETE');command('hide');fontFailure=false;flush();emptySeen()
  fresh();fontFailure=true;liveShow(4641,'QUEST_COMPLETE');titleOverride='Changed while awaiting font';fontFailure=false;A.ChangeFont(2);emptySeen()
  fresh();coldLayout=true;liveShow(4641,'QUEST_COMPLETE');emptySeen()
  command('hide');coldLayout=false;flush();emptySeen()
  -- The current request supersedes the old deferred layout callback.
  fresh();coldLayout=true;liveShow(4641,'QUEST_COMPLETE');emptySeen()
  command('783');coldLayout=false;flush();emptySeen()
  fresh();UIParent:Hide();liveShow(4641,'QUEST_COMPLETE');emptySeen()
  UIParent:Show();A.ChangeFont(2);assert(learned(horde),'Visible-parent recovery did not learn')
  fresh();MMNorthshireTestScroll:Hide();liveShow(4641,'QUEST_COMPLETE');emptySeen()
  MMNorthshireTestScroll:Show();A.ChangeFont(2);assert(learned(horde),'Visible-scroll recovery did not learn')
  fresh();local oldVisible=body.IsVisible;body.IsVisible=function() error('Visibility unavailable') end
  liveShow(4641,'QUEST_COMPLETE');emptySeen();body.IsVisible=oldVisible
  command('hide');flush();emptySeen()
  fresh();body.IsVisible=false;liveShow(4641,'QUEST_COMPLETE');emptySeen()
  body.IsVisible=oldVisible;command('hide');flush();emptySeen()
  -- A font API can fail with false, throw, or fail to report its actual font.
  local savedSetFont,savedGetFont,savedSetText=body.SetFont,body.GetFont,body.SetText
  for _,mode in ipairs({'false-font','throw-font','throw-get','false-text','throw-text'}) do
    fresh()
    if mode=='false-font' then body.SetFont=function() return false end
    elseif mode=='throw-font' then body.SetFont=function() error('font failure') end
    elseif mode=='throw-get' then body.GetFont=function() error('get-font failure') end
    elseif mode=='false-text' then body.SetText=function() return false end
    else body.SetText=function() error('text failure') end end
    liveShow(4641,'QUEST_COMPLETE');assert(not body:IsShown());emptySeen()
    command('hide');body.SetFont=savedSetFont;body.GetFont=savedGetFont;body.SetText=savedSetText;flush();emptySeen()
  end
  print('PASS: title mismatch/missing/error/secret, held states, invalid IDs, superseded events, dismissed callbacks, auto-off, English debug, hidden/cold layout and failed/throwing font/text APIs never consume introductions.')

  -- The source-order scanner deduplicates across all fields, while pronunciation
  -- resets for each field and inserted player names are strictly literal.
  fresh();fixture('<class> <race>',horde.short..' <class> <race> <class> '..horde.short,'<race> <class> '..horde.short)
  liveShow(7)
  local orc=A.termGlossary['race.orc']
  assert(plainCount(shown.text,warrior.intro)==1 and plainCount(shown.text,orc.intro)==1 and plainCount(shown.text,horde.intro)==1)
  assert(plainCount(shown.text,warrior.short)==2 and plainCount(shown.text,orc.short)==2 and plainCount(shown.text,horde.short)==1)
  for token,record in pairs(A.identityLabels.class) do
    fresh();fixture('Title','<Class> <class>')
    UnitClass=function() return 'Localized',token end
    liveShow(7)
    assert(record.termKey and record.intro and hasMeaning(record),'Class meaning missing for '..token)
    assert(MMNorthshireTermSeen.seen[record.termKey] and plainCount(shown.text,record.intro)==1)
    fire('QUEST_FINISHED');liveShow(7);assert(not hasMeaning(record) and shown.text:find(record.full,1,true))
  end
  for token,record in pairs(A.identityLabels.race) do
    fresh();fixture('Title','<Race> <race>')
    UnitRace=function() return 'Localized',token end
    liveShow(7)
    assert(record.termKey and record.intro and hasMeaning(record),'Race meaning missing for '..token)
    assert(MMNorthshireTermSeen.seen[record.termKey] and plainCount(shown.text,record.intro)==1)
  end
  fresh();fixture('Title','<name> <name>')
  local dangerous=horde.short..' <class> %1 |cdeadbeefName|r'
  UnitName=function() return dangerous end
  liveShow(7);assert(plainCount(shown.text,dangerous:gsub('|','||'))==2,'Name was parsed as annotation, marker or replacement pattern');emptySeen()
  fresh();fixture('Title','<class> '..horde.short..' <class>')
  UnitClass=function() return 'Odd%Class|cdeadbeef','UNKNOWN' end
  liveShow(7);assert(plainCount(shown.text,'Odd%Class||cdeadbeef')==2 and learned(horde))
  fresh();fixture('Title','<class>')
  liveShow(7);assert(hasMeaning(warrior))
  UnitClass=function() return 'Hunter','HUNTER' end
  fire('QUEST_DETAIL');flush();assert(hasMeaning(A.identityLabels.class.HUNTER),'Identity change reused a stale class snapshot')
  print('PASS: meanings follow title/body/objective source order, pronunciation remains once per field; all 17 class/race meanings verified; locale-independent tokens, same-stage identity changes and percent/color/marker-like usernames stay safe.')

  fresh();fixture('Title',warrior.short..' <class> '..warrior.intro..' '..warrior.short)
  liveShow(7);assert(plainCount(shown.text,warrior.intro)==1 and plainCount(shown.text,warrior.short)==0,'Static and dynamic class aliases did not share a canonical term')
  fresh();fixture('Title','<class> '..warrior.short)
  liveShow(7);assert(plainCount(shown.text,warrior.intro)==1 and plainCount(shown.text,warrior.short)==0)
  local originalAliases=A.termAliases
  local reversed={};for i=#originalAliases,1,-1 do reversed[#reversed+1]=originalAliases[i] end
  A.termAliases=reversed
  fresh();fixture('Title',horde.intro..' '..warrior.intro)
  liveShow(7);assert(plainCount(shown.text,horde.intro)==1 and plainCount(shown.text,warrior.intro)==1,'Alias order changed exact old-meaning replacement')
  fire('QUEST_FINISHED');liveShow(7)
  assert(not hasMeaning(horde) and not hasMeaning(warrior),'Old source meaning leaked after learning')
  assert(shown.text:find(horde.short,1,true) and shown.text:find(warrior.short,1,true))
  A.termAliases=originalAliases
  fresh();fixture('Title','Elder '..warrior.short..' | '..'Super'..horde.short..' | '..horde.short..'ling')
  liveShow(7);emptySeen();assert(not hasMeaning(horde) and not hasMeaning(warrior),'A suffix inside an ordinary NPC name became a term')
  fresh();fixture('Title','|cffff0000'..horde.short..'|r')
  liveShow(7);assert(hasMeaning(horde) and learned(horde),'Color syntax broke exact-label boundaries')
  for sex,label in pairs({[2]=A.labels.priest,[3]=A.labels.priestess}) do
    fresh();fixture('Title','<priest/priestess> <class>')
    UnitSex=function() return sex end
    UnitClass=function() return 'Priest','PRIEST' end
    local alias
    for _,candidate in ipairs(A.termAliases) do if candidate.text==label then alias=candidate;break end end
    assert(alias and alias.key=='class.priest','Priest/priestess marker alias missing')
    liveShow(7);assert(shown.text:find(alias.intro,1,true) and plainCount(shown.text,alias.intro)==1)
    assert(MMNorthshireTermSeen.seen['class.priest'])
    fire('QUEST_FINISHED');liveShow(7)
    assert(not shown.text:find(alias.intro,1,true) and shown.text:find(alias.short,1,true),'Religious-role marker repeated its meaning')
  end
  local marshalOne,marshalTwo
  for _,alias in ipairs(A.termAliases) do
    if alias.short:find('Marshal McBride (',1,true)==1 then marshalOne=alias end
    if alias.short:find('Marshal Haggard (',1,true)==1 then marshalTwo=alias end
  end
  assert(marshalOne and marshalTwo,'Compound-rank test labels missing')
  fresh();fixture('Title',marshalOne.short..' '..marshalTwo.short..' '..marshalOne.short)
  liveShow(7)
  assert(shown.text:find(marshalOne.intro,1,true) and shown.text:find(marshalTwo.short,1,true))
  assert(not shown.text:find(marshalTwo.intro,1,true),'Two names with one rank repeated the meaning')
  assert(plainCount(shown.text,marshalOne.intro)==1 and plainCount(shown.text,marshalTwo.short)==1,'Distinct rank labels lost their own pronunciation')
  -- Every exact catalog alias, including legacy meanings, must normalize in
  -- either source order and without mutating learned state during review.
  fresh()
  for _,alias in ipairs(A.termAliases) do
    local fields=T.Prepare(7,'detail',true,{{field='detail',text=alias.text}},{})
    assert(fields[1]==alias.intro,'Alias failed first-introduction normalization: '..alias.key)
    emptySeen()
  end
  -- Explicit content-review exceptions suppress only static aliases, never the
  -- player's real dynamic class token even when both occur in the same field.
  local exceptions=A.termFieldExceptions
  fresh();fixture('Title',warrior.short..' <class>')
  A.termFieldExceptions={[7]={detail={['class.warrior']=true}}}
  liveShow(7)
  assert(shown.text:find(warrior.short,1,true) and hasMeaning(warrior) and learned(warrior),'Static exception swallowed a dynamic identity')
  A.termFieldExceptions=exceptions
  -- A callback retained from an old request cannot commit after a preview,
  -- another character table, or a later stage replaced it.
  local wrapper=A.ShowText
  local callbacks={}
  A.ShowText=function(title,text,note,onVisible)
    shown={title=title,text=text,note=note};callbacks[#callbacks+1]=onVisible or false
    A.window:Show()
  end
  fresh();fixture('Title',horde.short,nil,horde.short)
  liveShow(7);local delayed=callbacks[#callbacks];emptySeen()
  command('7');delayed();emptySeen()
  liveShow(7);delayed=callbacks[#callbacks]
  MMNorthshireTermSeen={version=1,seen={}};delayed();emptySeen()
  liveShow(7);delayed=callbacks[#callbacks];fire('QUEST_PROGRESS');flush();delayed();emptySeen()
  local current=callbacks[#callbacks];current();assert(learned(horde));current();assert(learned(horde))
  A.ShowText=wrapper
  A.quests[7]=original7
  UnitName,UnitClass,UnitRace,UnitSex=oldName,oldClass,oldRace,oldSex
  debugCommand('off');command('hide');fire('QUEST_FINISHED');flush()
  titleOverride=nil;questID=0;fontFailure=false;coldLayout=false
  print('PASS: static/dynamic canonical deduplication, exact old-meaning replacement, alias reordering and overlap boundaries, sex-specific priest labels, static-only field exclusions and idempotent current-view renderer commits.')
end
