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

if A.quests[3221] then
  debugCommand('off');titleOverride=nil
  local ids={3221,452,491,493,530,95981,98298,98299,5921,5922,5929,5930,5931,5932,6001,6002,6121,6122,6123,6124,6125,6126,6127,6128,6129,6130,26,27,28,29,30,31,272,5061,6061,6087,6088,6089,6062,6083,6082,6081,6063,6101,6102,6103,6064,6084,6085,6086}
  for _,id in ipairs(ids) do
    assert(A.quests[id], '12 November batch quest missing: '..id)
    questID=id
    for event,field in pairs({QUEST_DETAIL='detail',QUEST_PROGRESS='progress',QUEST_COMPLETE='complete'}) do
      fire(event);flush()
      assert(A.window:IsShown()==(A.quests[id][field]~=nil), '12 November state routing failed: '..id..'/'..field)
      assert(MMNorthshireCaptures[id].states[field].title==A.quests[id].en, 'Class-chain capture identity lost')
    end
  end
  for _,id in ipairs({6064,6086,6125,6130}) do
    assert(A.quests[id].detail==nil, 'Unsupported gender branch was incorrectly enabled: '..id)
    questID=id;fire('QUEST_DETAIL');flush()
    assert(not A.window:IsShown(), 'Held class dialogue did not retain English fallback')
    assert(MMNorthshireCaptures[id].states.detail.translationFallback~=nil, 'Held class dialogue lost fallback capture')
  end
  questID=6064;fire('QUEST_PROGRESS');flush()
  assert(A.quests[6064].progress==nil and not A.window:IsShown(), 'Conflicting-gender progress was incorrectly enabled')
  assert(MMNorthshireCaptures[6064].states.progress.translationFallback~=nil, 'Conflicting-gender progress lost fallback capture')
  questID=0;fire('QUEST_FINISHED')
  print('PASS: 12 November 50-quest batch across150 dialogue states, class-chain captures,4 unsupported-gender offers and1 conflicting-gender progress hold.')
end

if A.quests[6061] then
  local expected={
    [6061]={'adult plainstrider','yaw sharpmane'},[6087]={'prairie stalker','yaw sharpmane'},[6088]={'swoop','yaw sharpmane'},
    [6062]={'dire mottled boar','thotar'},[6083]={'surf crawler','thotar'},[6082]={'armored scorpid','thotar'},
    [6063]={'webwood lurker','dazalar'},[6101]={'nightsaber stalker','dazalar'},[6102]={'strigid screecher','dazalar'},
    [6064]={'large crag boar','grif wildheart'},[6084]={'snow leopard','grif wildheart'},[6085]={'ice claw bear','grif wildheart'}}
  for id,terms in pairs(expected) do
    local objective=A.quests[id].objective:lower()
    for _,term in ipairs(terms) do assert(objective:find(term,1,true),'Same-title Hunter target/trainer mixed: '..id..'/'..term) end
  end
  assert(A.quests[6001].objective:find('Cenarion Moondust',1,true), 'Alliance bear dust mixed')
  assert(A.quests[6002].objective:find('Cenarion Lunardust',1,true), 'Horde bear dust mixed')
  assert(A.quests[6123].objective:find('Lunar Funguses',1,true), 'Alliance poison ingredient mixed')
  assert(A.quests[6128].objective:find('Kodo Horns',1,true), 'Horde poison ingredient mixed')
  assert(A.quests[6124].objective:find('Sickly Deer',1,true), 'Alliance cure target mixed')
  assert(A.quests[6129].objective:find('Sickly Gazelles',1,true), 'Horde cure target mixed')
  assert(A.quests[31].objective:find('Turak Runetotem',1,true), 'Horde aquatic return mixed')
  assert(A.quests[5061].objective:find('Mathrengyl Bearwalker',1,true), 'Alliance aquatic return mixed')
  assert(A.quests[98298].objective:find('Worgen Bits',1,true), 'Forever Arugal step mixed')
  print('PASS: all12 same-title Hunter target/trainer pairs, faction-specific Druid dust/ingredients/cure targets/aquatic returns and Forever Arugal objective.')
end

if A.quests[1498] then
  debugCommand('off');titleOverride=nil
  local ids={1505,1498,1502,1503,1638,1639,1640,1665,1666,1667,1679,1678,1680,1681,1682,1684,1683,1686,1692,1693,1860,1861,1879,1880,1883,1884,1919,1920,1921,1941,1959,1960,1961,1962,1516,1517,1518,1519,1520,1521,94373,94374,94375,1522,1524,1525,1526,1527,1462,1463}
  for _,id in ipairs(ids) do
    assert(A.quests[id],'Afternoon class-route quest missing: '..id)
    questID=id
    for event,field in pairs({QUEST_DETAIL='detail',QUEST_PROGRESS='progress',QUEST_COMPLETE='complete'}) do
      fire(event);flush()
      assert(A.window:IsShown()==(A.quests[id][field]~=nil),'Afternoon class-route state routing failed: '..id..'/'..field)
      assert(MMNorthshireCaptures[id].states[field].title==A.quests[id].en,'Afternoon capture lost identity')
    end
  end
  questID=0;fire('QUEST_FINISHED')
  print('PASS: afternoon 50-class-quest batch across 150 dialogue states, automatic captures and source/runtime holds.')
end

if A.quests[1498] then
  local expected={
    [1498]={'Singed Scale','Uzzek'},[1503]={'Forged Steel Bar',"Thun'grim"},
    [1640]={'Bartleby'},[1667]={"Haggard's Badge",'Dead-tooth Jack'},[1678]={"Vejrek's Head",'Muren Stormpike'},
    [1681]={'Umbral Ore','Tormus Deepforge'},[1686]={'Elunite Ore','Medallion of Elura','Elanaria'},
    [1921]={'Charged Rift Gem','Wynne Larson'},[1961]={'Dalaran Mana Gem','Josef Gregorian'},
    [1516]={'Felstalker','Canaga Earthcaller'},[1519]={'Ritual Salve','Seer Ravenfeather'},
    [94373]={'Frostmane Bear Pendant','Teo Hammerstorm'},
    [1517]={'Spirit Rock','Earth Sapta'},[1520]={'Kodo Rock','Earth Sapta'},[94374]={'Spirit Stone','Earth Sapta'},
    [1525]={'Fire Tar','Reagent Pouch','Telf Joolam'},[1526]={'Minor Manifestation of Fire','Glowing Ember'},
    [1462]={'Seer Ravenfeather','Earth Sapta'},[1463]={'Canaga Earthcaller','Earth Sapta'}}
  for id,terms in pairs(expected) do
    local objective=A.quests[id].objective:lower()
    for _,term in ipairs(terms) do
      assert(objective:find(term:lower(),1,true),'Class branch target/item/recipient mixed: '..id..'/'..term)
    end
  end
  local hoof=A.quests[1516].objective:lower()
  assert(hoof:find('felstalker hoof',1,true) or hoof:find('felstalker hooves',1,true),'Orc Earth reagent was not the correct hoof item')
  for _,id in ipairs({1517,1520,94374}) do
    assert(not A.quests[id].objective:find('Provided item:',1,true),'Website item widget leaked into objective')
  end
  for _,id in ipairs({1941,1962}) do
    assert(A.quests[id].complete and not A.quests[id].detail and not A.quests[id].objective,'Robe reward turn-in invented offer/objective or lost completion')
  end
  assert(not A.quests[1638].complete and not A.quests[1639].complete,'Conflicting Warrior gender completion was enabled')
  assert(not A.quests[1462].detail and not A.quests[1463].detail,'Unverified legacy Sapta offer was enabled')
  print('PASS: 19 Warrior/Mage/Shaman objective contracts, distinct Earth branches, provided-item UI exclusion, reward-only robe states and reviewed source holds.')
end

if A.quests[1641] then
  debugCommand('off');titleOverride=nil
  local ids={1641,1642,1643,1644,1780,1781,1786,1787,1788,1790,1645,1646,1647,1648,1778,1779,1783,1784,1785,1789,2997,2998,2999,3000,1859,1963,1858,2205,2206,2218,2238,2239,2241,2242,2259,2260,2281,2282,1998,1999,1485,1499,1599,1506,1501,1504,1685,1688,1689,1715}
  for _,id in ipairs(ids) do
    assert(A.quests[id], '13 November class quest missing: '..id)
    questID=id
    for event,field in pairs({QUEST_DETAIL='detail',QUEST_PROGRESS='progress',QUEST_COMPLETE='complete'}) do
      fire(event);flush()
      assert(A.window:IsShown()==(A.quests[id][field]~=nil),'13 November dialogue routing failed: '..id..'/'..field)
      assert(MMNorthshireCaptures[id].states[field].title==A.quests[id].en,'13 November capture lost quest identity')
    end
  end
  local held={{1780,'detail'},{1786,'complete'},{1783,'complete'},{2998,'detail'},{2205,'detail'},{1485,'progress'},{1685,'complete'}}
  for _,x in ipairs(held) do
    assert(not A.quests[x[1]][x[2]],'Unresolved source/runtime branch incorrectly enabled')
    questID=x[1]
    fire(({detail='QUEST_DETAIL',progress='QUEST_PROGRESS',complete='QUEST_COMPLETE'})[x[2]]);flush()
    assert(not A.window:IsShown(),'Held source did not retain original-language fallback')
    assert(MMNorthshireCaptures[x[1]].states[x[2]].translationFallback~=nil,'Held source lost automatic capture')
  end
  questID=0;fire('QUEST_FINISHED')
  print('PASS: 13 November50 class quests across150 dialogue states, seven explicit source holds and automatic fallback captures.')
end

if A.quests[1641] then
  local expected={
    [1643]={'Stephanie Turner','Trade District'},[1644]={'Linen Cloth','Stephanie Turner'},
    [1647]={'John Turner','Ironforge'},[1648]={'Linen Cloth','John Turner'},
    [1786]={'Symbol of Life','Henze Faulk'},[1783]={'Symbol of Life','Narm Faulk'},
    [1787]={'Defias Script','Gazin Tenorm'},[1784]={'Dark Iron Script','Muiredon Battleforge'},
    [1963]={'Tazan','Satchel','Therzok'},[1858]={'key','Satchel','Therzok'},
    [2206]={'Defias Dockmaster','Shipping Schedule'},[2238]={'Onin MacHammar','Gnomeregan'},
    [2242]={'Sethir the Ancient','Syurna'},[2282]={'Token of Thievery','Lucius'},
    [1999]={'Dalaran Status Report','Mennet Carkad'},[1485]={'Vile Familiar Heads','Ruzan'},
    [1501]={'Tablet of Verga',"Gan'rul Bloodeye"},
    [1504]={'Glyphs of Summoning',"Gan'rul Bloodeye"},
    [1688]={"Surena's Choker",'Gakin the Darkbinder'},
    [1689]={'Bloodstone Choker','Gakin the Darkbinder'}}
  for id,terms in pairs(expected) do
    local objective=A.quests[id].objective:lower()
    for _,term in ipairs(terms) do assert(objective:find(term:lower(),1,true),'13 November distinct class target/item/recipient mixed: '..id..'/'..term) end
  end
  assert(A.quests[1789].complete and not A.quests[1789].detail and not A.quests[1789].objective,'Dwarf Tome reward-only state mixed with legacy offer')
  print('PASS:20 distinct Paladin/Rogue/Warlock target-item-recipient contracts and reward-only Dwarf turn-in; Unicode quantities validated against source before shaping.')
end

if A.quests[1641] then
  debugCommand('off');titleOverride=nil
  local filled={{90902,'progress'},{90902,'complete'},{91208,'progress'},{91208,'complete'},{91209,'complete'},{98389,'progress'},{98389,'complete'},{98601,'progress'},{98601,'complete'},{92706,'progress'},{92706,'complete'},{95494,'progress'},{95494,'complete'},{95507,'progress'},{95507,'complete'},{95774,'progress'},{95774,'complete'},{96875,'progress'},{96875,'complete'},{97223,'progress'},{97223,'complete'},{97253,'progress'},{97253,'complete'},{97279,'progress'},{97279,'complete'},{99051,'progress'},{99051,'complete'},{99052,'progress'},{99052,'complete'},{87760,'progress'},{87760,'complete'},{97894,'complete'},{97926,'progress'},{97926,'complete'},{97977,'progress'},{97977,'complete'},{98013,'complete'},{98025,'progress'},{98025,'complete'},{91724,'progress'},{94864,'progress'},{95998,'progress'},{97919,'progress'},{97924,'complete'},{94411,'progress'},{97970,'progress'},{97973,'progress'},{98021,'complete'},{98024,'complete'}}
  for _,x in ipairs(filled) do
    questID=x[1];local field=x[2]
    fire(({detail='QUEST_DETAIL',progress='QUEST_PROGRESS',complete='QUEST_COMPLETE'})[field]);flush()
    assert(A.quests[questID][field] and A.window:IsShown(),'Reviewed upstream reply remains unavailable')
    assert(MMNorthshireCaptures[questID].states[field].translationFallback==nil,'Reviewed upstream fill still reports fallback')
    assert(MMNorthshireCaptures[questID].states[field].title==A.quests[questID].en,'Upstream fill lost capture identity')
  end
  assert(A.quests[98021].complete and A.quests[98024].complete,'Source-resolved Skyborne arrival greeting missing')
  assert(not A.quests[93928].complete,'Placeholder PH source was enabled')
  assert(not A.quests[91736].detail and not A.quests[91738].detail,'Legacy offers duplicated current progress')
  assert(not A.quests[98435].detail and not A.quests[98435].objective,'Unresolved source branch was enabled')
  assert(not A.quests[99108].detail,'Unconfirmed legacy offer was enabled')
  assert(A.quests[91724].objective:find('8',1,true),'Current Defias Wizard quantity not updated')
  assert(A.quests[99128].objective:find('7',1,true) and A.quests[99128].objective:find('4',1,true),'Current Murloc quantities not updated')
  assert(A.quests[99130].objective:find('6',1,true) and A.quests[99130].objective:find('18',1,true),'Current bait ingredients not updated')
  assert(A.quests[94792].progress:find('<class>',1,true),'Current Hunter progress lost class marker')
  assert(A.quests[94793].detail:find('<class>',1,true) and A.quests[94793].complete:find('<class>',1,true),'Current Hunter training lost class markers')
  assert(A.quests[94441].complete:find('Bandarion Keep',1,true) and not A.quests[94441].complete:find("Tyr's Watch",1,true),'Current Bandarion place correction missing')
  questID=0;fire('QUEST_FINISHED')
  print('PASS:49 upstream reply routing/capture contracts, source-resolved Skyborne greetings, six remaining source holds and guarded quantity/class/place corrections.')
end

if A.quests[5621] then
  debugCommand('off');titleOverride=nil
  local ids={5621,5622,5624,5625,5626,5648,5649,98574,5627,5628,5629,5630,5631,5632,5633,5652,5654,5655,5656,5657,990,991,1023,1024,1025,1008,1134,1007,1009,1010,1020,1033,1034,1016,1017,1061,1062,1063,1064,1065,1066,1067,1086,6523,6401,6548,6629,6421,6481,6461}
  for _,id in ipairs(ids) do
    assert(A.quests[id],'13 November afternoon quest missing: '..id)
    questID=id
    for event,field in pairs({QUEST_DETAIL='detail',QUEST_PROGRESS='progress',QUEST_COMPLETE='complete'}) do
      fire(event);flush()
      assert(A.window:IsShown()==(A.quests[id][field]~=nil),'Afternoon dialogue routing failed: '..id..'/'..field)
      assert(MMNorthshireCaptures[id].states[field].title==A.quests[id].en,'Afternoon capture lost quest identity')
    end
  end
  for _,x in ipairs({{5624,'detail'},{5630,'detail'},{5633,'detail'},{5652,'detail'},{5656,'complete'}}) do
    assert(not A.quests[x[1]][x[2]],'Unresolved Priest source branch incorrectly enabled')
    questID=x[1];fire(({detail='QUEST_DETAIL',complete='QUEST_COMPLETE'})[x[2]]);flush()
    assert(not A.window:IsShown() and MMNorthshireCaptures[x[1]].states[x[2]].translationFallback~=nil,'Priest hold lost fallback/capture')
  end
  for _,id in ipairs({96390,98319,99160}) do
    questID=id;fire('QUEST_PROGRESS');flush()
    assert(A.quests[id].progress and A.window:IsShown(),'Fresh source-supported Progress reply remains unavailable')
    assert(MMNorthshireCaptures[id].states.progress.translationFallback==nil,'Restored Progress retains missing-state flag')
  end
  assert(not A.quests[99108].detail,'Unverified class-specific Sparring Match offer was enabled')
  assert(A.quests[92465].detail:find('<class>',1,true) and not A.quests[92465].detail:find('<Class>',1,true),'Current primary class marker case lost')
  assert(A.quests[96390].detail:find('Dark Iron spies',1,true),'Identifying Dark Iron target phrase lost')
  questID=0;fire('QUEST_FINISHED')
  print('PASS: afternoon50 quests across150 dialogue states, five Priest source holds, three restored Progress replies and guarded class/target corrections.')
end

if A.quests[5621] then
  local expected={
    [5621]={'Sentinel Shaya','Laurna Morninglight'},[5624]={'Guard Roberts','Priestess Josetta'},
    [5625]={'Mountaineer Dolf','Maxan Anvol'},[5648]={"Grunt Kor'ja","Tai'jin"},
    [98574]={'Hallowed Memorandum','Branstock Khalder'},[5628]={'Priestess Alathea','Darnassus'},[5654]={"Ur'kyo",'Orgrimmar'},
    [991]={'Teronis'},[1023]={'Glowing Gem',"Teronis' Journal"},[1024]={"Shael'dryn",'moonwell'},[1025]={'Den Watcher','Ursa','Totemic','Warrior'},
    [1008]={'Wrathtail Head','Shindrell Swiftfire'},[1134]={'Pridewing Venom Sac','Shindrell Swiftfire'},
    [1007]={'Ancient Statuette','Talen'},[1009]={'Ring of Zoram','Talen'},
    [1016]={'Intact Elemental Bracer','Divining Scroll','Divined Scroll','Sentinel Velene Starstrike'},
    [1017]={'Sarilus Foulborne','Sentinel Velene Starstrike'},
    [1065]={"Zamah's Note",'Apothecary Lydon'},[1066]={'Vials of Innocent Blood','Apothecary Lydon'},
    [1067]={"Lydon's Toxin",'Apothecary Zamah'},[1086]={'Toxic Fogger','Apothecary Zamah'},
    [6523]={'Kaya Flathoof','Camp Aparaje','Makaba Flathoof'},[6401]={'Tammra Windfield','Sun Rock Retreat'},
    [6548]={'Grimtotem Ruffian','Grimtotem Mercenar'},[6629]={'Grundig Darkcloud','Grimtotem Brute'},
    [6421]={'Resonite Crystal',"Mor'rogal"},[6481]={'Enchanted Resonite Crystal','Goggeroc',"Mor'rogal"},
    [6461]={'Deepmoss Creeper','Deepmoss Venomspitter'}}
  for id,terms in pairs(expected) do
    local objective=A.quests[id].objective:lower()
    for _,term in ipairs(terms) do assert(objective:find(term:lower(),1,true),'Afternoon target/item/recipient step mixed: '..id..'/'..term) end
  end
  for _,id in ipairs({5621,5624,5625,5648}) do
    assert(A.quests[id].objective:find('Lesser Heal',1,true) and A.quests[id].objective:find('Power Word',1,true) and A.quests[id].objective:find('Fortitude',1,true),'Priest heal-then-buff spell identities lost')
  end
  for _,id in ipairs({5627,5652}) do
    assert(A.quests[id].complete and not A.quests[id].detail and not A.quests[id].objective,'Completion-only Priest lesson invented an offer/objective')
  end
  assert(A.quests[5632].complete,'Source-supported Returning Home completion fallback missing')
  assert(A.quests[1025].progress,'Source-supported Aggressive Defense Progress fallback missing')
  print('PASS:28 Priest/Ashenvale/Stonetalon objective identity contracts, distinct injured targets, heal/buff spell identities, completion-only lessons and reviewed secondary-state fallbacks.')
end

