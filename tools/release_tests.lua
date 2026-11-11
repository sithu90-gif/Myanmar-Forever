-- Appended to the existing Lua mocks. Test the real bridge and term lifecycle.
do
  local savedQuest=A.quests[7]
  local originalRace=UnitRace
  local sky=A.identityLabels.race.Skyborne
  assert(sky and sky.en=='Skyborne' and sky.termKey=='race.skyborne')
  assert(sky.intro~=sky.full and A.termGlossary['race.skyborne'])
  A.quests[7]={en=savedQuest.en,title='Title',detail='<race> <Race>',objective=nil}
  debugCommand('off');titleOverride=nil
  for _,id in ipairs({95,96}) do
    MMNorthshireTermSeen={version=1,seen={}}
    A.TermIntroductions.Invalidate()
    UnitRace=function() return 'Localized Skyborne','NEW_CLIENT_TOKEN',id end
    questID=7;fire('QUEST_DETAIL');flush()
    assert(A.window:IsShown() and plainCount(shown.text,sky.intro)==1,'Skyborne ID did not receive its own meaning')
    assert(MMNorthshireTermSeen.seen['race.skyborne'],'Visible Skyborne label not committed')
    assert(not MMNorthshireTermSeen.seen['race.undead'],'Skyborne was mistaken for Undead')
    fire('QUEST_FINISHED');fire('QUEST_DETAIL');flush()
    assert(shown.text:find(sky.full,1,true) and not shown.text:find(sky.intro,1,true),'Skyborne meaning repeated')
  end
  for _,name in ipairs({'High Order Skyborne','Windshaper Skyborne'}) do
    UnitRace=function() return name,'UNKNOWN_TOKEN' end
    command('7');assert(shown.text:find('Skyborne',1,true),'English Skyborne alias failed')
  end
  UnitRace=function() return 'Future race','FUTURE',999 end
  command('7');assert(shown.text:find('Future race',1,true) and not shown.text:find('Skyborne',1,true),'Unknown race mapped to Skyborne')
  local originalSecret=issecretvalue
  issecretvalue=function(value) return value==95 or originalSecret(value) end
  UnitRace=function() return 'Future race','FUTURE',95 end
  command('7');assert(shown.text:find('Future race',1,true),'Secret race ID was inspected')
  issecretvalue=originalSecret
  A.quests[7]=savedQuest;UnitRace=originalRace;questID=0
  print('PASS: Skyborne race IDs 95/96, English identity aliases, separate introduction history, unknown/secret identity fallback and repeated-render lifecycle.')
end

do
  -- Both documented English spellings must identify the same known quest;
  -- unrelated titles must still fail closed and create a local capture.
  debugCommand('off')
  for id,alias in pairs({[92516]='Hippogryph Harassment',[92597]='Reading the Leylines'}) do
    assert(A.quests[id] and A.quests[id].enAliases,'Documented Skyborne title alias missing')
    questID=id;titleOverride=alias;fire('QUEST_DETAIL');flush()
    assert(A.window:IsShown(),'Verified alternate Skyborne title was rejected')
    titleOverride=alias..' unrelated';fire('QUEST_DETAIL');flush()
    assert(not A.window:IsShown(),'Fuzzy Skyborne title match bypassed identity guard')
    assert(MMNorthshireCaptures[id].states.detail.translationFallback=='title_mismatch')
  end
  titleOverride=nil;questID=0;fire('QUEST_FINISHED')
  print('PASS: source-documented Skyborne title aliases and strict wrong-title capture/fallback.')
end

