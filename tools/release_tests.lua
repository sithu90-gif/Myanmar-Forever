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
  assert(A.quests[5639].detail,'Source-supported Laurena referral fallback missing')
  assert(not A.quests[5679].complete,'Conflicting learned-spell identity enabled')
  assert(not A.quests[94466].complete,'Unresolved Fire gender variant enabled')
  assert(not A.quests[94822].complete,'Suspicious literal-player-name completion enabled')
  for _,id in ipairs({5634,5635,5636,5637,5638,5640}) do assert(not A.quests[id].objective,'Conflicting Rohan/Laurena route enabled') end
  questID=0;fire('QUEST_FINISHED')
  print('PASS: distinct five-step Fire recipient/reagent/elemental/return contracts, Priest referral identities, completion-only boundaries and unresolved trainer/spell/name branches.')
end