if A.quests[94449] then
  debugCommand('off');titleOverride=nil
  for _,id in ipairs({5634,5635,5636,5637,5638,5639,5640,94773,94774,94775,94776,94777,94778,94779,94817,94821,94822,94823,94824,94825,94826,5658,5660,5661,5662,5663,5644,5646,5679,5642,5643,5680,5672,5673,5674,5675,5641,5645,5647,5676,5677,5678,94818,94819,94820,94449,94465,94466,94467,94468}) do
    assert(A.quests[id],'14 November morning quest missing: '..id)
    questID=id
    for event,field in pairs({QUEST_DETAIL='detail',QUEST_PROGRESS='progress',QUEST_COMPLETE='complete'}) do
      fire(event);flush()
      assert(A.window:IsShown()==(A.quests[id][field]~=nil),'Morning dialogue routing failed: '..id..'/'..field)
      assert(MMNorthshireCaptures[id].states[field].title==A.quests[id].en,'Morning capture lost quest ID/title')
    end
  end
  for _,h in ipairs({{5634,"detail"},{5635,"detail"},{5636,"detail"},{5637,"detail"},{5638,"detail"},{94822,"complete"},{5674,"detail"},{5675,"detail"},{5679,"complete"},{94466,"complete"}}) do
    assert(not A.quests[h[1]][h[2]],'Unresolved source branch was enabled')
    questID=h[1];fire(({detail='QUEST_DETAIL',progress='QUEST_PROGRESS',complete='QUEST_COMPLETE'})[h[2]]);flush()
    assert(not A.window:IsShown() and MMNorthshireCaptures[h[1]].states[h[2]].translationFallback~=nil,'Source hold lost original-language fallback/capture')
  end
  for _,id in ipairs({5641,5645,5647}) do
    assert(A.quests[id].en=='Chastise' and A.quests[id].enAliases,'Exact Dwarf title alias missing')
    questID=id;titleOverride='A Lack of Fear';fire('QUEST_COMPLETE');flush()
    assert(A.window:IsShown(),'Documented installed Dwarf title was rejected')
    titleOverride='A Lack of Fear unrelated';fire('QUEST_COMPLETE');flush()
    assert(not A.window:IsShown() and MMNorthshireCaptures[id].states.complete.translationFallback=='title_mismatch','Fuzzy Dwarf title bypassed source identity guard')
  end
  for _,id in ipairs({5644,5646,5679}) do
    assert(A.quests[id].en=='Dark Sacrifice' and not A.quests[id].enAliases,'Obsolete Devouring Plague label became a runtime alias')
  end
  for _,id in ipairs({5644,5646}) do
    questID=id;titleOverride='Devouring Plague';fire('QUEST_DETAIL');flush()
    assert(not A.window:IsShown() and MMNorthshireCaptures[id].states.detail.translationFallback=='title_mismatch','Obsolete spell title bypassed current identity guard')
  end
  titleOverride=nil;questID=0;fire('QUEST_FINISHED')
  print('PASS: morning50 across150 dialogue states, source-hold fallback/capture and three exact Dwarf title aliases with wrong-title rejection.')
end

if A.quests[94449] then
  local expected={
    [94449]={'Bruegs Kindleborn','Dun Morogh'},
    [94465]={'Torch of the Dormant Flame','Braldir Ashmantle','Loch Modan'},
    [94466]={'Fire Tar','Reagent Pouch','Braldir Ashmantle','Loch Modan'},
    [94467]={'Minor Manifestation of Fire','Glowing Ember','Shrine of Eternal Flame'},
    [94468]={'Torch of Eternal Flame','Bruegs Kindleborn','Dun Morogh'},
    [5658]={},[5660]={'Aelthalyste','Undercity'},[5661]={'Aelthalyste','Undercity'},
    [5662]={'Aelthalyste','Undercity'},[5663]={'Aelthalyste','Undercity'},
    [5644]={'Aelthalyste','Undercity'},[5646]={'Aelthalyste','Undercity'},
    [5645]={'High Priest Rohan','Ironforge'},[5647]={'High Priest Rohan','Ironforge'}}
  for id,terms in pairs(expected) do
    if #terms>0 then
      assert(A.quests[id].objective,'Supported class route objective missing: '..id)
      for _,term in ipairs(terms) do assert(A.quests[id].objective:lower():find(term:lower(),1,true),'Recipient, reagent or Fire step mixed: '..id..'/'..term) end
    end
  end
  for _,id in ipairs({5658,5679,5680,5672,5676,5641}) do
    assert(not A.quests[id].detail and not A.quests[id].objective,'Completion-only Priest record invented a referral: '..id)
  end
  if EXPECTED_DISABLED_FIELDS and EXPECTED_DISABLED_FIELDS['5639.detail'] then
    assert(not A.quests[5639].detail,'Reviewed unsupported Laurena referral was enabled')
  else
    assert(A.quests[5639].detail,'Source-supported Laurena referral fallback missing')
  end
  assert(not A.quests[5679].complete,'Conflicting learned-spell identity enabled')
  assert(not A.quests[94466].complete,'Unresolved Fire gender variant enabled')
  assert(not A.quests[94822].complete,'Suspicious literal-player-name completion enabled')
  for _,id in ipairs({5634,5635,5636,5637,5638,5640}) do assert(not A.quests[id].objective,'Conflicting Rohan/Laurena route enabled') end
  questID=0;fire('QUEST_FINISHED')
  print('PASS: distinct five-step Fire recipient/reagent/elemental/return contracts, Priest referral identities, completion-only boundaries and unresolved trainer/spell/name branches.')
end

if EXPECTED_DISABLED_FIELDS and EXPECTED_DISABLED_FIELDS['5639.detail'] then
  debugCommand('off');titleOverride=nil;questID=5639
  assert(A.quests[5639].title and A.quests[5639].complete,'Source hold removed valid title or completion')
  assert(not A.quests[5639].detail and not A.quests[5639].objective and not A.quests[5639].progress,'Completion-only source invented a referral/objective/progress')
  fire('QUEST_DETAIL');flush()
  assert(not A.window:IsShown(),'Unsupported legacy offer still displays Myanmar')
  assert(MMNorthshireCaptures[5639].states.detail.title==A.quests[5639].en and MMNorthshireCaptures[5639].states.detail.translationFallback~=nil,'Held offer lost English identity/fallback capture')
  fire('QUEST_COMPLETE');flush()
  assert(A.window:IsShown() and MMNorthshireCaptures[5639].states.complete.translationFallback==nil,'Valid completion became unavailable after offer hold')
  questID=0;fire('QUEST_FINISHED')
  print('PASS: hash-guarded5639 legacy-offer hold retains valid title/completion and original-language fallback/capture.')
end

if A.quests[94913] then
  debugCommand('off');titleOverride=nil
  for _,id in ipairs({5923,5924,5925,5926,5927,5928,94911,94912,94913,94914,98340,98393,98405,98394,98342,98396,98739,98731,98362,98397,98581,96243,1523,2983,2984,94473,1528,1529,2985,2986,1530,1535,1536,1534,220,63,100,96,972,1103,94494,94495,94497,94499,94500,94501,94502,94503,94505,94616}) do
    assert(A.quests[id] and A.quests[id].title,'15 November morning quest/title missing: '..id)
    questID=id
    for event,field in pairs({QUEST_DETAIL='detail',QUEST_PROGRESS='progress',QUEST_COMPLETE='complete'}) do
      fire(event);flush()
      assert(A.window:IsShown()==(A.quests[id][field]~=nil),'New Druid/Shaman dialogue routing failed: '..id..'/'..field)
      assert(MMNorthshireCaptures[id].states[field].title==A.quests[id].en,'New quest capture lost ID/title')
    end
  end
  for _,h in ipairs({{94473,"detail"},{94473,"complete"},{972,"detail"},{1103,"detail"},{94616,"detail"}}) do
    questID=h[1];fire(({detail='QUEST_DETAIL',progress='QUEST_PROGRESS',complete='QUEST_COMPLETE'})[h[2]]);flush()
    assert(not A.window:IsShown() and MMNorthshireCaptures[h[1]].states[h[2]].translationFallback~=nil,'New held source state lost original-language fallback/capture')
  end
  assert(EXPECTED_DISABLED_FIELDS['5639.detail'] and not A.quests[5639].detail,'Prior guarded legacy-offer hold was refilled')
  for _,id in ipairs({972,94616}) do
    assert(not A.quests[id].detail and not A.quests[id].objective and not A.quests[id].progress and A.quests[id].complete,'Completion-only sapta recovery invented a legacy offer')
  end
  assert(not A.quests[94473].complete and A.quests[94473].objective,'Hardcoded Ukko reply enabled or valid recovery goal lost')
  titleOverride=nil;questID=0;fire('QUEST_FINISHED')
  print('PASS:15November50 records across150 dialogue states, new source-hold fallback/capture, completion-only sapta boundaries and retained5639 guard.')
end

if A.quests[94913] then
  local expected={
    [94913]={"Teleport: Moonglade","Dendrite Starblaze","Nighthaven"},
    [94914]={"Teleport: Moonglade","Dendrite Starblaze","Nighthaven"},
    [98342]={"Relic of the Fang","Relic of the Claw","Relic of the Silent Shadow","Stormrage Barrow Den","Great Cat Spirit"},
    [98396]={"Relic of the Fang","Relic of the Claw","Relic of the Silent Shadow","Stormrage Barrow Den","Great Cat Spirit"},
    [98362]={"Thunder Bluff","Turak Runetotem"},
    [98397]={"Darnassus","Mathrengyl Bearwalker"},
    [98731]={"Dendrite"},
    [98739]={"Dendrite"},
    [98581]={"Archaic Rune","Teo Hammerstorm","Anvilmar"},
    [96243]={"Teo Hammerstorm","Dun Morogh"},
    [1523]={"Kranal Fiss","Barrens"},
    [2983]={"Kranal Fiss","Barrens"},
    [2984]={"Kranal Fiss","Barrens"},
    [1530]={"Brine"},
    [1535]={"Empty Brown Waterskin","Brine"},
    [1536]={"Empty Red Waterskin","Tarren Mill","Brine"},
    [1534]={"Empty Blue Waterskin","Ruins of Stardust","Brine"},
    [220]={"Vial of Purest Water","Islen Waterseer"},
    [63]={"Corrupt Manifestation of Water","Bracers","Remaining Drops of Purest Water","Brazier of Everfount"},
    [100]={"Minor Manifestation of Water","Silverpine Forest"},
    [96]={"Shard of Water","Islen Waterseer"},
    [1103]={"Water Sapta","Tiev Mordune","Minor Manifestation of Water"},
    [94494]={"Norric Lochthane","Loch Modan"},
    [94495]={"Hervdana Saegrund","Wetlands"},
    [94497]={"Empty Brown Waterskin","Hervdana","Wetlands"},
    [94499]={"Empty Red Waterskin","Stonewatch Falls","Nightcrawler Murlocs","Hervdana Saegrund"},
    [94500]={"Unfilled Blue Waterskin","Astranaar","Hervdana Saegrund"},
    [94501]={"Vial of Purest Water","Norric Lochthane"},
    [94502]={"Water Sapta","Stendel's Pond","Norric"},
    [94503]={"Minor Manifestation of Water","Westfall"},
    [94505]={"Shard of Water","Norric Lochthane"}}
  for id,terms in pairs(expected) do
    local objective=assert(A.quests[id].objective,'Supported route objective missing: '..id):lower()
    for _,term in ipairs(terms) do assert(objective:find(term:lower(),1,true),'Druid relic/teleport or Water color/location/recipient contract failed: '..id..'/'..term) end
  end
  assert(A.quests[1523].complete:find('Xanis',1,true) and not A.quests[1523].complete:find('Narm',1,true),'Current Fire referrer replaced by legacy branch')
  for _,id in ipairs({94913,94914}) do assert(A.quests[id].objective:find('Teleport: Moonglade',1,true),'Teleport spell identity lost') end
  assert(A.quests[94502].objective:find('Water Sapta',1,true),'Current drink-sapta objective omitted')
  questID=0;fire('QUEST_FINISHED')
  print('PASS:31 current-English Druid/Shaman recipient/item/color/location contracts, distinct relic triples, teleport spell, current Fire referrer and Alliance sapta instruction.')
end

if A.quests[6065] then
  debugCommand('off');titleOverride=nil
  for _,id in ipairs({6065,6066,6067,6068,6069,6070,6071,6072,6073,6074,6075,6076,6721,6722,98391,2519,2518,2520,730,6344,98067,399,97220,97222,97234,97237,79007,2039,2041,96393,96394,96403,5726,5727,5728,5729,5730,5722,5723,5724,5725,5761,97242,97246,97249,97275,97326,768,769,97485}) do
    assert(A.quests[id] and A.quests[id].title,'15 November afternoon quest/title missing: '..id)
    questID=id
    for event,field in pairs({QUEST_DETAIL='detail',QUEST_PROGRESS='progress',QUEST_COMPLETE='complete'}) do
      fire(event);flush()
      assert(A.window:IsShown()==(A.quests[id][field]~=nil),'New Hunter/capital state routing failed: '..id..'/'..field)
      assert(MMNorthshireCaptures[id].states[field].title==A.quests[id].en,'Afternoon capture lost exact questID/title')
    end
  end
  for _,h in ipairs({{5728,"detail"}}) do
    questID=h[1];fire(({detail='QUEST_DETAIL',progress='QUEST_PROGRESS',complete='QUEST_COMPLETE'})[h[2]]);flush()
    assert(not A.window:IsShown() and MMNorthshireCaptures[h[1]].states[h[2]].translationFallback~=nil,'Afternoon held state lost original-language fallback/capture')
  end
  assert(not A.quests[5728].detail and A.quests[5728].objective and A.quests[5728].complete,'Hidden Enemies gender branch enabled or independent valid states lost')
  assert(EXPECTED_DISABLED_FIELDS['5639.detail'] and not A.quests[5639].detail,'Prior unsupported referral hold was refilled')
  assert(not A.quests[79007].progress and A.quests[79007].detail and A.quests[79007].complete,'Burned-note clue source boundaries changed')
  titleOverride=nil;questID=0;fire('QUEST_FINISHED')
  print('PASS:15NovemberAfternoon50 records across150 dialogue states, gender-hold original fallback/capture, burned-note boundaries and preserved5639 guard.')
end

if A.quests[6065] then
  local expected={
    [6065]={"Yaw Sharpmane","Bloodhoof Village"},
    [6066]={"Yaw Sharpmane","Bloodhoof Village"},
    [6067]={"Yaw Sharpmane","Bloodhoof Village"},
    [6068]={"Thotar","Razor Hill"},
    [6069]={"Thotar","Razor Hill"},
    [6070]={"Thotar","Razor Hill"},
    [6071]={"Dazalar","Dolanaar"},
    [6072]={"Dazalar","Dolanaar"},
    [6073]={"Dazalar","Dolanaar"},
    [6721]={"Dazalar","Dolanaar"},
    [6722]={"Dazalar","Dolanaar"},
    [6074]={"Grif Wildheart","Kharanos"},
    [6075]={"Grif Wildheart","Kharanos"},
    [6076]={"Grif Wildheart","Kharanos"},
    [98391]={"Sister Aquinne","Darnassus"},
    [2519]={"Sister Aquinne","Priestess A'moora","Temple of the Moon"},
    [2518]={"Priestess A'moora","Temple of the Moon","Darnassus","Lady Sathrah","Silvery Spinnerets"},
    [2520]={"Priestess A'moora","Lady Sathrah"},
    [730]={"Auberdine"},
    [6344]={"Nessa Shadowsong"},
    [98067]={"Sentinel Owls","Cenarion Hold","Darnassus Bank","Craftsman's Terrace Inn","City Gate","Sentinel Dalia Sunblade","Temple of the Moon"},
    [399]={"Baros Alexston","Westfall","Cathedral Square","Stormwind"},
    [97220]={"Gatehouse Shipment","Trias' Cheese","Trade District"},
    [97222]={"Gatehouse Shipment","Trias"},
    [97234]={"Stormwind"},
    [97237]={"Roy Lewells","Stormwind"},
    [2039]={"Bingles Blastenheimer","Loch Modan"},
    [2041]={"Shoni the Shilent","Stormwind"},
    [96393]={"Hall of Thanes","Old Ironforge","Head of Durgen Dirgehammer"},
    [96394]={"Enraged Apparitions","Tormented Souls","Anvilmar"},
    [96403]={"Dwarven Heirlooms","Hall of Thanes"},
    [5726]={"Lieutenant's Insignia","Thrall","Orgrimmar"},
    [5727]={"Lieutenant's Insignia","Neeru Fireblade","Burning Blade","Thrall","Orgrimmar"},
    [5728]={"Bazzalan","Jergosh the Invoker","Thrall","Orgrimmar"},
    [5729]={"Neeru Fireblade","Orgrimmar"},
    [5730]={"Thrall","Orgrimmar"},
    [5722]={"Ragefire Chasm","Maur Grimtotem"},
    [5723]={"Orgrimmar","Ragefire Chasm","Ragefire Troggs","Ragefire Shaman","Rahauro","Thunder Bluff"},
    [5724]={"Grimtotem Satchel","Rahauro","Thunder Bluff"},
    [5725]={"Spells of Shadow","Incantations from the Nether","Varimathras","Undercity"},
    [5761]={"Ragefire Chasm","Taragaman the Hungerer","Neeru Fireblade","Orgrimmar"},
    [97242]={"Cattails","Speargrass","Valley of Honor","Kor'geld","Yelmak's Alchemy and Potions"},
    [97246]={"Borstan's Firepit","Thatog","Migi"},
    [97249]={"Migi's Lunch","Grommash Hold"},
    [97275]={"Yelmak's Potion","Whuut"},
    [97326]={"Smooth Boulders","Thra","Grommash Hold"},
    [768]={"Light Leather","Veren Tallstrider","Thunder Bluff"},
    [769]={"Light Leather","Coarse Thread","Veren Tallstrider","Thunder Bluff"},
    [97485]={"Bundle of Herbs","Nida","Bundle of Cedar Twigs","Nata","Sinew Thread","Mahu","Ceremonial Flint and Tinder","Naal","Hunter's Rise"}}
  for id,terms in pairs(expected) do
    local objective=assert(A.quests[id].objective,'Afternoon objective missing: '..id):lower()
    for _,term in ipairs(terms) do assert(objective:find(term:lower(),1,true),'Hunter referral/capital ritual/dungeon contract failed: '..id..'/'..term) end
  end
  for _,id in ipairs({6065,6066,6067,6068,6069,6070,6071,6072,6073,6074,6075,6076,6721,6722}) do
    assert(not A.quests[id].progress,'Hunter referral invented a progress state: '..id)
  end
  for _,id in ipairs({6071,6076}) do assert(A.quests[id].complete:find('<class>',1,true),'Current Hunter completion placeholder missing: '..id) end
  assert(A.quests[5726].detail:find('<name>',1,true),'Current lower-case Thrall name marker changed')
  assert(A.quests[5730].detail:find('<class>',1,true),'Current lower-case Thrall class marker changed')
  assert(not A.quests[79007].objective:find('Westfall',1,true) and not A.quests[79007].objective:find('Barrens',1,true),'Added unsourced destination to enigmatic note clue')
  questID=0;fire('QUEST_FINISHED')
  print('PASS:49 current-English Hunter recipient/capital delivery/ritual/dungeon identity contracts, same-title referral alternatives, current player marker cases and unspoiled burned-note clue.')
end

if A.quests[96628] then
  debugCommand('off');titleOverride=nil
  for _,id in ipairs({96628,96608,96629,96031,96044,96045,96046,96047,96050,96055,96056,96057,96058,96059,96630,96606,96634,97938,97939,97940,97941,97942,97943,97944,97946,97948,97949,97950,96659,96605,96661,97927,97928,97929,97930,97931,97932,97933,97934,97935,97936,97937,96652,96604,96655,96102,97899,97900,97901,97902}) do
    assert(A.quests[id] and A.quests[id].title,'16 November camping quest/title missing: '..id)
    questID=id
    for event,field in pairs({QUEST_DETAIL='detail',QUEST_PROGRESS='progress',QUEST_COMPLETE='complete'}) do
      fire(event);flush()
      assert(A.window:IsShown()==(A.quests[id][field]~=nil),'Camping state routing failed: '..id..'/'..field)
      assert(MMNorthshireCaptures[id].states[field].title==A.quests[id].en,'Camping capture lost exact questID/title')
    end
  end
  for _,h in ipairs({}) do
    questID=h[1];fire(({detail='QUEST_DETAIL',progress='QUEST_PROGRESS',complete='QUEST_COMPLETE'})[h[2]]);flush()
    assert(not A.window:IsShown() and MMNorthshireCaptures[h[1]].states[h[2]].translationFallback~=nil,'New camping hold lost original fallback/capture')
  end
  assert(EXPECTED_DISABLED_FIELDS['5639.detail'] and not A.quests[5639].detail,'Prior unsupported referral hold refilled')
  assert(not A.quests[5728].detail and A.quests[5728].complete,'Prior unsupported gender offer hold refilled or valid completion lost')
  titleOverride=nil;questID=0;fire('QUEST_FINISHED')
  print('PASS:16NovemberCamping50 records across150 dialogue states, perID same-title capture and preserved source/runtime holds.')
end

