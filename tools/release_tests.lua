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