do
  debugCommand('off');titleOverride=nil
  for _,id in ipairs({99131,334,94863,97919,94792,94864,97920,97921,332,97915,333,94793,353}) do
    assert(A.quests[id],'Captured missing quest was not added: '..id)
    questID=id
    for event,field in pairs({QUEST_DETAIL='detail',QUEST_PROGRESS='progress',QUEST_COMPLETE='complete'}) do
      fire(event);flush()
      assert(A.window:IsShown()==(A.quests[id][field]~=nil),'Captured quest state routing failed')
      local saved=MMNorthshireCaptures[id].states[field]
      assert(saved and saved.title==A.quests[id].en,'Automatic capture lost after adding translation')
    end
  end
  questID=91723;fire('QUEST_PROGRESS');flush()
  assert(A.quests[91723].progress and A.window:IsShown(),'Live-captured Delicate Instruments progress remains missing')
  assert(MMNorthshireCaptures[91723].states.progress.translationFallback==nil,'Filled state still reports fallback')
  questID=999999;titleOverride='New future quest';fire('QUEST_DETAIL');flush()
  assert(not A.window:IsShown(),'Unknown future quest invented a translation')
  assert(MMNorthshireCaptures[999999].states.detail.translationFallback=='quest_not_in_catalog','Untranslated future quest was not captured')
  titleOverride=nil;questID=0;fire('QUEST_FINISHED')
  print('PASS: all 13 captured missing quest IDs, the Delicate Instruments progress override, automatic capture after translation, and future unknown-quest capture.')
end

if A.quests[437] then
  debugCommand('off');titleOverride=nil
  local added={437,438,439,443,444,446,448,477,478,479,481,482,447,450,451,6321,6322,6323,6324,435,449,440,441,460,461,96821,96825,96822,96873,96876,99123,97225,96874,96877,95495,95508,95621,97236,87288,490,99053,98046,98065,98403,98042,91736,91753,91738,91740,91746}
  for _,id in ipairs(added) do
    assert(A.quests[id], 'Scheduled batch ID missing: '..id)
    questID=id
    for event,field in pairs({QUEST_DETAIL='detail',QUEST_PROGRESS='progress',QUEST_COMPLETE='complete'}) do
      fire(event);flush()
      assert(A.window:IsShown()==(A.quests[id][field]~=nil), 'Scheduled batch state routing failed: '..id..'/'..field)
      assert(MMNorthshireCaptures[id].states[field].title==A.quests[id].en, 'Scheduled batch capture lost its quest identity')
    end
  end
  questID=590;fire('QUEST_PROGRESS');flush()
  assert(A.quests[590].progress and A.window:IsShown(), 'Verified Rogue\'s Deal progress still missing')
  assert(MMNorthshireCaptures[590].states.progress.translationFallback==nil, 'Filled progress retained missing-state fallback')
  questID=0;fire('QUEST_FINISHED')
  print('PASS: scheduled 50-quest batch across 150 dialogue states plus the verified Rogue\'s Deal progress reply; absent states and automatic captures preserved.')
end

if A.quests[98046] then
  assert(A.quests[98046].objective:find('Drained Vessel',1,true), 'Crown delivery step uses wrong item')
  assert(A.quests[98065].objective:find('Moonwell Remnants',1,true), 'Later Crown delivery step uses wrong item')
  assert(A.quests[447].objective:find('Grizzled Bear Hearts',1,true), 'First recipe step uses wrong ingredients')
  assert(A.quests[450].objective:find('Apothecary Berard',1,true), 'Journal recipe step lost its owner')
  assert(A.quests[451].objective:find('Lake Creeper Moss',1,true), 'Later recipe step uses wrong ingredients')
  for _,id in ipairs({91736,91738}) do
    assert(not A.quests[id].detail and not A.quests[id].objective, 'Repeatable interaction invented offer/objective')
    assert(A.quests[id].progress and A.quests[id].complete, 'Repeatable interaction lost supported replies')
  end
  questID=490;titleOverride='<UNUSED>';fire('QUEST_DETAIL');flush()
  assert(not A.window:IsShown(), 'Obsolete generic UA title bypassed current quest title guard')
  assert(MMNorthshireCaptures[490].states.detail.translationFallback=='title_mismatch', 'Wrong-title fallback lost capture')
  titleOverride=nil;questID=0;fire('QUEST_FINISHED')
  print('PASS: distinct Crown/Recipe steps, repeatable progress-only source layouts and strict rejection of obsolete UA UNUSED title.')
end