if A.quests[96628] then
  local expected={
    [96628]={"Supply Bundle","Eric Brighthammer","Kharanos"},
    [96608]={"Eric","Basic Campfire","Boosted Rest"},
    [96629]={"Gremlock Pilsnor","Kharanos"},
    [96031]={"Gretta Finespindle","Ironforge"},
    [96044]={"Tognus Flintfire","Kharanos"},
    [96045]={"Vosur Brakthel","Ironforge"},
    [96046]={"Yarr Hammerstone","Kharanos"},
    [96047]={"Thamner Pol","Kharanos"},
    [96050]={"Paxton Ganter","Iceflow Lake","Dun Morogh"},
    [96055]={"Reyna Stonebranch","Ironforge"},
    [96056]={"Balthus Stoneflayer","Ironforge"},
    [96057]={"Uthrar Threx","Ironforge"},
    [96058]={"Bronk Guzzlegear","Kharanos"},
    [96059]={"Thonys Pillarstone","Ironforge"},
    [96630]={"Lyreena Duskblade","Dolanaar"},
    [96606]={"Lyreena","Basic Campfire","Boosted Rest"},
    [96634]={"Zarrin","Dolanaar"},
    [97938]={"Cyndra Kindwhisper","Dolanaar"},
    [97939]={"Elisa Steelhand","Auberdine","Darkshore"},
    [97940]={"Alanna Raveneye","Oracle Glade","Teldrassil"},
    [97941]={"Jenna Lemkenilli","Auberdine","Darkshore"},
    [97942]={"Byancie","Dolanaar"},
    [97943]={"Astaia","Darnassus"},
    [97944]={"Malorne Bladeleaf","Dolanaar"},
    [97946]={"Nadyia Maneweaver","Darnassus","Dolanaar"},
    [97948]={"Kurdram Stonehammer","Auberdine"},
    [97949]={"Radnaal Maneweaver","Darnassus","Dolanaar"},
    [97950]={"Trianna","Darnassus"},
    [96659]={"Supply Bundle","Kaga Wildhoof","Bloodhoof Village"},
    [96605]={"Kaga","Basic Campfire","Boosted Rest"},
    [96661]={"Pyall Silentstride","Bloodhoof Village"},
    [97927]={"Kray","Thunder Bluff"},
    [97928]={"Thrag Stonehoof","Thunder Bluff"},
    [97929]={"Mot Dawnstrider","Thunder Bluff"},
    [97930]={"Twizwick Sprocketgrind","Venture Co. Mine","Mulgore"},
    [97931]={"Vira Younghoof","Bloodhoof Village"},
    [97932]={"Uthan Stillwater","Bloodhoof Village"},
    [97933]={"Komin Winterhoof","Thunder Bluff"},
    [97934]={"Chaw Stronghide","Bloodhoof Village"},
    [97935]={"Brek Stonehoof","Thunder Bluff"},
    [97936]={"Yonn Deepcut","Bloodhoof Village"},
    [97937]={"Vhan","Thunder Bluff"},
    [96652]={"Brakk","Razor Hill"},
    [96604]={"Brakk","Basic Campfire","Boosted Rest"},
    [96655]={"Cook Torka","Razor Hill"},
    [96102]={"Snang","Orgrimmar"},
    [97899]={"Whuut","Orgrimmar"},
    [97900]={"Dwukk","Razor Hill"},
    [97901]={"Jhag","Orgrimmar"},
    [97902]={"Mukdrak","Razor Hill"}}
  for id,terms in pairs(expected) do
    local objective=assert(A.quests[id].objective,'Camping objective missing: '..id):lower()
    for _,term in ipairs(terms) do assert(objective:find(term:lower(),1,true),'Camping recipient/item/buff/city contract failed: '..id..'/'..term) end
  end
  for _,id in ipairs({96031,96055,96056,96057,97939,97940,97941,97943,97944,97946,97948,97949,97950,97928,97929,97930,97933,97937,97899,97902}) do assert(not A.quests[id].progress,'Invented current-English-absent camping progress: '..id) end
  for _,id in ipairs({96608,96606,96605,96604}) do assert(A.quests[id].objective:find('Boosted Rest',1,true),'Camp rest buff identity lost: '..id) end
  for _,id in ipairs({96057,97950,97937,96102}) do
    assert(A.quests[id].detail:find('Faction Banner',1,true),'Current tailoring offer banner identity lost: '..id)
    assert(A.quests[id].complete:find('Rallying Banner',1,true),'Current tailoring completion banner identity lost: '..id)
  end
  questID=0;fire('QUEST_FINISHED')
  print('PASS:50 current-English camping supply/journal/recipient/buff/remote-profession contracts, source-absent progress and field-specific tailoring banner identities.')
end

if A.quests[97916] then
  debugCommand('off');titleOverride=nil
  for _,id in ipairs({97916,97917,97918,97922,97923,97925,97903,97904,97905,97906,97907,97908,97277,384,1578,1618,6661,6662,97263,2178,4161,1581,1582,1579,1580,95065,97914,343,344,345,347,346,1359,1358,97891,480,516,442,95883,95884,95885,1489,1490,914,959,962,1486,1487,1491,866}) do
    assert(A.quests[id] and A.quests[id].title,'16 November afternoon quest/title missing: '..id)
    questID=id
    for event,field in pairs({QUEST_DETAIL='detail',QUEST_PROGRESS='progress',QUEST_COMPLETE='complete'}) do
      fire(event);flush()
      assert(A.window:IsShown()==(A.quests[id][field]~=nil),'Afternoon early-route state routing failed: '..id..'/'..field)
      assert(MMNorthshireCaptures[id].states[field].title==A.quests[id].en,'Afternoon capture lost questID/title')
    end
  end
  for _,h in ipairs({}) do
    questID=h[1];fire(({detail='QUEST_DETAIL',progress='QUEST_PROGRESS',complete='QUEST_COMPLETE'})[h[2]]);flush()
    assert(not A.window:IsShown() and MMNorthshireCaptures[h[1]].states[h[2]].translationFallback~=nil,'New held state lost original fallback/capture')
  end
  assert(EXPECTED_DISABLED_FIELDS['5639.detail'] and not A.quests[5639].detail,'Historical unsupported referral hold refilled')
  assert(not A.quests[5728].detail and A.quests[5728].complete,'Historical gender offer hold refilled or valid completion lost')
  titleOverride=nil;questID=0;fire('QUEST_FINISHED')
  print('PASS:16NovemberAfternoon50 records across150 dialogue states, exactID same-title capture and preserved historical source holds.')
end

if A.quests[97916] then
  local expected={
    [97916]={"Smith Argus","Goldshire"},
    [97917]={"Betty Quin","Stormwind"},
    [97918]={"Sprite Jumpsprocket","Stormwind"},
    [97922]={"Adele Fielder","Goldshire"},
    [97923]={"Gelman Stonehand","Stormwind"},
    [97925]={"Eldrin","Eastvale Logging Camp","Elwynn Forest"},
    [97903]={"Rawrk","Razor Hill"},
    [97904]={"Lau'Tiki","Sen'jin Village"},
    [97905]={"Jandi","Orgrimmar"},
    [97906]={"Karolek","Orgrimmar"},
    [97907]={"Krunn","Razor Hill"},
    [97908]={"Thuwd","Orgrimmar"},
    [97277]={"Grund","Gozwin","Mechanic's Log","Snow Leopard Prowler"},
    [384]={"Ragnar Thunderbrew","Kharanos","Crag Boar Ribs","Rhapsody Malt"},
    [1578]={"Copper Axes","Copper Chain Belts","Thorvald","Loch Modan"},
    [1618]={"Tormus Deepforge","Runed Copper Belts","Heavy Copper Mauls","Verner Osgood","Redridge"},
    [6661]={"Deeprun Rat","Rat Catcher","Flute","Monty"},
    [6662]={"Carton of Mystery Meat","Nipsy","Stormwind","Deeprun Tram"},
    [97263]={"Eldrun"},
    [2178]={"Strider Meat","Alanndarian Nightsong","Auberdine"},
    [4161]={"Small Spider Leg","Zarrin","Dolanaar"},
    [1581]={"Elixirs of Lion's Strength","Elixirs of Minor Defense","Syral Bladeleaf","Dolanaar"},
    [1582]={"Embossed Leather Glove","Embossed Leather Boots","Embossed Leather Cloaks","Lotherias","Darnassus"},
    [1579]={"Gaffer Jacks","Wizbang Cranktoggle","Auberdine"},
    [1580]={"Electropellers","Wizbang Cranktoggle","Auberdine"},
    [95065]={"Shiny Bauble","Nightcrawlers","Gilbert Gray","Stormwind"},
    [97914]={"Thundris","Baros Alexston","Stormwind","Auberdine"},
    [343]={"Royal Library","Stormwind Keep","Milton Sheaf","Brother Kristoff"},
    [344]={"Brother Paxton","Northshire Abbey"},
    [345]={"Foreman Oslow","Lakeshire","Rethban Iron Ore"},
    [347]={"Rethban Ore","Brother Paxton","Northshire Library"},
    [346]={"Brother Kristoff","Cathedral Square","Stresses of Iron"},
    [1359]={"Wolf Heart Samples","Apothecary Zinge","Undercity"},
    [1358]={"Wolf Heart Sample","Apothecary Helbrim","Barrens"},
    [97891]={"Unstable Potion","Doctor Martin Felben","Apothecarium"},
    [480]={"Dalaran","Shadow Priest Allister","Sepulcher"},
    [516]={"Beren's Peril","Ravenclaw Drudgers","Ravenclaw Guardians","Shadow Priest Allister","Sepulcher"},
    [442]={"Thule's Head","High Executor Hadrec","Sepulcher"},
    [95883]={"Tortured Soul","Beren's Peril","Silverpine Forest"},
    [95884]={"Offering Stone","Beren's Peril","Silverpine Forest"},
    [95885]={"Tortured Soul","Offering Stone","Beren's Peril"},
    [1489]={"Hamuul Runetotem"},
    [1490]={"Nara Wildmane"},
    [914]={"Cobrahn","Anacondra","Pythas","Serpentis","Nara Wildmane","Thunder Bluff"},
    [959]={"Bigglefuzz","Ratchet","99-Year-Old Port","Mad Magglish","Wailing Caverns"},
    [962]={"Apothecary Zamah","Thunder Bluff","Serpentbloom"},
    [1486]={"Nalpak","Wailing Caverns","Deviate Hides"},
    [1487]={"Ebru","Wailing Caverns","Deviate Ravagers","Deviate Vipers","Deviate Shamblers","Deviate Dreadfangs"},
    [1491]={"Wailing Essence","Mebok Mizzyrix","Ratchet"},
    [866]={"Root Samples","Mebok Mizzyrix","Ratchet"}}
  for id,terms in pairs(expected) do
    local objective=assert(A.quests[id].objective,'Afternoon supported objective missing: '..id):lower()
    for _,term in ipairs(terms) do assert(objective:find(term:lower(),1,true),'Camping/craft/library/Silverpine/WailingCaverns objective identity failed: '..id..'/'..term) end
  end
  for _,id in ipairs({97918,97923,97925,97905,97906,97908,343,344,345,97891,95884,1489,1490}) do assert(not A.quests[id].progress,'Invented current-English-absent progress: '..id) end
  assert(not A.quests[1358].objective:find('Wolf Heart Samples',1,true),'Singular sample step replaced by plural samples')
  assert(A.quests[97925].detail:find('Faction Banner',1,true) and A.quests[97925].complete:find('Rallying Banner',1,true),'Field-specific tailoring source labels normalized')
  for _,id in ipairs({343,344,345,347,346}) do assert(A.quests[id].title,'Library chain step missing') end
  for _,id in ipairs({95883,95884,95885}) do assert(A.quests[id].objective,'Offering Stone stage missing') end
  questID=0;fire('QUEST_FINISHED')
  print('PASS:50 current-English camping trainer/crafting/library/dungeon contracts, singular/plural samples, thirteen absent progress boundaries and distinct OfferingStone stages.')
end

if A.quests[166] and A.quests[78124] and A.quests[1057] then
  debugCommand('off');titleOverride=nil
  for _,id in ipairs({166,214,373,389,391,392,393,350,2745,2746,434,394,395,396,7791,1078,78124,78127,78142,78143,78145,78146,78147,78148,78149,79091,79092,79093,79094,79095,79096,79097,78150,97286,264,235,742,6383,6542,6545,6546,6547,6442,6462,6482,6503,6544,6641,1056,1057}) do
    assert(A.quests[id] and A.quests[id].title,'19 November quest/title missing: '..id)
    questID=id
    for event,field in pairs({QUEST_DETAIL='detail',QUEST_PROGRESS='progress',QUEST_COMPLETE='complete'}) do
      fire(event);flush()
      assert(A.window:IsShown()==(A.quests[id][field]~=nil),'Morning source-state routing failed: '..id..'/'..field)
      assert(MMNorthshireCaptures[id].states[field].title==A.quests[id].en,'Morning capture lost exact ID/title')
    end
  end
  for _,h in ipairs({{2746,"detail"}}) do
    questID=h[1];fire(({detail='QUEST_DETAIL',progress='QUEST_PROGRESS',complete='QUEST_COMPLETE'})[h[2]]);flush()
    assert(not A.window:IsShown() and MMNorthshireCaptures[h[1]].states[h[2]].translationFallback~=nil,'Held gender state lost original fallback/capture')
  end
  for _,r in ipairs({{373,"progress"},{373,"complete"},{389,"detail"},{389,"complete"},{214,"detail"},{79092,"progress"},{79092,"complete"},{79093,"progress"},{79093,"complete"},{391,"detail"},{7791,"progress"},{1078,"detail"},{166,"detail"}}) do
    questID=r[1];fire(({detail='QUEST_DETAIL',progress='QUEST_PROGRESS',complete='QUEST_COMPLETE'})[r[2]]);flush()
    assert(A.window:IsShown(),'Previously saved missing state still untranslated: '..r[1]..'/'..r[2])
  end
  assert(not A.quests[5639].detail and not A.quests[5728].detail,'Historical source holds refilled')
  questID=0;fire('QUEST_FINISHED')
  print('PASS:19NovemberMorning50 records across150 dialogue states,13 saved missing states now routed, source-hold original fallback and historical guards.')
end

if A.quests[166] and A.quests[78124] and A.quests[1057] then
  local contracts={
    {166,"objective",{"Edwin VanCleef","Gryan Stoutmantle"}},
    {214,"objective",{"Scout Riell","Sentinel Hill Tower","Red Silk Bandanas"}},
    {373,"objective",{"Letter to the City Architect","Baros Alexston","Stormwind"}},
    {389,"objective",{"Warden Thelwater","Stockade"}},
    {391,"objective",{"Bazil Thredd","Warden Thelwater","Stockade"}},
    {392,"objective",{"Sealed Description of Thredd's Visitor","Baros Alexston"}},
    {393,"objective",{"Sealed Description of Thredd's Visitor","Master Mathias Shaw"}},
    {350,"objective",{"Elling Trias","Stormwind"}},
    {2745,"objective",{"Tyrion","Stormwind Castle"}},
    {2746,"objective",{"Silk Cloth","Clara's Fresh Apples","Tyrion"}},
    {434,"objective",{"Lord Gregor Lescovar","Marzon the Silent Blade","Elling Trias"}},
    {394,"objective",{"Mathias Shaw","Stormwind"}},
    {395,"objective",{"Baros Alexston","Stormwind"}},
    {396,"objective",{"Baros Alexston","Defias Brotherhood","King Varian Wrynn","Stormwind Keep"}},
    {1078,"objective",{"Crystalized Scales","Collin Mauren","Stormwind"}},
    {264,"objective",{"Clarice's Pendant","Yuriv's Tomb","Silverpine"}},
    {235,"objective",{"Senani Thunderheart","Splintertree Post","Ashenvale"}},
    {742,"objective",{"Senani Thunderheart","Splintertree Post","Ashenvale"}},
    {6383,"complete",{"Ursangous","Shadumbra","Sharptalon"}},
    {6542,"objective",{"Kadrak","Barrens"}},
    {6545,"complete",{"Kadrak"}},
    {6546,"complete",{"Kadrak"}},
    {6547,"complete",{"Kadrak"}},
    {6442,"objective",{"Wrathtail Heads","Marukai","Zoram Strand"}},
    {6462,"objective",{"Troll Charms","Mitsuwa","Zoram'gar Outpost"}},
    {6482,"objective",{"Ruul","Yama Snowhoof"}},
    {6503,"objective",{"Ashenvale Outrunners","Kuray'bin","Splintertree Outpost"}},
    {6544,"objective",{"Torek","Silverwing Outpost","Duriel Moonfire","Ertog Ragetusk","Splintertree Post"}},
    {6641,"objective",{"Muglash","Naga","Zoram'gar Outpost","Warsong Runner","Vorsha the Lasher"}},
    {1056,"objective",{"Keeper Albagorm","Stonetalon Peak"}},
    {1057,"objective",{"Keeper Albagorm","Stonetalon Peak","Bloodfury Harpies","Bloodfury Ambushers","Bloodfury Slayers","Bloodfury Roguefeathers"}},
    {78124,"title",{"Nar'thalas Almanac"}},
    {78127,"title",{"The Dalaran Digest"}},
    {78142,"title",{"Bewitchments and Glamours"}},
    {78143,"title",{"Secrets of the Dreamers"}},
    {78145,"title",{"Arcanic Systems Manual"}},
    {78146,"title",{"Goaz Scrolls"}},
    {78147,"title",{"Crimes Against Anatomy"}},
    {78148,"title",{"Runes of the Sorcerer-Kings"}},
    {78149,"title",{"Fury of the Land"}},
    {79091,"title",{"Archmage Antonidas: The Unabridged Autobiography"}},
    {79092,"title",{"Archmage Theocritus' Research Journal"}},
    {79093,"title",{"Rumi of Gnomeregan: The Collected Works"}},
    {79094,"title",{"The Lessons of Ta'zo"}},
    {79095,"title",{"The Apothecary's Metaphysical Primer"}},
    {79096,"title",{"Ataeric: On Arcane Curiosities"}},
    {79097,"title",{"Baxtan: On Destructive Magics"}}}
  for _,c in ipairs(contracts) do
    local value=assert(A.quests[c[1]][c[2]],'Missing source-grounded identity field'):lower()
    for _,term in ipairs(c[3]) do assert(value:find(term:lower(),1,true),'Current source recipient/book/escort/target contract failed: '..c[1]..'/'..term) end
  end
  for _,r in ipairs({{389,"progress"},{350,"progress"},{2745,"progress"},{434,"progress"},{394,"progress"},{395,"progress"},{7791,"detail"},{78124,"detail"},{78127,"detail"},{78142,"detail"},{78143,"detail"},{78145,"detail"},{78146,"detail"},{78147,"detail"},{78148,"detail"},{78149,"detail"},{79091,"detail"},{79092,"detail"},{79093,"detail"},{79094,"detail"},{79095,"detail"},{79096,"detail"},{79097,"detail"},{78150,"detail"},{78150,"progress"},{97286,"detail"},{97286,"progress"},{235,"progress"},{742,"progress"},{6383,"detail"},{6383,"progress"},{6542,"progress"},{6545,"detail"},{6546,"detail"},{6547,"detail"},{6482,"progress"},{6544,"progress"},{6641,"progress"},{1056,"progress"}}) do assert(not A.quests[r[1]][r[2]],'Invented current-English-absent state: '..r[1]..'/'..r[2]) end
  assert(not A.quests[7791].detail and not A.quests[7791].objective and A.quests[7791].progress and A.quests[7791].complete,'Donation source boundaries changed')
  for _,id in ipairs({78150,97286}) do
    assert(not A.quests[id].detail and not A.quests[id].objective and not A.quests[id].progress and A.quests[id].complete,'Library reward/access completion-only boundary changed')
    assert(not A.quests[id].complete:find('<name>',1,true),'Copied a book completion into reward/access step')
  end
  for id,wrong in pairs({[78148]='Runes of the Sorceror-Kings',[79092]="Archmage Theocritus's Research Journal"}) do
    questID=id;titleOverride=wrong;fire('QUEST_PROGRESS');flush()
    assert(not A.window:IsShown(),'Invalid upstream book label enabled as runtime alias')
    titleOverride=nil;fire('QUEST_PROGRESS');flush()
    assert(A.window:IsShown(),'Current book title rejected after upstream spelling check')
  end
  questID=0;titleOverride=nil;fire('QUEST_FINISHED')
  print('PASS:47 current-English recipient/book/escort/target contracts plus3 donation/access boundaries, exact book-spelling alias rejection and source-absence checks.')
end

if A.quests[2] and A.quests[98283] and A.quests[2480] then
  debugCommand('off');titleOverride=nil
  for _,id in ipairs({2,23,24,247,1059,1483,1093,1094,1095,1096,1087,1088,1089,6282,6283,86576,6301,6381,6393,6284,467,466,463,276,277,275,98283,279,281,284,285,286,98189,98190,98191,2378,2379,2380,2381,2382,2359,2360,2607,2608,2609,2458,2460,2478,2479,2480}) do
    assert(A.quests[id] and A.quests[id].title,'21 November quest/title missing: '..id)
    questID=id
    for event,field in pairs({QUEST_DETAIL='detail',QUEST_PROGRESS='progress',QUEST_COMPLETE='complete'}) do
      fire(event);flush()
      assert(A.window:IsShown()==(A.quests[id][field]~=nil),'Morning source-state routing failed: '..id..'/'..field)
      assert(MMNorthshireCaptures[id].states[field].title==A.quests[id].en,'Morning capture lost exact ID/title')
    end
  end
  for _,h in ipairs({{6283,"progress"},{463,"detail"},{98190,"detail"},{2608,"detail"}}) do
    questID=h[1];fire(({detail='QUEST_DETAIL',progress='QUEST_PROGRESS',complete='QUEST_COMPLETE'})[h[2]]);flush()
    assert(not A.window:IsShown() and MMNorthshireCaptures[h[1]].states[h[2]].translationFallback~=nil,'Held branch lost original fallback/capture')
  end
  assert(not A.quests[5639].detail and not A.quests[5728].detail,'Historical source holds refilled')
  questID=0;fire('QUEST_FINISHED')
  print('PASS:21NovemberMorning50 records across150 dialogue states, held branch original fallback/capture and historical guards.')
end

if A.quests[2] and A.quests[98283] and A.quests[2480] then
  local contracts={
    {2,"objective",{"Sharptalon's Claw","Senani Thunderheart","Splintertree Post","Ashenvale"}},
    {23,"objective",{"Ursangous's Paw","Senani Thunderheart","Splintertree Post"}},
    {24,"objective",{"Shadumbra's Head","Senani Thunderheart"}},
    {247,"complete",{"Ashenvale Hunt","Horde"}},
    {1059,"objective",{"Falfindel Waywarder","Thousand Needles","Feralas"}},
    {1483,"objective",{"Ziz Fizziks","Windshear Crag"}},
    {1093,"objective",{"Super Reaper 6000 Blueprints","Ziz Fizziks","Stonetalon Mountains"}},
    {1094,"objective",{"Sealed Envelope","Sputtervalve","Barrens"}},
    {1095,"objective",{"Ziz Fizziks","Stonetalon Mountains"}},
    {1096,"objective",{"Gerenzo Wrenchwhistle's Mechanical Arm","Ziz Fizziks"}},
    {1087,"objective",{"Sons of Cenarius","Daughters of Cenarius","Cenarion Botanists","Braelyn Firehand","Sun Rock Retreat"}},
    {1088,"objective",{"Ordanus","Braelyn Firehand"}},
    {1089,"objective",{"Stonetalon Peak","Gatekeeper's Key","Talon Den Hoard"}},
    {6282,"objective",{"Maggran Earthbinder","Sun Rock Retreat","Bloodfury Harpies","Bloodfury Ambushers","Bloodfury Slayers","Bloodfury Roguefeathers"}},
    {6283,"objective",{"Maggran","Bloodfury Ripper"}},
    {86576,"objective",{"Glittering Sunstones","Mor'rogal"}},
    {6301,"objective",{"Tammra Windfield","Gaea Seeds"}},
    {6381,"objective",{"Gaea Seeds","Gaea Dirt Mounds","Enchanted Gaea Seeds","Tammra"}},
    {6393,"objective",{"Incendrites","Tsunaman"}},
    {6284,"objective",{"Besseleth","Besseleth's Fang","Maggran"}},
    {467,"objective",{"Pilot Stonegear"}},
    {466,"objective",{"Incendicite Ore","Pilot Stonegear","Dun Morogh"}},
    {463,"objective",{"Greenwarden"}},
    {276,"objective",{"Mosshide Gnolls","Mosshide Mongrels","Rethiel the Greenwarden","Wetlands"}},
    {277,"objective",{"Rethiel the Greenwarden","Crude Flints"}},
    {275,"objective",{"Fen Creepers","Rethiel the Greenwarden"}},
    {98283,"objective",{"Carnage's Head","Rethiel the Greenwarden","The Green Belt"}},
    {279,"objective",{"Bluegill Murlocs","Gobbler","Gobbler's Head","Karl Boran","Menethil Harbor"}},
    {281,"objective",{"Murloc"}},
    {284,"objective",{"Menethil Statuette"}},
    {285,"objective",{"Murloc","Menethil Statuette"}},
    {286,"objective",{"Karl Boran","Menethil Statuette"}},
    {98189,"objective",{"Menethil Statuette","Captain Stoutfist","Menethil Keep"}},
    {98190,"objective",{"Menethil Statuette","Highlord Bolvar Fordragon","Stormwind Keep"}},
    {98191,"objective",{"Menethil Statuette","Lord Grayson Shadowbreaker","Cathedral of Light"}},
    {2378,"objective",{"Orgrimmar","Shenthul","Cleft of Shadow"}},
    {2380,"objective",{"Shenthul","Cleft of Shadow","Orgrimmar"}},
    {2379,"objective",{"Zando'zan","Cleft of Shadow"}},
    {2382,"objective",{"Ratchet","Wrenix the Wretched"}},
    {2381,"objective",{"Southsea Treasure","Wrenix the Wretched","Ratchet","E.C.A.C.","Thieves' Tools","Wrenix's Gizmotronic Apparatus"}},
    {2360,"objective",{"Westfall","Agent Kearnen"}},
    {2359,"objective",{"Defias Tower Key","Defias Tower","Duskwood Chest","Mathias Shaw","Stormwind","Kearnen's Journal"}},
    {2607,"objective",{"Doc Mixilpixil","Barracks"}},
    {2608,"objective",{"/Lay","Doc Mixilpixil"}},
    {2609,"detail",{"The Finest Thread","Dr. Montgomery"}},
    {2460,"objective",{"Shenthul"}},
    {2458,"objective",{"Venture Co. Tower","Sludge Fen","Shattered Hand","Taskmaster Fizzule","Flare Gun","/Salute"}},
    {2478,"objective",{"Silixiz's Tower Key","Foreman Silixiz","Mutated Venture Co. Drones","Venture Co. Patrollers","Venture Co. Lookouts","Grand Foreman Gallywix","Cache of Zanzil's Altered Mixture","Gallywix's Head","Shenthul","Orgrimmar"}},
    {2479,"objective",{"Tarren Mill","Hillsbrad Foothills","Sample of Zanzil's Mixture","Serge Hinott","Zeppelin","Undercity","Silverpine","Hillsbrad"}},
    {2480,"objective",{"Serge Hinott"}}}
  for _,c in ipairs(contracts) do
    local value=assert(A.quests[c[1]][c[2]],'Missing source-grounded identity field'):lower()
    for _,term in ipairs(c[3]) do assert(value:find(term:lower(),1,true),'Current source recipient/target/item contract failed: '..c[1]..'/'..term) end
  end
  for _,r in ipairs({{247,"detail"},{247,"progress"},{1059,"progress"},{1483,"progress"},{1095,"progress"},{467,"progress"},{463,"progress"},{281,"progress"},{284,"progress"},{285,"progress"},{2378,"progress"},{2380,"progress"},{2379,"progress"},{2382,"progress"},{2360,"progress"},{2607,"progress"},{2458,"progress"},{2480,"progress"}}) do assert(not A.quests[r[1]][r[2]],'Invented current-English-absent state: '..r[1]..'/'..r[2]) end
  for _,c in ipairs({
    {1089,"objective",{"Gatekeeper's Key","Talon Den Hoard"}},
    {2381,"objective",{"Wrenix's Gizmotronic Apparatus","E.C.A.C.","Thieves' Tools","E.C.A.C."}},
    {2458,"objective",{"Flare Gun","Taskmaster Fizzule","/Salute"}},
    {2478,"objective",{"Silixiz's Tower Key","Mutated Venture Co. Drones","Venture Co. Patrollers","Venture Co. Lookouts","Grand Foreman Gallywix","Gallywix's lockbox","Cache of Zanzil's Altered Mixture","Gallywix's Head","Shenthul"}},
    {2479,"objective",{"Zeppelin","Undercity","Silverpine","Hillsbrad"}}}) do
    local value=assert(A.quests[c[1]][c[2]])
    local pos=1
    for _,term in ipairs(c[3]) do
      local a,b=value:find(term,pos,true);assert(a,'Current source command/quantity/stage order contract failed: '..c[1]..'/'..term);pos=b+1
    end
  end
  assert(A.quests[1094].en==A.quests[1095].en and A.quests[1094].objective~=A.quests[1095].objective,'Further Instructions distinct recipients collapsed')
  assert(A.quests[286].en==A.quests[98189].en and A.quests[286].objective~=A.quests[98189].objective,'Statuette distinct recipients collapsed')
  assert(A.quests[98190].en==A.quests[98191].en and A.quests[98190].objective~=A.quests[98191].objective,'Family Friend stages collapsed')
  assert(A.quests[2607].en==A.quests[2608].en and A.quests[2608].en==A.quests[2609].en and A.quests[2607].objective~=A.quests[2608].objective,'Zanzil referral/exam/cure stages collapsed')
  assert(not A.quests[247].detail and not A.quests[247].objective and not A.quests[247].progress and A.quests[247].complete,'Hunt reward-only boundary changed')
  assert(not A.quests[2609].objective and A.quests[2609].detail,'Held cure objective disabled supported offer or was refilled')
  questID=0;titleOverride=nil;fire('QUEST_FINISHED')
  print('PASS:50 current-English identity contracts, same-title stage separation, source absences, quantities and executable command order.')
end

if A.quests[1070] and A.quests[95216] and A.quests[970] then
  debugCommand('off');titleOverride=nil
  for _,id in ipairs({1070,1071,1072,1073,1074,1075,1076,1077,1085,1079,1080,1081,1082,1083,1091,1058,1068,1090,1092,86574,95216,92401,92421,97288,97289,97290,97291,97292,95250,95189,95204,95195,92415,95161,92422,970,973,1140,1167,976,943,994,1026,1027,1028,1055,1029,1030,1045,1046}) do
    assert(A.quests[id] and A.quests[id].title,'21November afternoon quest/title missing:'..id)
    questID=id
    for event,field in pairs({QUEST_DETAIL='detail',QUEST_PROGRESS='progress',QUEST_COMPLETE='complete'}) do
      fire(event);flush()
      assert(A.window:IsShown()==(A.quests[id][field]~=nil),'Afternoon source-state routing failed:'..id..'/'..field)
      assert(MMNorthshireCaptures[id].states[field].title==A.quests[id].en,'Afternoon capture lost exact ID/title')
    end
  end
  for _,h in ipairs({{95250,"detail"}}) do
    questID=h[1];fire(({detail='QUEST_DETAIL',progress='QUEST_PROGRESS',complete='QUEST_COMPLETE'})[h[2]]);flush()
    assert(not A.window:IsShown() and MMNorthshireCaptures[h[1]].states[h[2]].translationFallback~=nil,'Held source branch lost fallback/capture')
  end
  assert(not A.quests[5639].detail and not A.quests[5728].detail,'Historical source holds refilled')
  questID=0;fire('QUEST_FINISHED')
  print('PASS:21NovemberAfternoon50 records across150 dialogue cases, held source fallback/capture and historical guards.')
end

if A.quests[1070] and A.quests[95216] and A.quests[970] then
  local contracts={
    {1070,"objective",{"Kaela Shadowspear","Windshear Crag","Stonetalon Mountains"}},
    {1085,"objective",{"Gaxim"}},
    {1071,"objective",{"Venture Co. Loggers","Venture Co. Deforesters","Gaxim Rustfizzle"}},
    {1072,"objective",{"Lomac Gearstrip","Ironforge"}},
    {1073,"objective",{"Minor Mana Potions","Elixirs of Minor Fortitude","Lomac Gearstrip"}},
    {1074,"objective",{"Nitromirglyceronium","Gaxim Rustfizzle"}},
    {1075,"objective",{"Collin Mauren","Stormwind"}},
    {1076,"objective",{"Dust Devil Debris","Collin Mauren"}},
    {1077,"objective",{"Scroll of Messaging","Gaxim Rustfizzle"}},
    {1079,"objective",{"Venture Co.'s Engineering Plans","Windshear Crag"}},
    {1080,"objective",{"Venture Co. Letters","Windshear Mine","Windshear Crag"}},
    {1091,"objective",{"Venture Co. Letters","Kaela Shadowspear"}},
    {1083,"objective",{"Smoldering Embers","Charred Vale","Kaela Shadowspear"}},
    {1082,"objective",{"Sentinel Thenysil","Ashenvale"}},
    {1081,"objective",{"Tyrande Whisperwind","Darnassus"}},
    {1090,"objective",{"Piznik"}},
    {1092,"objective",{"Unidentified Ore","Ziz Fizziks"}},
    {1058,"objective",{"Witch Doctor Jin'Zil","Malaka'jin","Stonetalon Sap","Twilight Whiskers","Courser Eyes","Fey Dragon Scale"}},
    {1068,"objective",{"XT:4","XT:9","Seereth Stonebreak","Stonetalon Mountains","Barrens"}},
    {86574,"objective",{"Stonetalon Supplies","Pridewing Wyverns","Innkeeper Faralia"}},
    {95216,"objective",{"Highly Toxic Strain","Witherfang","Ruins of Lordaeron","Theodore Griffs","Undercity"}},
    {92401,"objective",{"Edward Heartweaver","Ruins of Lordaeron"}},
    {92421,"objective",{"Intact Limbs","Ruins of Lordaeron","Morbin Lightbane","Undercity"}},
    {97288,"objective",{"Abominable Head","Master Apothecary Faranell","Undercity"}},
    {97289,"objective",{"Head of the Baron","Othmar","Undercity"}},
    {97290,"objective",{"Master Apothecary Faranell","Undercity"}},
    {97291,"objective",{"Toxic Skullcap","Tawny Grisette","Trade Quarter","Blisterweed","Herbalism Trainer","Essence of Agony","Rogues' Quarter","Master Apothecary Faranell"}},
    {97292,"objective",{"Hissing Serum","Othmar","Master Apothecary Faranell"}},
    {95250,"objective",{"Head of the Baron","Ruins of Lordaeron","Captain Truman"}},
    {95189,"objective",{"Crest of Lordaeron","Lady Dena Kennedy","Stormwind City"}},
    {95204,"objective",{"Crest of Lordaeron","Oran Snakewrithe","Undercity"}},
    {95195,"objective",{"Bloodied Insignias","General Marcus Jonathan","Stormwind City"}},
    {92415,"objective",{"Blood-Stained Letter","Orphan Matron Nightingale","Stormwind City"}},
    {95161,"objective",{"Blood-Stained Letter","Avette Fellwood","Duskwood"}},
    {92422,"objective",{"Rath'mael","Ruins of Lordaeron","Deathguard Kristof","Brill"}},
    {970,"objective",{"Glowing Soul Gem","Delgren the Purifier","Maestra's Post"}},
    {973,"objective",{"Ilkrud Magthrull's Tome","Delgren the Purifier"}},
    {1140,"objective",{"Highborne","Night Run","Satyrnaar","Delgren the Purifier"}},
    {1167,"objective",{"Balthule Shadowstrike","Tower of Althalaxx"}},
    {976,"objective",{"Delgren the Purifier","Maestra's Post","Feero","Ashenvale Forest"}},
    {943,"objective",{"Archaeologist Flagongut","Menethil Harbor","Stone of Relu","Flagongut's Fossil"}},
    {994,"objective",{"Volcor","Terenthis","Auberdine"}},
    {1026,"objective",{"Wooden Key","Dartol's Rod","Shael'dryn"}},
    {1027,"objective",{"Dartol's Rod","Shael'dryn"}},
    {1028,"objective",{"Dartol's Rod"}},
    {1055,"objective",{"Shael'dryn"}},
    {1029,"objective",{"Raene Wolfrunner","Astranaar"}},
    {1030,"objective",{"Dartol's Rod of Transformation"}},
    {1045,"objective",{"Bloodtooth Guards","Ran Bloodtooth's Skull","Krolg","Lake Mystral"}},
    {1046,"objective",{"Ran Bloodtooth's Skull","Dartol's Rod of Transformation","Raene Wolfrunner","Astranaar"}}}
  for _,c in ipairs(contracts) do
    local value=assert(A.quests[c[1]][c[2]],'Missing source-grounded identity field'):lower()
    for _,term in ipairs(c[3]) do assert(value:find(term:lower(),1,true),'Current source recipient/target/item contract failed:'..c[1]..'/'..term) end
  end
  for _,r in ipairs({{1070,"progress"},{1085,"progress"},{1072,"progress"},{1075,"progress"},{1082,"progress"},{1081,"progress"},{92401,"progress"},{97290,"progress"},{95250,"progress"},{95250,"complete"},{92422,"progress"},{1167,"progress"},{994,"progress"},{1055,"progress"},{1029,"progress"},{1030,"progress"}}) do assert(not A.quests[r[1]][r[2]],'Invented current-English-absent state:'..r[1]..'/'..r[2]) end
  for _,c in ipairs({
    {976,"objective",{"Feero","Delgren the Purifier"}},
    {994,"objective",{"Volcor","Terenthis"}},
    {1026,"objective",{"Wooden Key","Dartol's Rod","Shael'dryn"}},
    {1027,"objective",{"Dartol's Rod","Shael'dryn"}},
    {1046,"objective",{"Ran Bloodtooth's Skull","Dartol's Rod of Transformation","Raene Wolfrunner"}},
    {97291,"objective",{"Trade Quarter","Tawny Grisette","Toxic Skullcap","Herbalism Trainer","Blisterweed","Rogues' Quarter","Essence of Agony"}}}) do
    local value=assert(A.quests[c[1]][c[2]]);local pos=1
    for _,term in ipairs(c[3]) do local a,b=value:find(term,pos,true);assert(a,'Current source ordered task failed:'..c[1]..'/'..term);pos=b+1 end
  end
  for _,chain in ipairs({{1070,1085},{1073,1074},{1090,1092},{97288,97289,97290,97291,97292},{95189,95204},{92415,95161},{1026,1027,1028,1055,1029,1030,1045,1046}}) do
    for i=2,#chain do
      local a,b=A.quests[chain[i-1]],A.quests[chain[i]]
      assert(a.en==b.en and a.objective~=b.objective,'Distinct same-title tasks collapsed:'..chain[i])
    end
  end
  assert(not A.quests[95250].detail and not A.quests[95250].progress and not A.quests[95250].complete and A.quests[95250].objective,'Unresolved Human branch or absent replies invented')
  questID=0;titleOverride=nil;fire('QUEST_FINISHED')
  print('PASS:50 afternoon source identity contracts, eight same-title Raene stages, Torment/faction deliveries, source absences and ordered tasks.')
end

if A.quests[256] and A.quests[98095] and A.quests[822] then
  debugCommand('off');titleOverride=nil
  for _,id in ipairs({878,5052,879,906,843,846,849,874,873,868,883,884,885,822,893,6981,3369,3370,97003,97005,256,468,455,473,469,470,484,471,98072,98240,98245,98197,98282,98459,98461,494,527,528,98094,98095,529,532,539,541,550,496,499,498,546,549}) do
    assert(A.quests[id] and A.quests[id].title,'22November quest/title missing:'..id)
    questID=id
    for event,field in pairs({QUEST_DETAIL='detail',QUEST_PROGRESS='progress',QUEST_COMPLETE='complete'}) do
      fire(event);flush()
      assert(A.window:IsShown()==(A.quests[id][field]~=nil),'Morning state routing failed:'..id..'/'..field)
      assert(MMNorthshireCaptures[id].states[field].title==A.quests[id].en,'Morning capture lost ID/title')
    end
  end
  for _,h in ipairs({{874,"detail"},{455,"progress"},{470,"complete"}}) do
    questID=h[1];fire(({detail='QUEST_DETAIL',progress='QUEST_PROGRESS',complete='QUEST_COMPLETE'})[h[2]]);flush()
    assert(not A.window:IsShown() and MMNorthshireCaptures[h[1]].states[h[2]].translationFallback~=nil,'Held branch lost English fallback/capture')
  end
  assert(not A.quests[5639].detail and not A.quests[5728].detail and not A.quests[95250].detail,'Historical source holds refilled')
  questID=0;fire('QUEST_FINISHED')
  print('PASS:22NovemberMorning50 records and150 dialogue routing/capture cases; English fallback for held states.')
end

if A.quests[256] and A.quests[98095] and A.quests[822] then
  local contracts={
    {878,"objective",{"Bristleback Water Seekers","Bristleback Thornweavers","Bristleback Geomancers","Mangletooth"}},
    {5052,"objective",{"Blood Shard","Mangletooth","Camp Taurajo"}},
    {879,"objective",{"Nak","Kuz","Lok Orcbane","Mangletooth"}},
    {906,"objective",{"Lok's Skull","Thork","Crossroads"}},
    {843,"objective",{"Bael'dun Excavators","Bael'dun Foremen","Khazgorm's Journal","Gann Stonespire"}},
    {846,"objective",{"Nitroglycerin","Wood Pulp","Sodium Nitrate","Gann Stonespire"}},
    {849,"objective",{"Bael Modan","Gann Stonespire"}},
    {874,"objective",{"Mahren Skyseer"}},
    {873,"objective",{"Heart of Isha Awak","Mahren Skyseer"}},
    {868,"objective",{"Silithid Eggs","Digging Claw","Korran"}},
    {883,"objective",{"Hoof of Lakota'mani","Jorn"}},
    {884,"objective",{"Owatanka's Tailspike","Jorn"}},
    {885,"objective",{"Washte Pawne's Feather","Jorn Skyseer"}},
    {822,"objective",{"Lightning Glands","Thunderhawk Saliva Gland","Kodo Liver","Brewmaster Drohn"}},
    {893,"objective",{"Razormane Backstabber","Charred Razormane Wand","Razormane War Shield","Tatternack Steelforge"}},
    {6981,"objective",{"Ratchet"}},
    {3369,"objective",{"Nightmare Shard","Hamuul Runetotem","Elder Rise"}},
    {3370,"objective",{"Nightmare Shard","Mathrengyl Bearwalker","Darnassus"}},
    {97003,"objective",{"Chol'aruk","Gur'ak"}},
    {97005,"objective",{"Chol'aruk's Head","Bainham"}},
    {256,"objective",{"Chok'sul","Magistrate Bluntnose","Thelsamar"}},
    {468,"objective",{"Mountaineer Rockgar"}},
    {455,"objective",{"Dun Algaz","Dragonmaw Scouts","Dragonmaw Grunts","Valstag Ironjaw","Menethil Harbor"}},
    {473,"objective",{"Captain Stoutfist"}},
    {469,"objective",{"Bundle of Crocolisk Skins","James Halloran","Menethil Harbor"}},
    {470,"objective",{"Ironbeard's Tomb","Sida","Menethil Harbor"}},
    {484,"detail",{"James Halloran","Einar"}},
    {471,"objective",{"Giant Crocolisk Skins","James Halloran"}},
    {98072,"objective",{"Pristine Crimson Scales","James Halloran"}},
    {98240,"objective",{"Crimson Crate","Howin Kindfeather","Menethil Harbor"}},
    {98245,"objective",{"Razormaw Incisors","Howin Kindfeather"}},
    {98197,"objective",{"Khaz Modan Timber","Khaz Modan Iron","Valstag Ironjaw"}},
    {98282,"objective",{"Unruptured Stalker Gland","Thelgen Rock","Caitlin Grassman"}},
    {98459,"objective",{"Tom's Gift","Bart Tidewater"}},
    {98461,"objective",{"Hollee's Note","Tarrel Rockweaver"}},
    {494,"objective",{"Tarren Mill","Deathstalker Lesh","High Executor Darthalia"}},
    {527,"objective",{"Hillsbrad Farmhands","Hillsbrad Farmers","Farmer Ray","Farmer Getz","Darthalia"}},
    {528,"objective",{"Hillsbrad Peasants","Darthalia"}},
    {98094,"objective",{"High Executor Darthalia","Deathstalker Masoj","Tarren Mill","Dun Garok"}},
    {98095,"objective",{"Deathstalker Masoj","Apothecary Vials","Hillsbrad Foothills"}},
    {529,"objective",{"Blacksmith Verringtan","Hillsbrad Apprentice Blacksmiths","Darthalia"}},
    {532,"objective",{"Magistrate Burnside","Hillsbrad Councilmen","Hillsbrad Proclamation","Hillsbrad Town Registry"}},
    {539,"objective",{"Foreman Bonds","Hillsbrad Miners","Darthalia"}},
    {541,"detail",{"Dun Garok"}},
    {550,"objective",{"Darthalia's Sealed Commendation","Varimathras","Undercity"}},
    {496,"objective",{"Apothecary Lydon","Gray Bear Tongues","Creeper Ichor"}},
    {499,"objective",{"Umpi","Elixir of Suffering"}},
    {498,"objective",{"Krusk","Drull","Tog'thar","Durnholde Keep"}},
    {546,"objective",{"Deathguard Samsa","Hillsbrad Human Skulls"}},
    {549,"objective",{"Syndicate Rogues","Syndicate Watchmen","High Executor Darthalia"}}}
  for _,c in ipairs(contracts) do
    local value=assert(A.quests[c[1]][c[2]],'Missing identity field'):lower()
    for _,term in ipairs(c[3]) do assert(value:find(term:lower(),1,true),'Source target/recipient/item identity failed:'..c[1]..'/'..term) end
  end
  for _,r in ipairs({{874,"progress"},{468,"progress"},{473,"progress"},{494,"progress"}}) do assert(not A.quests[r[1]][r[2]],'Invented absent primary state:'..r[1]..'/'..r[2]) end
  for _,h in ipairs({{874,"detail"},{455,"progress"},{470,"complete"},{484,"objective"},{541,"objective"}}) do assert(not A.quests[h[1]][h[2]],'Source-conflicting state refilled:'..h[1]..'/'..h[2]) end
  for _,chain in ipairs({{879,906},{846,849},{3369,3370},{97003,97005},{527,528,529,532,539},{496,499}}) do
    for i=2,#chain do
      local a,b=A.quests[chain[i-1]],A.quests[chain[i]]
      assert(a.en==b.en and a.objective~=b.objective,'Distinct same-title task collapsed:'..chain[i])
    end
  end
  assert(A.quests[541].en==A.quests[550].en and not A.quests[541].objective and A.quests[541].detail and A.quests[550].objective,'Hillsbrad disputed numbers or final commendation boundary failed')
  assert(A.quests[821].en==A.quests[822].en and A.quests[821].objective~=A.quests[822].objective,'Final Chen recipe collapsed into earlier recipe')
  questID=0;titleOverride=nil;fire('QUEST_FINISHED')
  print('PASS:50 current-English identity contracts, same-title steps, absent states and explicit source holds.')
end

if A.quests[98576] and A.quests[91858] and A.quests[6562] then
  debugCommand('off');titleOverride=nil
  for _,id in ipairs({98576,897,862,97250,98093,3513,3514,97538,98251,98252,1195,1196,1197,1130,1131,98028,1054,1035,1143,981,3681,91858,91859,91860,91861,91862,96204,95034,95036,95111,95125,95126,95140,1442,95042,6562,6563,6564,6565,971,1198,1199,1200,6561,1275,3765,1740,1098,1013,1014}) do
    assert(A.quests[id] and A.quests[id].title,'22November quest/title missing:'..id)
    questID=id
    for event,field in pairs({QUEST_DETAIL='detail',QUEST_PROGRESS='progress',QUEST_COMPLETE='complete'}) do
      fire(event);flush()
      assert(A.window:IsShown()==(A.quests[id][field]~=nil),'Morning state routing failed:'..id..'/'..field)
      assert(MMNorthshireCaptures[id].states[field].title==A.quests[id].en,'Morning capture lost ID/title')
    end
  end
  for _,h in ipairs({{3514,"progress"}}) do
    questID=h[1];fire(({detail='QUEST_DETAIL',progress='QUEST_PROGRESS',complete='QUEST_COMPLETE'})[h[2]]);flush()
    assert(not A.window:IsShown() and MMNorthshireCaptures[h[1]].states[h[2]].translationFallback~=nil,'Held branch lost English fallback/capture')
  end
  assert(not A.quests[5639].detail and not A.quests[5728].detail and not A.quests[95250].detail,'Historical source holds refilled')
  questID=0;fire('QUEST_FINISHED')
  print('PASS:22NovemberAfternoon50 records and150 dialogue routing/capture cases; English fallback for held states.')
end

if A.quests[98576] and A.quests[91858] and A.quests[6562] then
  local contracts={
    {98576,"objective",{"Glyphic Parchment","Mai'ah","Valley of Trials"}},
    {897,"objective",{"Harvester's Head","Jorn Skyseer"}},
    {862,"objective",{"Dig Rats","Grub","Crossroads"}},
    {97250,"objective",{"Alliance","Barrens","Dustwallow Marsh","Grunt Logmar","Camp Taurajo"}},
    {98093,"objective",{"Sulhasa","Stormhide","Hecklefang Stalkers"}},
    {3513,"objective",{"Runed Scroll","Barrens"}},
    {3514,"objective",{"Talon Den","Rynthariel the Keymaster"}},
    {97538,"objective",{"Tah Winterhoof","Thunder Bluff","Mirkweed Pods","Mirkfallon Lake"}},
    {98251,"objective",{"Shadowhorn Stag","Ashenvale Bear","Va'xug","Fallen Sky Lake"}},
    {98252,"objective",{"Va'xug","Eye of Kilrogg","Ashenvale"}},
    {1195,"objective",{"Filled Etched Phial","Zangen Stonehoof","Thunder Bluff"}},
    {1196,"objective",{"Filled Etched Phial","Rau Cliffrunner","Freewind Post"}},
    {1197,"objective",{"Cloven Hoof","Rau Cliffrunner","Freewind Post"}},
    {1130,"objective",{"Melor Stonehoof","Thunder Bluff"}},
    {1131,"objective",{"Steelsnap's Rib","Melor Stonehoof","Thunder Bluff"}},
    {98028,"objective",{"Clouded Water Globe","Onu","Grove of the Ancients","Darkshore"}},
    {1054,"objective",{"Dal Bloodclaw's Skull","Raene Wolfrunner","Astranaar"}},
    {1035,"objective",{"Fallen Moonstone","Shadethicket Oracle","Pelturas","Astranaar"}},
    {1143,"objective",{"Athrikus Narassin","Balthule Shadowstrike","Tower of Althalaxx"}},
    {981,"objective",{"Delgren the Purifier","Maestra's Post"}},
    {3681,"objective",{"Duthorian Rall","Stormwind"}},
    {91858,"objective",{"Sepulcher","Silverpine Forest","Trevan Rol","Earthen Ring"}},
    {91859,"objective",{"Deathguard Baldren","Earthen Ring","Sepulcher"}},
    {91860,"objective",{"Fenris Isle","Earthen Ring"}},
    {91861,"objective",{"Fenris Keep","Earthen Ring"}},
    {91862,"objective",{"Fenris Isle Key","Rot Hide Gnolls","Lumina Windsinger"}},
    {96204,"objective",{"Lumina Windsinger","Fenris Keep"}},
    {95034,"objective",{"Lumina Windsinger","Sepulcher"}},
    {95036,"objective",{"Trevan Rol","Sepulcher"}},
    {95111,"objective",{"Ott"}},
    {95125,"objective",{"Ott"}},
    {95126,"objective",{"Ott's Masterwork","Trevan Rol","Silverpine Forest"}},
    {95140,"objective",{"Moonsilver Blade","Old Fire-Eye","Silverpine Forest"}},
    {1442,"objective",{"Kor Gem","Thundris Windweaver","Darkshore"}},
    {95042,"objective",{"Kor Gem","Ulric Frostveil","Ashenvale"}},
    {6562,"objective",{"Je'neu Sancrea","Ashenvale"}},
    {6563,"objective",{"Sapphires of Aku'Mai","Je'neu Sancrea"}},
    {6564,"objective",{"Damp Note","Je'neu Sancrea"}},
    {6565,"objective",{"Lorgus Jett","Blackfathom Deeps","Je'neu Sancrea"}},
    {971,"objective",{"Lorgalis Manuscript","Gerrig Bonegrip","Forlorn Cavern","Ironforge"}},
    {1198,"objective",{"Argent Guard Thaelrid","Blackfathom Deeps"}},
    {1199,"objective",{"Twilight Pendants","Argent Guard Manados","Darnassus"}},
    {1200,"objective",{"Twilight Lord Kelris","Dawnwatcher Selgorm","Darnassus"}},
    {6561,"objective",{"Twilight Lord Kelris","Bashana Runetotem","Thunder Bluff"}},
    {1275,"objective",{"Gershala Nightwhisper","Auberdine","Corrupt Brain stems"}},
    {3765,"objective",{"Gershala Nightwhisper","Auberdine"}},
    {1740,"objective",{"Soran'ruk Fragments","Large Soran'ruk Fragment","Doan Karhan","Barrens"}},
    {1098,"objective",{"Deathstalker Adamant","Deathstalker Vincent"}},
    {1013,"objective",{"Book of Ur","Keeper Bel'dugur","Apothecarium","Undercity"}},
    {1014,"objective",{"Arugal","Dalar Dawnweaver","Sepulcher"}}}
  for _,c in ipairs(contracts) do
    local value=assert(A.quests[c[1]][c[2]],'Missing identity field'):lower()
    for _,term in ipairs(c[3]) do assert(value:find(term:lower(),1,true),'Source target/recipient/item identity failed:'..c[1]..'/'..term) end
  end
  for _,r in ipairs({{97250,"progress"},{98252,"progress"},{1130,"progress"},{981,"progress"},{3681,"progress"},{91858,"progress"},{91859,"progress"},{91860,"progress"},{91861,"progress"},{96204,"progress"},{6562,"progress"},{1198,"progress"},{3765,"progress"},{1098,"progress"}}) do assert(not A.quests[r[1]][r[2]],'Invented absent primary state:'..r[1]..'/'..r[2]) end
  for _,h in ipairs({{3514,"progress"}}) do assert(not A.quests[h[1]][h[2]],'Source-conflicting state refilled:'..h[1]..'/'..h[2]) end
  for _,chain in ipairs({{1195,1196,1197},{1143,981},{1442,95042},{6564,6565},{1200,6561}}) do
    for i=2,#chain do
      local a,b=A.quests[chain[i-1]],A.quests[chain[i]]
      assert(a.en==b.en and a.objective~=b.objective,'Distinct same-title tasks collapsed:'..chain[i])
    end
  end
  assert(A.quests[91862].objective~=A.quests[96204].objective and A.quests[95111].objective~=A.quests[95125].objective and A.quests[95126].objective~=A.quests[95140].objective,'Paladin key/free/escort/forge/watch/return/use stages collapsed')
  questID=0;titleOverride=nil;fire('QUEST_FINISHED')
  print('PASS:50 current-English identity contracts, same-title steps, absent states and explicit source holds.')
end

if A.quests[1698] and A.quests[1823] and A.quests[1649] then
  debugCommand('off');titleOverride=nil
  for _,id in ipairs({1698,1699,1702,1701,1782,1700,1705,1706,1703,1710,1711,1704,1708,1709,1823,1824,1825,1838,1848,1839,1842,1843,1840,1844,1845,1841,1846,1847,1793,1794,1649,1650,1651,1652,1653,1654,1655,1806,98575,94472,1464,98287,98341,98404,98738,97979,98386,96395,3861,97583}) do
    assert(A.quests[id] and A.quests[id].title,'23November quest/title missing:'..id)
    questID=id
    for event,field in pairs({QUEST_DETAIL='detail',QUEST_PROGRESS='progress',QUEST_COMPLETE='complete'}) do
      fire(event);flush()
      assert(A.window:IsShown()==(A.quests[id][field]~=nil),'Morning state routing failed:'..id..'/'..field)
      assert(MMNorthshireCaptures[id].states[field].title==A.quests[id].en,'Morning capture lost ID/title')
    end
  end
  for _,h in ipairs({{1844,"detail"},{1846,"detail"},{1655,"detail"},{1464,"detail"}}) do
    questID=h[1];fire(({detail='QUEST_DETAIL',progress='QUEST_PROGRESS',complete='QUEST_COMPLETE'})[h[2]]);flush()
    assert(not A.window:IsShown() and MMNorthshireCaptures[h[1]].states[h[2]].translationFallback~=nil,'Held branch lost English fallback/capture')
  end
  assert(not A.quests[5639].detail and not A.quests[5728].detail and not A.quests[95250].detail,'Historical source holds refilled')
  questID=0;fire('QUEST_FINISHED')
  print('PASS:23NovemberMorning50 records and150 dialogue routing/capture cases; English fallback for held states.')
end

if A.quests[1698] and A.quests[1823] and A.quests[1649] then
  local contracts={
    {1698,"objective",{"Yorus Barleybrew"}},
    {1699,"objective",{"Rethban Caverns","Yorus Barleybrew"}},
    {1702,"objective",{"Cask of Scalder","Furen Longbeard"}},
    {1701,"objective",{"Furen Longbeard","Stormwind"}},
    {1782,"complete",{"Furen Longbeard","Alliance"}},
    {1700,"objective",{"Furen's Notes","Grimand Elmore"}},
    {1705,"objective",{"Burning Blood","Burning Rock","Grimand Elmore","Stormwind"}},
    {1706,"complete",{"Furen","<name>"}},
    {1703,"objective",{"Furen's Notes","Mathiel"}},
    {1710,"objective",{"Sunscorched Shells","Mathiel","Darnassus"}},
    {1711,"complete",{"Furen","<name>"}},
    {1704,"objective",{"Furen's Notes","Klockmort Spannerspan"}},
    {1708,"objective",{"Searing Coral","Klockmort Spannerspan","Ironforge"}},
    {1709,"complete",{"Furen","<name>"}},
    {1823,"objective",{"Ruga Ragetotem"}},
    {1824,"objective",{"twitching antennae","Ruga Ragetotem","Camp Taurajo"}},
    {1825,"objective",{"Thun'grim Firegaze","Barrens"}},
    {1838,"objective",{"Thun'grim Firegaze","Smoky Iron Ingots","Powdered Azurite","Iron Bars","Vial of Phlogiston"}},
    {1848,"complete",{"<name>"}},
    {1839,"objective",{"Ula'elek","Durotar"}},
    {1842,"objective",{"Uncloven Satyr Hooves","Ula'elek","Sen'jin Village"}},
    {1843,"complete",{"<name>"}},
    {1840,"objective",{"Orm Stonehoof","Thunder Bluff"}},
    {1844,"objective",{"Galvanized Horn","Orm Stonehoof","Thunder Bluff"}},
    {1845,"complete",{"Earthmother","<name>"}},
    {1841,"objective",{"Velora Nitely","Undercity"}},
    {1846,"objective",{"Sturdy Dragonmaw Shinbones","Velora Nitely","Undercity"}},
    {1847,"complete",{"Scourge","<name>"}},
    {1793,"complete",{"Light","Cathedral of Light","<name>"}},
    {1794,"complete",{"Light","Cathedral of Light","<name>"}},
    {1649,"objective",{"Duthorian Rall","Stormwind"}},
    {1650,"objective",{"Daphne Stilwell","Westfall"}},
    {1651,"objective",{"Daphne Stilwell","Defias"}},
    {1652,"objective",{"Duthorian Rall","Stormwind"}},
    {1653,"objective",{"Jordan Stilwell","Ironforge"}},
    {1654,"objective",{"Jordan's Weapon Notes","Whitestone Oak Lumber","Bailor's Refined Ore Shipment","Jordan's Smithing Hammer","Kor Gem","Jordan Stilwell"}},
    {1655,"objective",{"Jordan's Ore Shipment","Bailor Stonehand","Loch Modan"}},
    {1806,"objective",{"Jordan Stilwell"}},
    {98575,"objective",{"Tainted Tablet","Nartok","Valley of Trials"}},
    {94472,"objective",{"Teo Hammerstorm","Earth Sapta"}},
    {1464,"objective",{"Telf Joolam","Fire Sapta"}},
    {98287,"objective",{"Sprite Jumpsprocket","Stormwind"}},
    {98341,"objective",{"Avatar of Saeyleenan","Moonglade"}},
    {98404,"objective",{"Relic of the Fang","Relic of the Claw","Relic of the Silent Shadow","Stormrage Barrow Den","Avatar of Saeyleenan"}},
    {98738,"objective",{"Dendrite"}},
    {97979,"objective",{"Elune's Light","Shadowmeld"}},
    {98386,"objective",{"Greater Tarantulas","Tarantula Eggs","Alther's Mill","Foreman Oslow","Redridge"}},
    {96395,"objective",{"Faldrim Anvilmar","Ghostly Attendant","Hall of Thanes"}},
    {3861,"objective",{"Special Chicken Feed","/cheer"}},
    {97583,"objective",{"Nutritious Slime Sludge"}}}
  for _,c in ipairs(contracts) do
    local value=assert(A.quests[c[1]][c[2]],'Missing source identity/placeholder field'):lower()
    for _,term in ipairs(c[3]) do assert(value:find(term:lower(),1,true),'Source target/recipient/item identity failed:'..c[1]..'/'..term) end
  end
  for _,r in ipairs({{1698,"progress"},{1782,"detail"},{1782,"progress"},{1706,"detail"},{1706,"progress"},{1711,"detail"},{1711,"progress"},{1709,"detail"},{1709,"progress"},{1823,"progress"},{1825,"progress"},{1848,"detail"},{1848,"progress"},{1839,"progress"},{1843,"detail"},{1843,"progress"},{1840,"progress"},{1845,"detail"},{1845,"progress"},{1841,"progress"},{1847,"detail"},{1847,"progress"},{1793,"detail"},{1793,"progress"},{1794,"detail"},{1794,"progress"},{1649,"progress"},{1650,"progress"},{1652,"progress"},{1653,"progress"},{1806,"progress"},{94472,"detail"},{94472,"progress"},{1464,"progress"},{98287,"progress"},{98287,"complete"},{98341,"progress"},{98738,"progress"},{96395,"progress"},{96395,"complete"}}) do assert(not A.quests[r[1]][r[2]],'Invented absent primary state:'..r[1]..'/'..r[2]) end
  for _,h in ipairs({{1844,"detail"},{1846,"detail"},{1655,"detail"},{1464,"detail"}}) do assert(not A.quests[h[1]][h[2]],'Source-conflicting state refilled:'..h[1]..'/'..h[2]) end
  for _,ids in ipairs({{1700,1703,1704},{1839,1840,1841},{1653,1654,1806},{98341,98404}}) do
    for i=2,#ids do assert(A.quests[ids[i-1]].objective~=A.quests[ids[i]].objective,'Distinct referral/material/action collapsed:'..ids[i]) end
  end
  assert(A.quests[1649].en==A.quests[1652].en and A.quests[1649].detail~=A.quests[1652].detail,'Initial versusreturnValorcontextcollapsed')
  assert(A.quests[1650].en==A.quests[1651].en and A.quests[1650].objective~=A.quests[1651].objective and A.quests[1651].objective~=A.quests[1652].objective,'Travel/defend/reportValorstagescollapsed')
  for _,id in ipairs({1782,1706,1711,1709,1848,1843,1845,1847,1793,1794}) do
    assert(A.quests[id].title and A.quests[id].complete and not A.quests[id].detail and not A.quests[id].objective and not A.quests[id].progress,'Reward-onlysourceboundaryinvented:'..id)
  end
  questID=0;titleOverride=nil;fire('QUEST_FINISHED')
  print('PASS:50 current-English identity contracts, same-title steps, absent states and explicit source holds.')
end

if A.quests[1509] and A.quests[305] and A.quests[501] then
  debugCommand('off');titleOverride=nil
  for _,id in ipairs({1509,1510,1511,1515,1512,1513,1474,1717,1738,1739,65602,65603,2299,2298,2300,65593,65597,65601,65610,65604,305,306,294,295,296,288,289,290,292,293,299,472,303,378,98230,501,502,509,513,515,517,524,216,6621,25,6441,6571,6581,1918,824}) do
    assert(A.quests[id] and A.quests[id].title,'23NovemberAfternoon quest/title missing:'..id)
    questID=id
    for event,field in pairs({QUEST_DETAIL='detail',QUEST_PROGRESS='progress',QUEST_COMPLETE='complete'}) do
      fire(event);flush()
      assert(A.window:IsShown()==(A.quests[id][field]~=nil),'Afternoon state routing failed:'..id..'/'..field)
      assert(MMNorthshireCaptures[id].states[field].title==A.quests[id].en,'Afternoon capture lost ID/title')
    end
  end
  for _,h in ipairs({{1510,"complete"},{303,"detail"},{515,"detail"}}) do
    questID=h[1];fire(({detail='QUEST_DETAIL',progress='QUEST_PROGRESS',complete='QUEST_COMPLETE'})[h[2]]);flush()
    assert(not A.window:IsShown() and MMNorthshireCaptures[h[1]].states[h[2]].translationFallback~=nil,'Held field lost English fallback/capture')
  end
  assert(not A.quests[5639].detail and not A.quests[5728].detail and not A.quests[95250].detail,'Historical source holds refilled')
  assert(not A.quests[111].progress,'New UA-only reply enabled without current English')
  questID=0;fire('QUEST_FINISHED')
  print('PASS:23NovemberAfternoon50 records and150 dialogue routing/capture cases; original fallback for held states.')
end

if A.quests[1509] and A.quests[305] and A.quests[501] then
  local contracts={
    {1509,"objective",{"Gazrog","Crossroads"}},
    {1510,"objective",{"Ken'zigla","Malaka'jin"}},
    {1511,"objective",{"Ken'zigla's Draught","Grunt Logmar","Camp Taurajo"}},
    {1515,"objective",{"Ken'zigla's Draught","Dogran","Barrens"}},
    {1512,"objective",{"Dirt-caked Pendant","Gan'rul Bloodeye","Orgrimmar"}},
    {1513,"objective",{"Dogran's Pendant","Gan'rul Bloodeye"}},
    {1474,"objective",{"Pure Hearts","Carendin Halgar","Undercity"}},
    {1717,"objective",{"Gakin the Darkbinder","Stormwind"}},
    {1738,"objective",{"Heartswood","Ashenvale","Gakin the Darkbinder"}},
    {1739,"objective",{"Heartswood Core","Gakin the Darkbinder","Slaughtered Lamb"}},
    {65602,"objective",{"Wooden Figurine","Gakin the Darkbinder"}},
    {65603,"objective",{"Wooden Figurine","Gakin the Darkbinder","Slaughtered Lamb"}},
    {2299,"objective",{"Ironforge","Hulfdan Blackbeard"}},
    {2298,"objective",{"Stormwind","Renzik"}},
    {2300,"objective",{"Stormwind","Renzik"}},
    {65593,"objective",{"Avelina Lilly","Isaac Pearson","Carendin Halgar","Temple of the Damned"}},
    {65597,"objective",{"Lovers' Hearts","Carendin Halgar","Undercity"}},
    {65601,"objective",{"Magar","Orgrimmar"}},
    {65610,"objective",{"Fallen Sky Lake","Ashenvale","Gan'rul Bloodeye"}},
    {65604,"objective",{"Withered Scarf","Gan'rul Bloodeye","Orgrimmar"}},
    {305,"objective",{"Tarrel Rockweaver","Merrin Rockweaver"}},
    {306,"objective",{"Tarrel Rockweaver","Merrin"}},
    {294,"objective",{"Ormer Ironbraid","Mottled Screechers","Mottled Raptors"}},
    {295,"objective",{"Ormer Ironbraid","Mottled Scytheclaw","Mottled Razormaw"}},
    {296,"objective",{"Ormer Ironbraid","Sarltooth"}},
    {288,"objective",{"First Mate Fitzsimmons","Flagon of Mead"}},
    {289,"objective",{"Cursed Sailors","Cursed Marines","First Mate Snellig","Snellig's Snuffbox"}},
    {290,"objective",{"Captain Halyndor","Intrepid Strongbox Key","Intrepid's Locked Strongbox"}},
    {292,"objective",{"Cursed Eye of Paleth","Glorin Steelbrow"}},
    {293,"objective",{"Archbishop Benedictus","Cursed Eye of Paleth","Cathedral of Light"}},
    {299,"objective",{"Prospector Whelgar","Ados","Modr","Golm","Neru"}},
    {472,"objective",{"Longbraid","Dun Modr"}},
    {303,"complete",{"King Magni"}},
    {378,"objective",{"Motley Garmason","Kam Deepfury","Dun Modr"}},
    {98230,"objective",{"Howin Kindfeather","Menethil Harbor"}},
    {501,"objective",{"Mountain Lion Blood","Apothecary Lydon","Tarren Mill"}},
    {502,"objective",{"Elixir of Pain","Stanley"}},
    {509,"objective",{"Mudsnout Blossoms","Apothecary Lydon","Tarren Mill"}},
    {513,"objective",{"Mudsnout Composite","Master Apothecary Faranell","Undercity"}},
    {515,"progress",{"Umpi","Undercity"}},
    {517,"objective",{"Shindigger Stout","Apothecary Lydon"}},
    {524,"objective",{"Tainted Keg"}},
    {216,"detail",{"Thistlefur"}},
    {6621,"objective",{"Karang's Banner","Foulweald Totem Mound","Chief Murgut","Murgut's Totem","Karang Amakkar"}},
    {25,"objective",{"Befouled Water Elementals","Mystral Lake","Talondeep Path","Splintertree Post","Mastok Wrilehiss"}},
    {6441,"objective",{"Satyr Horns","Pixel"}},
    {6571,"objective",{"Warsong Saw Blades","Logging Rope","Warsong Oil","Warsong Axe Shipment","Locke Okarr"}},
    {6581,"progress",{"Ratchet","deadly blunderbuss"}},
    {1918,"objective",{"Befouled Water Globe","Mastok Wrilehiss"}},
    {824,"objective",{"Befouled Water Globe","Je'neu Sancrea"}}}
  for _,c in ipairs(contracts) do
    local value=assert(A.quests[c[1]][c[2]],'Missing current-source task identity field'):lower()
    for _,term in ipairs(c[3]) do assert(value:find(term:lower(),1,true),'Source target/recipient/item identity failed:'..c[1]..'/'..term) end
  end
  for _,r in ipairs({{1509,"progress"},{1510,"progress"},{1717,"progress"},{2299,"progress"},{2298,"progress"},{2300,"progress"},{65601,"progress"},{305,"progress"},{472,"progress"},{98230,"progress"},{6581,"detail"},{6581,"objective"}}) do assert(not A.quests[r[1]][r[2]],'Invented missing current source state:'..r[1]..'/'..r[2]) end
  for _,h in ipairs({{1510,"complete"},{303,"objective"},{303,"detail"},{515,"detail"},{515,"objective"},{216,"objective"}}) do assert(not A.quests[h[1]][h[2]],'Source-conflicting field refilled:'..h[1]..'/'..h[2]) end
  local bindings={1513,1474,1739,65603,65597,65604}
  for i=1,#bindings do
    assert(A.quests[bindings[i]].en=='The Binding','Summoning identity/title changed')
    for j=i+1,#bindings do assert(A.quests[bindings[i]].objective~=A.quests[bindings[j]].objective,'Different summons/items/recipients collapsed') end
  end
  assert(A.quests[2298].objective==A.quests[2300].objective and A.quests[2298].detail~=A.quests[2300].detail,'Legitimate shared Renzik objective or different referral context lost')
  assert(A.quests[305].en==A.quests[306].en and A.quests[305].objective~=A.quests[306].objective,'Excavation travel/return steps collapsed')
  for _,pair in ipairs({{294,295},{295,296},{501,502},{509,513},{517,524},{1918,824}}) do
    assert(A.quests[pair[1]].objective~=A.quests[pair[2]].objective,'Different target/material/task/handoff collapsed')
  end
  assert(A.quests[6581].title and A.quests[6581].progress and A.quests[6581].complete and not A.quests[6581].detail and not A.quests[6581].objective,'SawBlade source boundaries invented')
  questID=0;titleOverride=nil;fire('QUEST_FINISHED')
  print('PASS:50 current-source identity contracts, distinct binding/referral/route steps, missing states and source holds.')
end

if A.quests[579] and A.quests[1149] and A.quests[1022] then
  debugCommand('off');titleOverride=nil
  for _,id in ipairs({579,960,961,79362,79363,96137,96138,6681,96779,78261,78307,78270,1149,1150,1151,1152,1154,6627,1159,1160,6628,1394,4542,4841,5064,4821,4865,5062,5088,4767,1022,1037,1038,1039,1040,1041,1042,1043,1044,4581,464,98221,465,474,98223,98246,98291,98293,98297,98209}) do
    assert(A.quests[id] and A.quests[id].title,'24NovemberMorning quest/title missing:'..id)
    questID=id
    for event,field in pairs({QUEST_DETAIL='detail',QUEST_PROGRESS='progress',QUEST_COMPLETE='complete'}) do
      fire(event);flush()
      assert(A.window:IsShown()==(A.quests[id][field]~=nil),'Morning state routing failed:'..id..'/'..field)
      assert(MMNorthshireCaptures[id].states[field].title==A.quests[id].en,'Morning capture lost ID/title')
    end
  end
  for _,h in ipairs({{78307,"detail"},{78270,"detail"}}) do
    questID=h[1];fire(({detail='QUEST_DETAIL',progress='QUEST_PROGRESS',complete='QUEST_COMPLETE'})[h[2]]);flush()
    assert(not A.window:IsShown() and MMNorthshireCaptures[h[1]].states[h[2]].translationFallback~=nil,'Held field lost original fallback/capture')
  end
  assert(not A.quests[5639].detail and not A.quests[5728].detail and not A.quests[95250].detail,'Historical source holds refilled')
  assert(not A.quests[111].progress,'Inherited UA-only reply enabled without English')
  questID=0;fire('QUEST_FINISHED')
  print('PASS:24NovemberMorning50 records and150 dialogue routing/capture cases; original fallback for held fields.')
end

if A.quests[579] and A.quests[1149] and A.quests[1022] then
  local contracts={
    {579,"progress",{"King Anduin"}},
    {960,"complete",{"Twilight's Hammer","phial of scrying"}},
    {961,"complete",{"Twilight's Hammer","phial of scrying"}},
    {79362,"objective",{"Grant's Mace","Raven Hill Cemetery","Sirra Von'Indi"}},
    {79363,"complete",{"Silvia Valor"}},
    {96137,"objective",{"Young Black Ravagers","Black Ravagers","Sirra Von'Indi"}},
    {96138,"objective",{"Splinter Fist Warriors","Splinter Fist Taskmasters","Sirra Von'Indi"}},
    {6681,"objective",{"Seal of Ravenholdt","Fahrad","Ravenholdt Manor"}},
    {96779,"objective",{"Lord Tomas","Durnholde Keep","Myrokos Silentform"}},
    {78261,"objective",{"The Horn of Xelthos","Shadowfang Keep","Pyrewood Village"}},
    {78307,"complete",{"<name>","C"}},
    {78270,"progress",{"Shadowfang","Venture Co."}},
    {1149,"objective",{"Thousand Needles"}},
    {1150,"objective",{"Grenka's Claw","Dorn Plainstalker"}},
    {1151,"objective",{"Fragments of Rok'Alim","Dorn Plainstalker"}},
    {1152,"objective",{"Braug Dimspirit","Talondeep Path","Stonetalon Mountains"}},
    {1154,"objective",{"Legacy of the Aspects","Braug Dimspirit"}},
    {6627,"objective",{"Braug Dimspirit","Stonetalon Mountains"}},
    {1159,"objective",{"Parqual Fintallas","Undercity"}},
    {1160,"objective",{"The Beginnings of the Undead Threat","Parqual Fintallas","Undercity"}},
    {6628,"objective",{"Parqual Fintallas","Undercity"}},
    {1394,"objective",{"Dorn Plainstalker","Thousand Needles"}},
    {4542,"objective",{"Urgent Message","Cliffwatcher Longhorn","Freewind Post"}},
    {4841,"objective",{"Galak Scouts","Galak Wranglers","Galak Windchasers","Cliffwatcher Longhorn"}},
    {5064,"objective",{"Secret Notes","Darkcloud Pinnacle"}},
    {4821,"objective",{"Alien Egg","Hagar Lightninghoof","Freewind Post"}},
    {4865,"objective",{"Motega Firemane"}},
    {5062,"objective",{"Incendia Agave","Magatha Grimtotem","Elder Rise"}},
    {5088,"objective",{"Arikara","Incendia Powder","Motega Firemane","Whitereach Post"}},
    {4767,"objective",{"Highperch Wyvern Eggs","Elu","Freewind Post"}},
    {1022,"detail",{"Felwood","Howling Vale","Tome of Mel'Thandris"}},
    {1037,"objective",{"Thyn'tel Bladeweaver","Warrior's Terrace","Darnassus"}},
    {1038,"objective",{"Velinde","Thyn'tel Bladeweaver","Darnassus"}},
    {1039,"objective",{"Wharfmaster Dizzywig","Ratchet"}},
    {1040,"objective",{"Booty Bay","Caravaneer Ruzzgot"}},
    {1041,"objective",{"Clerk Daltry","Darkshire"}},
    {1042,"objective",{"Jonathan Carevin","Darkshire"}},
    {1043,"objective",{"Scythe of Elune","Jonathan Carevin","Darkshire"}},
    {1044,"objective",{"Thyn'tel Bladeweaver","Darnassus"}},
    {4581,"objective",{"Shindrell's Note","Kayneth Stillwind","Forest Song"}},
    {464,"objective",{"Dragonmaw War Banners","Captain Stoutfist"}},
    {98221,"objective",{"Captain Stoutfist","Attack Plans","Angerfang Encampment"}},
    {465,"objective",{"Dragonmaw"}},
    {474,"objective",{"Chieftain Nek'rosh","Nek'rosh's Head","Captain Stoutfist"}},
    {98223,"objective",{"Tattered Spellbook","Captain Stoutfist","Menethil Harbor"}},
    {98246,"objective",{"Perfect Razormaw Eggs","Howin Kindfeather"}},
    {98291,"objective",{"Dragonmaw Reclaimers","Dragonmaw Soulbinders","Dragonmaw Infiltrators","Howin Kindfeather"}},
    {98293,"objective",{"Dragonmaw Armaments","Dragonmaw Retreat","Captain Stoutfist","Menethil Keep"}},
    {98297,"objective",{"Subdued Dragonspawn","Dragonmaw Gates","Howin Kindfeather"}},
    {98209,"objective",{"Nord'el","Thundris Windweaver","Auberdine","Darkshore","Menethil Harbor"}}}
  for _,c in ipairs(contracts) do
    local value=assert(A.quests[c[1]][c[2]],'Missing source task identity field'):lower()
    for _,term in ipairs(c[3]) do assert(value:find(term:lower(),1,true),'Source item/recipient/place identity failed:'..c[1]..'/'..term) end
  end
  for _,r in ipairs({{579,"objective"},{579,"detail"},{960,"objective"},{960,"progress"},{960,"detail"},{961,"objective"},{961,"progress"},{961,"detail"},{96779,"progress"},{78307,"progress"},{1152,"progress"},{1159,"progress"},{1394,"progress"},{4865,"progress"},{1037,"progress"},{1039,"progress"},{1040,"progress"},{1041,"progress"},{1042,"progress"},{1044,"progress"}}) do assert(not A.quests[r[1]][r[2]],'Invented missing current source state:'..r[1]..'/'..r[2]) end
  for _,h in ipairs({{79363,"objective"},{78307,"detail"},{78307,"objective"},{78270,"detail"},{78270,"objective"},{1022,"objective"}}) do assert(not A.quests[h[1]][h[2]],'Source-conflicting or placeholder field enabled:'..h[1]..'/'..h[2]) end
  for _,id in ipairs({960,961}) do
    assert(A.quests[id].title and A.quests[id].complete and not A.quests[id].detail and not A.quests[id].objective and not A.quests[id].progress,'Onu helper source boundaries invented')
  end
  assert(A.quests[960].en==A.quests[961].en and A.quests[960].complete~=A.quests[961].complete,'Different meditation/replacement helper states collapsed')
  assert(A.quests[579].title and A.quests[579].progress and A.quests[579].complete and not A.quests[579].detail and not A.quests[579].objective,'Library helper source boundaries invented')
  assert(A.quests[78261].en==A.quests[78307].en and A.quests[78261].objective and not A.quests[78307].objective and not A.quests[78307].detail,'Horn job/reward or placeholder fields confused')
  assert(not A.quests[78270].objective and not A.quests[78270].detail and A.quests[78270].progress,'Copied Horn instructions enabled for WorkOrder quest')
  local lore={1152,1154,6627,1159,1160,6628}
  for i=1,#lore do
    assert(A.quests[lore[i]].en=='Test of Lore','Lore same-title ID missing')
    for j=i+1,#lore do assert(A.quests[lore[i]].objective~=A.quests[lore[j]].objective,'Different Lore travel/book/question stages collapsed') end
  end
  for _,pair in ipairs({{1149,1150},{1150,1151},{4542,4841},{4841,5064},{4821,4865},{4865,5062},{5062,5088},{1037,1038},{1039,1040},{1040,1041},{1041,1042},{1042,1043},{1043,1044},{464,98221},{465,474},{474,98223},{98246,98291},{98291,98293},{98293,98297}}) do
    assert(A.quests[pair[1]].objective~=A.quests[pair[2]].objective,'Different target/task/handoff stages collapsed')
  end
  questID=0;titleOverride=nil;fire('QUEST_FINISHED')
  print('PASS:50 current-source identity contracts, six distinct Lore stages, helper/reward boundaries and source holds.')
end

if A.quests[1472] and A.quests[2923] and A.quests[96241] then
  debugCommand('off');titleOverride=nil
  for _,id in ipairs({1472,1476,1507,1508,1716,78088,78089,78090,78091,78092,78093,2923,2922,2927,2926,2962,2925,2924,2931,2930,2928,2929,2842,2843,2841,2904,386,377,387,388,96241,96259,96260,96261,96294,4770,4881,4904,4966,5147,5151,98155,98156,567,1153,6504,6921,6922,98059,98071}) do
    assert(A.quests[id] and A.quests[id].title,'24NovemberAfternoon quest/title missing:'..id)
    questID=id
    for event,field in pairs({QUEST_DETAIL='detail',QUEST_PROGRESS='progress',QUEST_COMPLETE='complete'}) do
      fire(event);flush()
      assert(A.window:IsShown()==(A.quests[id][field]~=nil),'Afternoon state routing failed:'..id..'/'..field)
      assert(MMNorthshireCaptures[id].states[field].title==A.quests[id].en,'Afternoon capture lost quest ID/title')
    end
  end
  for _,repair in ipairs({{1681,'detail'},{1681,'complete'},{1779,'detail'},{1783,'detail'},{1784,'detail'},{1784,'objective'}}) do
    local id,field=repair[1],repair[2]
    assert(A.quests[id][field]:lower():find('dark iron dwarves',1,true),'Repaired existing field lost source identity')
    questID=id;fire(field=='complete' and 'QUEST_COMPLETE' or 'QUEST_DETAIL');flush()
    assert(A.window:IsShown(),'Repaired existing state no longer renders:'..id..'/'..field)
  end
  assert(not A.quests[1783].complete,'Inherited brother/sister source conflict was enabled')
  for _,h in ipairs({{2927,"detail"}}) do
    questID=h[1];fire(({detail='QUEST_DETAIL',progress='QUEST_PROGRESS',complete='QUEST_COMPLETE'})[h[2]]);flush()
    assert(not A.window:IsShown() and MMNorthshireCaptures[h[1]].states[h[2]].translationFallback~=nil,'Held field lost original fallback/capture')
  end
  assert(not A.quests[2927].detail,'Unsupported sir-maam gender branch enabled')
  assert(not A.quests[5639].detail and not A.quests[5728].detail and not A.quests[95250].detail and not A.quests[111].progress,'Historical source holds refilled')
  questID=0;fire('QUEST_FINISHED')
  print('PASS:24NovemberAfternoon50 records and150 new dialogue cases plus six guarded repair cases; held branches keep native fallback.')
end

if A.quests[1472] and A.quests[2923] and A.quests[96241] then
  local contracts={
    {1472,"objective",{"Godrick Farsan","Temple of the Damned"}},
    {1476,"objective",{"Dalin Forgewright","Corma Villard","Carendin Halgar"}},
    {1507,"objective",{"Cazul","Cleft of Shadow"}},
    {1508,"objective",{"Zankaja","Orgrimmar"}},
    {1716,"objective",{"Takar the Seer","Barrens"}},
    {78088,"objective",{"Althalaxx Orb","Delgren the Purifier","Maestra's Post"}},
    {78089,"objective",{"Althalaxx Orb","Katherine the Pure","Stormwind"}},
    {78090,"objective",{"Stormwind"}},
    {78091,"objective",{"Summoner's Salt","Blackrock Summoners","Ursula Deline"}},
    {78092,"objective",{"Motes of Mannoroth","Orb of Althalaxx","Spear of Mannoroth","Demon Fall Canyon"}},
    {78093,"objective",{"Orb Shards","Delgren"}},
    {2923,"objective",{"Tinkmaster Overspark","Ironforge"}},
    {2922,"objective",{"Techbot's Memory Core","Tinkmaster Overspark"}},
    {2927,"objective",{"Ozzie Togglevolt","Kharanos"}},
    {2926,"objective",{"Empty Leaden Collection Phial","Irradiated Invaders","Irradiated Pillagers","Ozzie Togglevolt"}},
    {2962,"objective",{"High Potency Radioactive Fallout","Heavy Leaden Collection Phial"}},
    {2925,"objective",{"Klockmort Spannerspan","Ironforge"}},
    {2924,"objective",{"Essential Artificials","Klockmort Spannerspan"}},
    {2931,"objective",{"Master Mechanic Castpipe","Ironforge"}},
    {2930,"objective",{"Prismatic Punch Card","Master Mechanic Castpipe"}},
    {2928,"objective",{"Robo-mechanical Guts","Shoni","Stormwind"}},
    {2929,"objective",{"Mekgineer Thermaplugg","High Tinker Mekkatorque"}},
    {2842,"objective",{"Scooty","Booty Bay"}},
    {2843,"objective",{"Scooty","Goblin Transponder"}},
    {2841,"objective",{"Rig Blueprints","Thermaplugg's Safe Combination","Nogg"}},
    {2904,"objective",{"Kernobee","Clockwerk Run","Scooty","Booty Bay"}},
    {386,"objective",{"Targorr the Dread","Guard Berton","Lakeshire"}},
    {377,"objective",{"Councilman Millstipe","Dextren Ward"}},
    {387,"objective",{"Warden Thelwater","Defias Prisoners","Defias Convicts","Defias Insurgents"}},
    {388,"objective",{"Nikova Raskol","Red Wool Bandanas"}},
    {96241,"objective",{"Toxin Extractor","Gloomrise Toxin Samples","Gnawed Corpses"}},
    {96259,"objective",{"Gloomrise Hatchlings","Gloomrise Soldiers"}},
    {96260,"objective",{"Crystalline Silk","Gloomrise Spinners"}},
    {96261,"objective",{"Broodmother Valraxx","Gloomrise"}},
    {96294,"objective",{"Broodmother Valraxx","Muln Earthfury","Skywatcher Plateau"}},
    {4770,"objective",{"Pao'ka Swiftmountain","Highperch","Motega Firemane","Whitereach Post"}},
    {4881,"objective",{"Kanati Greycloud","Whitereach Post"}},
    {4966,"objective",{"Kanati Greycloud"}},
    {4904,"objective",{"Lakota Windsong","Darkcloud Pinnacle","Thalia Amberhide","Freewind Post"}},
    {5147,"objective",{"Arnak Grimtotem","Cliffwatcher Longhorn","Freewind Post"}},
    {5151,"objective",{"Hypercapacitor Gizmo","Panther Cage Key","Wizlo Bearingshiner"}},
    {98155,"objective",{"Pristine Pesterhide Pelts","Kristy Grant"}},
    {98156,"objective",{"Package of Pristine Pelts","Kimberly Grant"}},
    {567,"objective",{"High Executor Darthalia","Tarren Mill","Clerk Horrace Whitesteed","Citizen Wilkes","Miner Hackett","Farmer Kalaba"}},
    {98059,"objective",{"Sealed Company Request","Hillsbrad"}},
    {98071,"objective",{"Fallrook Varietal","Dun Garok","Hillsbrad Foothills","Homebrew Hops"}},
    {6504,"objective",{"Shredder Operating Manual","Gurda Ragescar","Splintertree Post"}},
    {6921,"objective",{"Fathom Core","Je'neu Sancrea","Zoram'gar Outpost"}},
    {6922,"objective",{"Strange Water Globe","Je'neu Sancrea","Zoram'gar Outpost"}},
    {1153,"objective",{"Unrefined Ore Sample","Gravelsnout Digger","Surveyor","Tatternack Steelforge","Camp Taurajo"}}}
  for _,c in ipairs(contracts) do
    local value=assert(A.quests[c[1]][c[2]],'Missing source task identity field'):lower()
    for _,term in ipairs(c[3]) do assert(value:find(term:lower(),1,true),'Current source identity failed:'..c[1]..'/'..term) end
  end
  for _,r in ipairs({{1472,"progress"},{1507,"progress"},{1508,"progress"},{1716,"progress"},{2923,"progress"},{2927,"progress"},{2925,"progress"},{2931,"progress"},{2842,"progress"},{4770,"progress"},{4881,"progress"},{4966,"progress"},{4904,"progress"},{98156,"progress"},{98059,"progress"}}) do assert(not A.quests[r[1]][r[2]],'Invented missing current source state:'..r[1]..'/'..r[2]) end
  for _,h in ipairs({{2927,"detail"}}) do assert(not A.quests[h[1]][h[2]],'Unsupported field enabled:'..h[1]..'/'..h[2]) end
  for _,pair in ipairs({{1472,1507},{1507,1716},{1507,1508},{78088,78089},{78089,78090},{78090,78091},{78091,78092},{78092,78093},{2923,2922},{2927,2926},{2926,2962},{2925,2924},{2931,2930},{2842,2843},{4881,4966},{98155,98156},{96259,96261},{96261,96294}}) do
    assert(A.quests[pair[1]].objective~=A.quests[pair[2]].objective,'Different handoff/task stages collapsed')
  end
  assert(A.quests[1472].en==A.quests[1507].en and A.quests[1507].en==A.quests[1716].en,'Same-title Warlock identities changed')
  questID=0;titleOverride=nil;fire('QUEST_FINISHED')
  print('PASS:50 current-source objective contracts, distinct Warlock and dungeon stages, unavailable states and gender hold.')
end

if A.quests[79192] and A.quests[98815] and A.quests[98219] then
  debugCommand('off');titleOverride=nil
  for _,id in ipairs({79192,79980,79974,79975,79976,98027,98417,98418,1011,1012,1084,5881,857,98815,95646,95647,95737,95772,95795,95809,95810,98824,98216,98310,98313,95663,95682,95664,98823,95697,335,336,397,536,559,560,561,562,563,98219,637,683,686,689,700,1142,1144,1221,78916,78917}) do
    assert(A.quests[id] and A.quests[id].title,'25NovemberMorning quest/title missing:'..id)
    questID=id
    for event,field in pairs({QUEST_DETAIL='detail',QUEST_PROGRESS='progress',QUEST_COMPLETE='complete'}) do
      fire(event);flush()
      assert(A.window:IsShown()==(A.quests[id][field]~=nil),'Morning state routing failed:'..id..'/'..field)
      assert(MMNorthshireCaptures[id].states[field].title==A.quests[id].en,'Morning capture lost quest ID/title')
    end
  end
  for _,h in ipairs({}) do
    questID=h[1];fire(({detail='QUEST_DETAIL',progress='QUEST_PROGRESS',complete='QUEST_COMPLETE'})[h[2]]);flush()
    assert(not A.window:IsShown() and MMNorthshireCaptures[h[1]].states[h[2]].translationFallback~=nil,'Held field lost original fallback/capture')
  end
  assert(not A.quests[5639].detail and not A.quests[5728].detail and not A.quests[95250].detail and not A.quests[111].progress,'Historical source holds refilled')
  questID=0;fire('QUEST_FINISHED')
  print('PASS:25NovemberMorning50 records and150 new dialogue cases ; held branches keep native fallback.')
end

if A.quests[79192] and A.quests[98815] and A.quests[98219] then
  local contracts={
    {79192,"detail",{"Mission","New Plague","The Barrens","Desolace"}},
    {79975,"detail",{"Eagle and Fist","Old Kingdoms"}},
    {98027,"objective",{"Crescent Necklace","Maliynn","Astranaar"}},
    {98417,"objective",{"Maseara Autumnmoon","Forest Song","Satyrnaar","Kurothel"}},
    {98418,"objective",{"Xavian Rogues","Felsworn","Betrayers","Hellcallers","Maseara Autumnmoon","Forest Song"}},
    {1011,"objective",{"Bottle of Disease","Kayneth Stillwind","Forest Song"}},
    {1012,"objective",{"Taneel Darkwood","Uthil Mooncall","Mavoris Cloudsbreak","Kayneth Stillwind","Forest Song"}},
    {1084,"objective",{"Corroded Shrapnel","Kaela Shadowspear","Stonetalon"}},
    {5881,"objective",{"Maggran","Grish Longrunner","Great Lift","Barrens"}},
    {857,"objective",{"Feegly the Exiled","Tear of the Moons"}},
    {98815,"objective",{"Thicket Raptor Hides","James Halloran","Menethil Harbor"}},
    {95646,"objective",{"Excavation Sites","Highland Horror","Rethiel the Greenwarden","Wetlands"}},
    {95647,"objective",{"Excavation Sites","Ardin Grassman"}},
    {95737,"objective",{"Caitlin Grassman","Menethil Harbor"}},
    {95772,"objective",{"Whelgar's Excavation Site","Dorin Songblade","Daewyn"}},
    {95795,"objective",{"Dorin Songblade"}},
    {95809,"objective",{"Caitlin Grassman","Menethil Harbor"}},
    {95810,"objective",{"Titan Relic","Prospector Whelgar","Wetlands"}},
    {98824,"objective",{"Titan Relic","High Explorer Magellas","Hall of Explorers","Ironforge"}},
    {98216,"objective",{"Goaz Stone","Goaz Warder","Titanic Keystone","Prospector Whelgar"}},
    {98310,"objective",{"Goaz Stone","Ados","Modr","Golm","Neru","Prospector Whelgar"}},
    {98313,"objective",{"Whelgar Relic Package","Historian Karnik","Ironforge"}},
    {95663,"objective",{"Wetlands","Dragonmaw","Deathstalker Agent"}},
    {95682,"objective",{"Excavation Site","Dragonmaw","Deathstalker Agent"}},
    {95664,"objective",{"Titan Relic","Elder Rise","Thunder Bluff"}},
    {98823,"objective",{"Titan Relic","Muln Earthfury","Skywatcher Plateau","Mulgore"}},
    {95697,"objective",{"Wetlands","Excavation Sites","Thicket Raptor Meat"}},
    {335,"objective",{"Zardeth the Black Claw","Darkshire","Tear of Tilloa","Wetlands","Musquash Root"}},
    {336,"objective",{"Black Claw Stout","Lord Wishock","Hall of Petitioners"}},
    {397,"objective",{"Zggi","Zardeth the Blackclaw"}},
    {536,"objective",{"Torn Fin Tidehunters","Torn Fin Oracles","Lieutenant Farren Orinelle","Southshore"}},
    {559,"objective",{"Murloc Heads","Western Strand","Lieutenant Farren Orinelle","Southshore"}},
    {560,"objective",{"sack of murloc heads","Marshall Redpath","Southshore"}},
    {561,"objective",{"Lieutenant Farren Orinelle","Southshore"}},
    {562,"objective",{"Daggerspine Shorehunters","Daggerspine Sirens","Lieutenant Farren Orinelle","Southshore"}},
    {563,"objective",{"Farren's report","Major Samuelson","Stormwind Keep"}},
    {637,"objective",{"Sully Balloo's Letter","Sara Balloo"}},
    {683,"objective",{"Sara Balloo","King Magni Bronzebeard","Ironforge"}},
    {686,"objective",{"King Magni Bronzebeard","Grand Mason Marblesten"}},
    {689,"objective",{"Grand Mason Marblesten","Ironforge","Alterac Granite"}},
    {700,"objective",{"King Magni Bronzebeard"}},
    {1142,"objective",{"Treshala's Pendant","Treshala Fallowbrook","Darnassus"}},
    {1144,"objective",{"Willix the Importer","Razorfen Kraul"}},
    {1221,"objective",{"Crate with Holes","Snufflenose Command Stick","Snufflenose Owner's Manual","Razorfen Kraul","Snufflenose Gopher","Command Stick","Blueleaf Tubers","Mebok Mizzyrix","Ratchet"}},
    {78916,"objective",{"Blackfathom Pearl","Dawnwatcher Selgorm","Darnassus"}},
    {78917,"objective",{"Blackfathom Pearl","Bashana Runetotem","Thunder Bluff"}},
    {98219,"objective",{"Lieutenant Farren Orinelle","Southshore","Hillsbrad Foothills"}},
    {1011,"detail",{"bottle of disease"}},
    {1011,"progress",{"bottle of disease"}}}
  for _,c in ipairs(contracts) do
    local value=assert(A.quests[c[1]][c[2]],'Missing source task identity field'):lower()
    for _,term in ipairs(c[3]) do assert(value:find(term:lower(),1,true),'Current source identity failed:'..c[1]..'/'..term) end
  end
  for _,c in ipairs({{79980,"detail"},{79974,"detail"},{79976,"detail"}}) do
    questID=c[1];fire('QUEST_DETAIL');flush()
    assert(A.window:IsShown() and shown.text:find(A.quests[c[1]][c[2]],1,true),'Clue encoded field did not render for exact quest ID')
  end
  for _,r in ipairs({{79192,"progress"},{79980,"progress"},{79974,"progress"},{79975,"progress"},{79976,"progress"},{98027,"progress"},{95647,"progress"},{95647,"complete"},{95737,"progress"},{95772,"progress"},{95772,"complete"},{95795,"progress"},{95663,"progress"},{397,"progress"},{98219,"progress"},{561,"progress"},{686,"progress"},{700,"progress"},{1144,"progress"}}) do assert(not A.quests[r[1]][r[2]],'Invented missing current source state:'..r[1]..'/'..r[2]) end
  for _,h in ipairs({}) do assert(not A.quests[h[1]][h[2]],'Unsupported field enabled:'..h[1]..'/'..h[2]) end
  for _,pair in ipairs({{79192,79980},{79980,79974},{79974,79975},{79975,79976},{98417,98418},{95646,95647},{95737,95772},{95795,95809},{95809,95810},{559,560},{560,561},{561,562},{562,563},{637,683},{683,686},{686,689},{689,700},{335,336},{336,397}}) do
    assert(A.quests[pair[1]].objective~=A.quests[pair[2]].objective,'Different handoff/task stages collapsed')
  end
  assert(A.quests[559].en==A.quests[560].en and A.quests[560].en==A.quests[561].en,'Same-title Farren stages changed')
  assert(A.quests[686].en==A.quests[689].en and A.quests[689].en==A.quests[700].en,'Same-title royal tribute stages changed')
  questID=0;titleOverride=nil;fire('QUEST_FINISHED')
  print('PASS:50 current-source quest contracts plus linked item safeguards, distinct treasure, Farren and royal tribute stages, unavailable states and recorded holds.')
end

if A.quests[1021] and A.quests[1274] and A.quests[1798] then
  debugCommand('off');titleOverride=nil
  for _,id in ipairs({1021,1031,1032,86757,98069,98070,1135,1145,1146,1147,3567,5421,1104,1105,1110,1175,1176,1179,1106,1178,98208,86776,87491,1274,1241,1242,1243,1244,1245,1246,1447,1247,1248,1249,1250,1264,1265,1266,1324,1267,1798,2996,3001,1758,1801,1802,1803,1804,1805,1795}) do
    assert(A.quests[id] and A.quests[id].title,'25NovemberAfternoon quest missing:'..id)
    questID=id
    for event,field in pairs({QUEST_DETAIL='detail',QUEST_PROGRESS='progress',QUEST_COMPLETE='complete'}) do
      fire(event);flush()
      assert(A.window:IsShown()==(A.quests[id][field]~=nil),'Afternoon state routing failed:'..id..'/'..field)
      assert(MMNorthshireCaptures[id].states[field].title==A.quests[id].en,'Afternoon capture lost exact quest title/ID')
    end
  end
  assert(not A.quests[5639].detail and not A.quests[5728].detail and not A.quests[95250].detail and not A.quests[111].progress,'Historical source holds refilled')
  questID=0;fire('QUEST_FINISHED')
  print('PASS:25NovemberAfternoon50 records and150 new dialogue routing/capture cases with inherited fallback guards.')
end

if A.quests[1021] and A.quests[1274] and A.quests[1798] then
  local contracts={    {1021,"objective",{"Anilia","Xavian"}},
    {1031,"objective",{"Geltharis","Branch of Cenarius","Illiyana","Shrine of Aessina"}},
    {1032,"objective",{"Satyr Horns","Illiyana","Shrine of Aessina"}},
    {86757,"objective",{"Jagged Orc Swords","Curved Orc Daggers","Shandrina"}},
    {98069,"objective",{"Stolen Freewind Supplies","Jandia","Freewind Post"}},
    {98070,"objective",{"Screeching Harpies","Screeching Roguefeather Harpies","Screeching Windcaller Harpies"}},
    {1135,"objective",{"Highperch Venom Sacs","Fiora Longears","Theramore"}},
    {1145,"objective",{"Korran's Sealed Note","Belgrom Rockmaul","Orgrimmar"}},
    {1146,"objective",{"Belgrom's Sealed Note","Moktar Krin","Thousand Needles"}},
    {1147,"objective",{"Silithid Searchers","Silithid Hive Drones","Silithid Invaders","Moktar Krin","Thousand Needles"}},
    {3567,"complete",{"twin colossals"}},
    {5421,"progress",{"Shadowprey Village","shellfish","Bloodbelly fish"}},
    {1104,"objective",{"Salty Scorpid Venoms","Fizzle Brassbolts","Shimmering Flats"}},
    {1105,"objective",{"Hardened Tortoise Shells","Wizzle Brassbolts","Shimmering Flats"}},
    {1110,"objective",{"Rocket Car Parts","Kravel Koalbeard","Shimmering Flats"}},
    {1175,"objective",{"Saltstone Basilisks","Saltstone Crystalhides","Saltstone Gazers","Trackmaster Zherin","Shimmering Flats"}},
    {1176,"objective",{"Hollow Vulture Bones","Pozzik","Shimmering Flats"}},
    {1179,"objective",{"crate of crash helmets","Wizzle Brassbolts","Shimmering Flats"}},
    {1106,"objective",{"Fizzle's Letter","Martek the Exiled","Badlands"}},
    {1178,"objective",{"Gazlowe","Ratchet"}},
    {98208,"objective",{"Nord'el","Sylessa Duskwhisper","Menethil Harbor"}},
    {86776,"objective",{"Bronze Bars","Morhan Coppertongue"}},
    {87491,"objective",{"captive fire elemental","Dun Modr"}},
    {1274,"objective",{"Bishop DeLavey","Stormwind Keep"}},
    {1241,"objective",{"Jorgen","Stormwind City"}},
    {1242,"objective",{"Jorgen","Sealed Note to Elling","Elling Trias","Stormwind City"}},
    {1243,"objective",{"Sealed Note to Watcher Backus","Watcher Backus","Duskwood"}},
    {1244,"objective",{"Defias Docket","Watcher Backus","Duskwood"}},
    {1245,"objective",{"Defias Docket","Elling Trias","Stormwind"}},
    {1246,"objective",{"Dashel Stonefist","Stormwind"}},
    {1447,"objective",{"Dashel Stonefist","Stormwind"}},
    {1247,"objective",{"Elling Trias","Stormwind"}},
    {1248,"objective",{"Mikhail","Wetlands"}},
    {1249,"objective",{"Tapoke Jahn","Mikhail","Menethil"}},
    {1250,"objective",{"Mikhail","Wetlands"}},
    {1264,"objective",{"Commander Samaul","Dustwallow Marsh"}},
    {1265,"objective",{"Sentry Point","Private Hendel"}},
    {1266,"objective",{"Private Hendel","Dustwallow Marsh"}},
    {1324,"objective",{"Private Hendel","Dustwallow Marsh"}},
    {1267,"objective",{"Jaina Proudmoore","Dustwallow Swamp"}},
    {1798,"objective",{"Barrens","Strahad Farsan"}},
    {2996,"objective",{"Ratchet","Strahad Farsan"}},
    {3001,"objective",{"Ratchet","Strahad Farsan"}},
    {1758,"objective",{"Ironforge","Krom Stoutarm"}},
    {1801,"objective",{"Undercity","Jorah Annison"}},
    {1802,"objective",{"Ironforge","Krom Stoutarm","Moldy Tome","Tattered Manuscript"}},
    {1803,"objective",{"Undercity","Jorah Annison","Moldy Tome","Tattered Manuscript"}},
    {1804,"objective",{"Reconstructed Tome","Rods of Channeling","Ratchet","Strahad Farsan"}},
    {1805,"objective",{"Reconstructed Tome","Rods of Channeling","Ratchet","Strahad Farsan"}},
    {1795,"objective",{"Tome of the Cabal","felhunter","Ratchet","Strahad Farsan"}}}
  for _,c in ipairs(contracts) do
    local value=assert(A.quests[c[1]][c[2]],'Source identity field absent'):lower()
    for _,term in ipairs(c[3]) do assert(value:find(term:lower(),1,true),'Source identity failed:'..c[1]..'/'..term) end
  end
  for _,c in ipairs({}) do
    questID=c[1];fire(({detail='QUEST_DETAIL',objective='QUEST_DETAIL',progress='QUEST_PROGRESS',complete='QUEST_COMPLETE'})[c[2]]);flush()
    assert(A.window:IsShown() and shown.text:find(A.quests[c[1]][c[2]],1,true),'Encoded source field did not render for exactID')
  end
  for _,r in ipairs({{1021,"progress"},{3567,"detail"},{3567,"objective"},{3567,"progress"},{5421,"detail"},{5421,"objective"},{1178,"progress"},{87491,"progress"},{1274,"progress"},{1246,"progress"},{1247,"progress"},{1248,"progress"},{1250,"progress"},{1264,"progress"},{1266,"progress"},{1267,"detail"},{1267,"progress"},{1798,"progress"},{2996,"progress"},{3001,"progress"},{1758,"progress"},{1801,"progress"}}) do assert(not A.quests[r[1]][r[2]],'Invented current source state:'..r[1]..'/'..r[2]) end
  for _,r in ipairs({{1274,"detail"}}) do
    assert(not A.quests[r[1]][r[2]],'Unsupported source field enabled:'..r[1]..'/'..r[2])
    local event=({detail='QUEST_DETAIL',progress='QUEST_PROGRESS',complete='QUEST_COMPLETE'})[r[2]]
    if event then
      questID=r[1];fire(event);flush()
      assert(not A.window:IsShown() and MMNorthshireCaptures[r[1]].states[r[2]].translationFallback~=nil,'Held state lost original fallback/capture')
    end
  end
  for _,p in ipairs({{1021,1031},{1031,1032},{1145,1146},{1146,1147},{1176,1178},{1274,1241},{1241,1242},{1242,1243},{1243,1244},{1244,1245},{1245,1246},{1246,1447},{1447,1247},{1247,1248},{1248,1249},{1249,1250},{1250,1264},{1264,1265},{1265,1266},{1266,1324},{1324,1267},{1798,1758},{1758,1802},{1802,1804},{1804,1795},{2996,1801},{1801,1803},{1803,1805},{1805,1795},{3001,1801}}) do assert(A.quests[p[1]].objective~=A.quests[p[2]].objective,'Distinct current-source task stages collapsed') end
  assert(A.quests[1241].en==A.quests[1242].en and A.quests[1242].en==A.quests[1243].en,'Diplomat same-title IDs changed')
  assert(A.quests[1758].en==A.quests[1801].en and A.quests[1804].en==A.quests[1805].en,'Tome faction step titles changed')
  questID=0;titleOverride=nil;fire('QUEST_FINISHED')
  print('PASS:50 source quest contracts,17 distinct Diplomat IDs,Tome faction stages,service/repeatable boundaries and unavailable-state guards.')
end

if A.quests[647] and A.quests[1431] and A.quests[1939] then
  debugCommand('off');titleOverride=nil
  for _,id in ipairs({505,631,632,633,634,647,87318,88756,88757,88758,544,545,547,552,553,555,556,557,7321,93680,1431,1432,1433,1434,1435,1436,1365,1366,1480,1481,1482,1484,1488,1437,1465,1438,1439,1440,97284,78132,78133,78134,1939,1938,1940,1942,1943,1944,1945,1946}) do
    assert(A.quests[id] and A.quests[id].title,'26NovemberMorning quest missing:'..id)
    questID=id
    for event,field in pairs({QUEST_DETAIL='detail',QUEST_PROGRESS='progress',QUEST_COMPLETE='complete'}) do
      fire(event);flush()
      assert(A.window:IsShown()==(A.quests[id][field]~=nil),'Afternoon state routing failed:'..id..'/'..field)
      assert(MMNorthshireCaptures[id].states[field].title==A.quests[id].en,'Afternoon capture lost exact quest title/ID')
    end
  end
  assert(not A.quests[5639].detail and not A.quests[5728].detail and not A.quests[95250].detail and not A.quests[111].progress,'Historical source holds refilled')
  questID=0;fire('QUEST_FINISHED')
  print('PASS:26NovemberMorning50 records and150 new dialogue routing/capture cases with inherited fallback guards.')
end

if A.quests[647] and A.quests[1431] and A.quests[1939] then
  local contracts={    {647,"objective",{"MacKreel's Moonshine","Brewmeister Bilger","Southshore"}},
    {631,"objective",{"Rhag Garmason","Ol' Rustlocke"}},
    {632,"objective",{"Rhag Garmason","Rustlocke"}},
    {633,"objective",{"cache of explosives"}},
    {634,"objective",{"Captain Nials","Refuge Pointe"}},
    {87318,"objective",{"Corma","Essene"}},
    {88757,"objective",{"Essene's Necklace","Essene's Spellbook","Essene's Waterskin"}},
    {88758,"objective",{"Essene's note","Corma Villard"}},
    {88756,"objective",{"Stolen Explosives","Dark Iron Dwarf"}},
    {505,"objective",{"Syndicate Footpads","Syndicate Thieves","Magistrate Henry Maleb","Southshore"}},
    {547,"objective",{"Deathguard Humbert","Dun Garok","Tarren Mill"}},
    {552,"objective",{"Helcular's Rod","Yeti","Novice Thaivand","Tarren Mill"}},
    {553,"objective",{"Rod of Helcular","Flame of Azel","Flame of Veraz","Flame of Uzel","Helcular's grave","Southshore"}},
    {555,"objective",{"Turtle Meat","Soothing Spices","Chef Jessen","Southshore"}},
    {7321,"objective",{"Turtle Meat","Soothing Spices","Christoph Jeffcoat","Tarren Mill"}},
    {556,"objective",{"Worn Stone Tokens","Keeper Bel'varil","Tarren Mill"}},
    {557,"objective",{"Bracers of Earth Binding","Keeper Bel'varil","Tarren Mill"}},
    {544,"detail",{"Tarren Mill","Forsaken","Undercity","Dark Lady","Sylvanas","Dalaran","Lordamere Internment Camp"}},
    {93680,"objective",{"Dalaran Sewer Key","Magus Wordeen Voidglare","Tarren Mill"}},
    {545,"objective",{"Dalaran Summoners","Elemental Slaves","Magus Voidglare","Tarren Mill"}},
    {1431,"objective",{"Keldran","Orgrimmar"}},
    {1432,"objective",{"Takata Steelblade","Desolace"}},
    {1433,"objective",{"Maurin Bonesplitter","Desolace"}},
    {1434,"objective",{"Hatefury Rogues","Hatefury Felsworn","Hatefury Betrayers","Hatefury Hellcallers","Takata Steelblade","Desolace"}},
    {1435,"detail",{"Burning Blade"}},
    {1436,"objective",{"Keldran","Orgrimmar"}},
    {1365,"objective",{"Khan Dez'hepah's Head","Felgur Twocuts","Desolace"}},
    {1366,"objective",{"Centaur Ears","Felgur Twocuts","Desolace"}},
    {1480,"objective",{"Flayed Demon Skin","Maurin Bonesplitter","Desolace"}},
    {1481,"objective",{"Shadowstalker Scalp","Maurin Bonesplitter","Desolace"}},
    {1482,"objective",{"Oracle Crystal","Maurin Bonesplitter","Desolace"}},
    {1484,"objective",{"Takata Steelblade","Desolace"}},
    {1488,"objective",{"Lord Azrethoc","Jugkar Grim'rod","Takata Steelblade","Desolace"}},
    {1437,"objective",{"Tyranis","Dalinda Malem","Desolace"}},
    {1465,"objective",{"Malem Pendant","Vahlarriel Demonslayer","Desolace"}},
    {1438,"objective",{"Dalinda Malem","Desolace"}},
    {1439,"objective",{"Tyranis Malem","Desolace"}},
    {1440,"objective",{"Dalinda Malem","Thunder Axe Fortress","Vahlarriel Demonslayer","Desolace"}},
    {97284,"objective",{"Burning Blade Orc","Thunder Axe Fortress","Vahlarriel Demonslayer","Nijel's Point"}},
    {78132,"title",{"Dragonslayer's Helm"}},
    {78133,"title",{"Dragonslayer's Shield"}},
    {78134,"title",{"Dragonslayer's Lance"}},
    {1939,"title",{"High Sorcerer Andromath"}},
    {1938,"title",{"Ur's Treatise on Shadow Magic"}},
    {1940,"title",{"Pristine Spider Silk"}},
    {1942,"title",{"Astral Knot"}},
    {1943,"title",{"Deino"}},
    {1944,"title",{"Xavian"}},
    {1945,"title",{"Laughing Sisters"}},
    {1946,"title",{"Nether-lace"}},
    {1939,"detail",{"Mage District"}}}
  for _,c in ipairs(contracts) do
    local value=assert(A.quests[c[1]][c[2]],'Source identity field absent'):lower()
    for _,term in ipairs(c[3]) do assert(value:find(term:lower(),1,true),'Source identity failed:'..c[1]..'/'..term) end
  end
  for _,c in ipairs({}) do
    questID=c[1];fire(({detail='QUEST_DETAIL',objective='QUEST_DETAIL',progress='QUEST_PROGRESS',complete='QUEST_COMPLETE'})[c[2]]);flush()
    assert(A.window:IsShown() and shown.text:find(A.quests[c[1]][c[2]],1,true),'Encoded source field did not render for exactID')
  end
  for _,r in ipairs({{631,"progress"},{634,"progress"},{87318,"progress"},{1431,"progress"},{1432,"progress"},{1433,"progress"},{1436,"progress"},{1484,"progress"},{1437,"progress"},{1465,"progress"},{1438,"progress"},{1440,"progress"},{97284,"progress"},{78132,"detail"},{78132,"objective"},{78133,"detail"},{78133,"objective"},{78134,"detail"},{78134,"objective"},{1939,"progress"},{1942,"detail"},{1942,"objective"},{1942,"progress"},{1943,"progress"},{1946,"detail"},{1946,"objective"},{1946,"progress"}}) do assert(not A.quests[r[1]][r[2]],'Invented current source state:'..r[1]..'/'..r[2]) end
  for _,r in ipairs({{1431,"complete"},{1435,"objective"}}) do
    assert(not A.quests[r[1]][r[2]],'Unsupported source field enabled:'..r[1]..'/'..r[2])
    local event=({detail='QUEST_DETAIL',progress='QUEST_PROGRESS',complete='QUEST_COMPLETE'})[r[2]]
    if event then
      questID=r[1];fire(event);flush()
      assert(not A.window:IsShown() and MMNorthshireCaptures[r[1]].states[r[2]].translationFallback~=nil,'Held state lost original fallback/capture')
    end
  end
  for _,p in ipairs({{631,632},{632,633},{633,634},{87318,88757},{88757,88758},{552,553},{556,557},{544,93680},{93680,545},{1431,1432},{1432,1433},{1433,1435},{1435,1436},{1480,1481},{1481,1482},{1482,1484},{1484,1488},{1365,1366},{1437,1465},{1465,1438},{1438,1439},{1439,1440},{1465,97284},{1939,1938},{1938,1940},{1943,1944},{1944,1945}}) do assert(A.quests[p[1]].objective~=A.quests[p[2]].objective,'Distinct current-source task stages collapsed') end
  assert(A.quests[631].en==A.quests[632].en and A.quests[632].en==A.quests[633].en,'Thandol same-title IDs changed')
  assert(A.quests[1480].en==A.quests[1481].en and A.quests[1482].en==A.quests[1484].en,'Corrupter same-title IDs changed')
  questID=0;titleOverride=nil;fire('QUEST_FINISHED')
  print('PASS:50 source quest contracts,Thandol/Corrupter/Mage stages,Alonso partial-state boundaries and unavailable-state guards.')
end

if A.quests[96781] and A.quests[583] and A.quests[1453] then
  debugCommand('off');titleOverride=nil
  for _,id in ipairs({1947,1948,1949,1950,96781,96782,96783,96784,96785,96786,1712,1713,1714,1718,1719,1791,1792,1951,1952,1953,185,186,187,188,190,191,192,193,583,5762,194,195,196,197,208,338,339,340,341,342,1387,1453,1454,1455,1456,1457,1458,1459,1466,1467}) do
    assert(A.quests[id] and A.quests[id].title,'26NovemberAfternoon quest missing:'..id)
    questID=id
    for event,field in pairs({QUEST_DETAIL='detail',QUEST_PROGRESS='progress',QUEST_COMPLETE='complete'}) do
      fire(event);flush()
      assert(A.window:IsShown()==(A.quests[id][field]~=nil),'Afternoon state routing failed:'..id..'/'..field)
      assert(MMNorthshireCaptures[id].states[field].title==A.quests[id].en,'Afternoon capture lost exact quest title/ID')
    end
  end
  assert(not A.quests[5639].detail and not A.quests[5728].detail and not A.quests[95250].detail and not A.quests[111].progress,'Historical source holds refilled')
  questID=0;fire('QUEST_FINISHED')
  print('PASS:26NovemberAfternoon50 records and150 new dialogue routing/capture cases with inherited fallback guards.')
end

if A.quests[96781] and A.quests[583] and A.quests[1453] then
  local contracts={    {96781,"objective",{"Barton's Scouting Report","Myrokos Silentform","Ravenholdt Manor"}},
    {96782,"detail",{"Barton","Alterac","Perenolde","Blade of House Perenolde","Royal Aegis of Perenolde","Syndicate","ogre"}},
    {96783,"objective",{"Stromgarde Keep","Northfold Manor","Syndicate"}},
    {96784,"objective",{"Syndicate","Stromgarde Keep"}},
    {96785,"objective",{"Anastasia","Stromgarde Keep"}},
    {96786,"objective",{"Syndicate","Ravenholdt Manor","Myrokos Silentform"}},
    {1947,"detail",{"mage","human","Tabetha","Dustwallow Marsh","Theramore","Stonemaul Ruins"}},
    {1948,"objective",{"Jade","Bolt Charged Bramble","Dustwallow Marsh","Tabetha"}},
    {1949,"detail",{"Magus Tirth","Rituals of Power","mage","Shimmering Flats","gnome","goblin"}},
    {1950,"complete",{"Johnson"}},
    {1951,"title",{"Rituals of Power"}},
    {1952,"title",{"Mage"}},
    {1953,"detail",{"Dustwallow Marsh","Tabetha","mage","Theramore"}},
    {1718,"detail",{"warrior","Barrens","Ratchet","Fray Island","Klannoc Macleod","Merchant Coast"}},
    {1719,"detail",{"The Affray","warrior","Fray Island","Twiggy Flathead","Big Will"}},
    {1791,"detail",{"berserker's stance","Alterac Mountains","Western Plaguelands","troll","Bath'rah the Windwatcher","shaman","Tarren Mill"}},
    {1712,"objective",{"Bath'rah's Parchment","Alterac","Bath'rah the Windwatcher"}},
    {1713,"objective",{"Whirlwind Heart","Bath'rah Windwatcher"}},
    {1792,"complete",{"Whirlwind Heart","Cyclonian"}},
    {1714,"title",{"Essence of the Exile"}},
    {185,"objective",{"Nesingwary's Expedition","Ajeck Rouack","Young Stranglethorn Tigers"}},
    {186,"objective",{"Nesingwary's Expedition","Ajeck Rouack","Stranglethorn Tigers"}},
    {187,"objective",{"Nesingwary's Expedition","Ajeck Rouack","Elder Stranglethorn Tigers"}},
    {188,"objective",{"Nesingwary's Expedition","Ajeck Rouack","Sin'Dall"}},
    {190,"objective",{"Nesingwary's Expedition","Young Panthers","Sir S. J. Erlgadin"}},
    {191,"objective",{"Nesingwary's Expedition","Panthers","Sir S. J. Erlgadin"}},
    {192,"objective",{"Nesingwary's Expedition","Shadowmaw Panthers","Sir S. J. Erlgadin"}},
    {193,"objective",{"Nesingwary's Expedition","Fang of Bhag'thera","Sir S. J. Erlgadin"}},
    {583,"objective",{"Hemet Nesingwary"}},
    {5762,"objective",{"Kravel's Crate","Stranglethorn","Hemet Nesingwary"}},
    {194,"objective",{"Hemet Nesingwary","Stranglethorn Raptors"}},
    {195,"objective",{"Hemet Nesingwary","Lashtail Raptors"}},
    {196,"objective",{"Hemet Nesingwary","Jungle Stalkers"}},
    {197,"objective",{"Hemet Nesingwary","Stranglethorn","raptor","Tethis"}},
    {208,"objective",{"Hemet Nesingwary","King Bangalash"}},
    {338,"objective",{"The Green Hills of Stranglethorn","Barnil"}},
    {339,"objective",{"Chapter I","Nesingwary","The Green Hills of Stranglethorn","Barnil Stonepot"}},
    {340,"objective",{"Chapter II","Nesingwary","The Green Hills of Stranglethorn","Barnil Stonepot"}},
    {341,"objective",{"Chapter III","Nesingwary","The Green Hills of Stranglethorn","Barnil Stonepot"}},
    {342,"objective",{"Chapter IV","Nesingwary","The Green Hills of Stranglethorn","Barnil Stonepot"}},
    {1387,"objective",{"Centaur Ears","Corporal Melkins","Nijel's Point","Desolace"}},
    {1453,"objective",{"Kreldig Ungor","Desolace"}},
    {1454,"objective",{"Karnitol's Chest","Desolace"}},
    {1455,"objective",{"Kreldig Ungor","Desolace"}},
    {1456,"objective",{"Karnitol's Satchel","Kreldig Ungor","Desolace"}},
    {1457,"objective",{"Karnitol's Satchel","Roetten Stonehammer","Ironforge"}},
    {1458,"objective",{"Hatefury Claws","Hatefury Horns","Kreldig Ungor","Desolace"}},
    {1459,"objective",{"Scorpashi Venom","Aged Kodo Hides","Kreldig Ungor","Desolace"}},
    {1466,"objective",{"Felhound Brains","Nether Wings","Doomwarder Blood","Kreldig Ungor","Desolace"}},
    {1467,"objective",{"Leftwitch's Package","Roetten Stonehammer","Ironforge"}}}
  for _,c in ipairs(contracts) do
    local value=assert(A.quests[c[1]][c[2]],'Source identity field absent'):lower()
    for _,term in ipairs(c[3]) do assert(value:find(term:lower(),1,true),'Source identity failed:'..c[1]..'/'..term) end
  end
  for _,c in ipairs({}) do
    questID=c[1];fire(({detail='QUEST_DETAIL',objective='QUEST_DETAIL',progress='QUEST_PROGRESS',complete='QUEST_COMPLETE'})[c[2]]);flush()
    assert(A.window:IsShown() and shown.text:find(A.quests[c[1]][c[2]],1,true),'Encoded source field did not render for exactID')
  end
  for _,r in ipairs({{96783,"progress"},{96784,"progress"},{1947,"progress"},{1949,"progress"},{1952,"progress"},{1953,"progress"},{1718,"progress"},{1791,"progress"},{1792,"detail"},{1792,"objective"},{1792,"progress"},{1714,"objective"},{583,"progress"},{1453,"progress"},{1454,"progress"},{1455,"progress"}}) do assert(not A.quests[r[1]][r[2]],'Invented current source state:'..r[1]..'/'..r[2]) end
  for _,r in ipairs({{1714,"detail"}}) do
    assert(not A.quests[r[1]][r[2]],'Unsupported source field enabled:'..r[1]..'/'..r[2])
    local event=({detail='QUEST_DETAIL',progress='QUEST_PROGRESS',complete='QUEST_COMPLETE'})[r[2]]
    if event then
      questID=r[1];fire(event);flush()
      assert(not A.window:IsShown() and MMNorthshireCaptures[r[1]].states[r[2]].translationFallback~=nil,'Held state lost original fallback/capture')
    end
  end
  for _,p in ipairs({{96781,96782},{96783,96784},{96784,96785},{96785,96786},{1947,1949},{1949,1950},{1950,1951},{1951,1952},{1947,1948},{1948,1952},{1952,1953},{1718,1719},{1719,1791},{1791,1712},{1712,1713},{5762,583},{583,185},{185,186},{186,187},{187,188},{583,190},{190,191},{191,192},{192,193},{583,194},{194,195},{195,196},{196,197},{188,208},{193,208},{197,208},{338,339},{339,340},{340,341},{341,342},{1453,1454},{1454,1455},{1455,1456},{1456,1457},{1453,1458},{1458,1459},{1459,1466},{1466,1467}}) do assert(A.quests[p[1]].objective~=A.quests[p[2]].objective,'Distinct current-source task stages collapsed') end
  assert(A.quests[185].en==A.quests[186].en and A.quests[186].en==A.quests[187].en and A.quests[187].en==A.quests[188].en,'Tiger Mastery same-title IDs changed')
  assert(A.quests[194].en==A.quests[195].en and A.quests[195].en==A.quests[196].en and A.quests[196].en==A.quests[197].en,'Raptor Mastery same-title IDs changed')
  assert(A.quests[1387].objective~=A.quests[1366].objective,'Alliance and Horde Centaur Bounty recipient objectives collapsed')
  questID=0;titleOverride=nil;fire('QUEST_FINISHED')
  print('PASS:50 source quest contracts,Mastery/Reclaimers/Mage/Warrior/Rogue stages,partial-state boundaries and unavailable-state guards.')
end
