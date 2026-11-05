-- WoW API mock for lifecycle/state correctness; no visual/game compatibility claim.
local objects,queue={},{}
local M={}
local function make(kind,name)
  local o=setmetatable({kind=kind,name=name,scripts={},events={},w=620,h=620,shown=true,scroll=0},{__index=M})
  objects[#objects+1]=o;if name then _G[name]=o end;return o
end
function CreateFrame(kind,name,parent,template) return make(kind,name) end
function M:CreateTexture() return make('texture') end
function M:CreateFontString() return make('font') end
function M:SetSize(w,h) self.w=w;self.h=h;if self.scripts.OnSizeChanged then self.scripts.OnSizeChanged(self,w,h) end end
function M:SetWidth(w) self.w=w end
function M:SetHeight(h) self.h=h end
function M:GetWidth() return self.w end
function M:GetHeight() return self.h end
function M:SetPoint(p,relative,rp,x,y) self.point={p,relative,rp,x,y} end
function M:GetPoint() return unpack(self.point or {'CENTER',UIParent,'CENTER',0,0}) end
function M:SetScript(k,fn) self.scripts[k]=fn end
function M:RegisterEvent(e) self.events[e]=true end
function M:Hide() local was=self.shown;self.shown=false;if was and self.scripts.OnHide then self.scripts.OnHide(self) end end
function M:Show() self.shown=true end
function M:IsShown() return self.shown end
function M:SetText(t) self.text=t end
function M:GetText() return self.text end
function M:SetFont(font,size) self.font=fontFailure and 'wrong-font' or font;self.size=size;return nil end
function M:GetFont() return self.font,self.size,'' end
local coldLayout=true
function M:GetStringHeight()
  if self.kind=='font' and self.font then
    assert(MMNorthshireTestWindow:IsShown(),'Text measured while reader is hidden')
    if coldLayout then return 0 end
  end
  return math.max(30,#(self.text or '')/5)
end
function M:SetVerticalScroll(n) self.scroll=n end
function M:GetVerticalScroll() return self.scroll end
function M:SetScrollChild(c) self.child=c end
function M:StartMoving() self.moving=true end
function M:StartSizing() self.sizing=true end
function M:StopMovingOrSizing() self.moving=false;self.sizing=false end
for _,k in ipairs({'SetBackdrop','SetTexture','SetNormalTexture','SetHighlightTexture','SetPushedTexture','SetAllPoints','SetColorTexture','SetTextColor','SetJustifyH','SetJustifyV','SetFrameStrata','SetClampedToScreen','SetMovable','SetResizable','EnableMouse','RegisterForDrag','EnableMouseWheel','ClearAllPoints','SetSpacing','SetResizeBounds'}) do M[k]=function() end end
UIParent=make('Frame');UIParent.w=1920;UIParent.h=1080
UISpecialFrames={};SlashCmdList={}
C_Timer={After=function(_,f) queue[#queue+1]=f end}
local questID=0
local catalogTitles={}
local titleOverride,titleUnavailable,titleError,titleSecret=nil,false,false,false
function GetQuestID() return questID end
function GetTitleText()
  if titleError then error('Title unavailable this frame') end
  if titleUnavailable then return nil end
  return titleOverride or catalogTitles[questID] or 'Live English title'
end
function GetQuestText() return 'Live English detail' end
function GetObjectiveText() return 'Kill 10 enemies.' end
function GetProgressText() return 'Live progress.' end
function GetRewardText() return 'Live completion.' end
function UnitName() return 'Test%Hero' end
local playerClass,playerRace='Warrior','Human'
function UnitClass() return playerClass end
function UnitRace() return playerRace end
local playerSex=2
function UnitSex() return playerSex end
function GetLocale() return 'enUS' end
function GetBuildInfo() return 'test-client' end
function time() return 123456 end
local selected=33
local logTitleOverride,logTitleUnavailable=nil,false
C_QuestLog={GetSelectedQuest=function() return selected end,
  GetTitleForQuestID=function(id) if not logTitleUnavailable then return logTitleOverride or catalogTitles[id] end end}
local function flush() local old=queue;queue={};for _,fn in ipairs(old) do fn() end end
local function fire(event,name) for _,o in ipairs(objects) do if o.events[event] then o.scripts.OnEvent(o,event,name) end end end
local A={}
for _,file in ipairs({'Catalogs/Northshire.lua','Renderer.lua','QuestBridge.lua','Controls.lua'}) do assert(loadfile(ADDON_DIR..'/'..file))('Myanmar_Forever_NorthshireTest',A) end
for id,q in pairs(A.quests) do catalogTitles[id]=q.en end
fire('ADDON_LOADED','Myanmar_Forever_NorthshireTest')
assert(MMNorthshireSettings.fontSize==16)
assert(A.window:GetWidth()==440 and A.window:GetHeight()==560)
local shown={};local actualShow=A.ShowText
A.ShowText=function(title,text,note) shown={title=title,text=text,note=note};actualShow(title,text,note) end
local command=SlashCmdList.MMNORTHSHIRETEST
-- Simulate a cold client whose font metrics arrive on the following frame.
command('7')
local body
for _,o in ipairs(objects) do if o.kind=='font' and o.font then body=o end end
assert(body and body.h==16,'Cold first frame should have no measured text yet')
coldLayout=false;flush()
assert(body.h>16,'First-open text must reflow without pressing A+ or A-')
assert(MMNorthshireSettings.fontSize==16,'Startup refresh must preserve font size')
command('33');command('7');flush()
assert(shown.title==A.quests[7].en,'Deferred refresh replaced the latest quest')
command('7');A.window:Hide();flush()
assert(not A.window:IsShown(),'Deferred refresh reopened the reader')
assert(A.debug~=true,'Debug must default off')
local debugCommand=SlashCmdList.MMFOREVERDEBUG
local function clickDebug(key)
  local b=A.debugButtons[key];assert(b and b:IsShown(),key..' control missing or hidden')
  b.scripts.OnClick()
end
for _,b in pairs(A.debugButtons) do assert(not b:IsShown()) end
assert(type(debugCommand)=='function' and SLASH_MMFOREVERDEBUG1=='/mmdebug')
local otherDebug
MMForeverDebugHandlers.TestOtherAddon=function(enabled) otherDebug=enabled end
debugCommand('on');assert(A.debug==true and otherDebug==true)
for _,b in pairs(A.debugButtons) do assert(b:IsShown()) end
debugCommand('off');assert(A.debug==false and otherDebug==false)
for _,b in pairs(A.debugButtons) do assert(not b:IsShown()) end
debugCommand('');assert(A.debug==true)
debugCommand('off');MMForeverDebugHandlers.TestOtherAddon=nil
local quests,states,missing=0,0,0
for id in pairs(A.quests) do
  quests=quests+1
  for _,stage in ipairs({'detail','progress','complete'}) do
    command(id..' '..stage)
    assert(A.window:IsShown()==(A.quests[id][stage]~=nil))
    if A.window:IsShown() then
      states=states+1
      assert(not shown.text:find('<[a-zA-Z/]+>'),'Unexpanded identity marker')
      assert(shown.title==A.quests[id].en)
    else missing=missing+1 end
  end
end
assert(quests==EXPECTED_QUESTS and states==EXPECTED_STATES and missing==EXPECTED_MISSING)
assert(MMNorthshireCaptures==nil,'Previews must not fake source captures')
command('40');assert(shown.text:find('Test%Hero',1,true),'Uppercase Name marker not expanded')
command('109');assert(shown.text:find('Warrior',1,true),'Uppercase Class marker not expanded')
command('7677');assert(not A.window:IsShown(),'Held quest released')
command('7678');assert(not A.window:IsShown(),'Placeholder quest released')
command('98021 complete');assert(not A.window:IsShown(),'Unverified elf-specific completion released')
for _,id in ipairs({91775,91724,91733,91777,92745,98387,98407,95999}) do
  command(id..' complete');assert(shown.text:find('Test%Hero',1,true),'Recovered player-name token failed')
end
for _,id in ipairs({92749,92909}) do
  command(id..' progress');assert(shown.text:find('Test%Hero',1,true),'Recovered progress player-name token failed')
end
command('91751 complete');assert(shown.text:find('Warrior',1,true),'Recovered class token failed')
command('95999 progress');assert(shown.text:find('Human',1,true),'Recovered race token failed')
command('93928 complete');assert(not A.window:IsShown(),'Unfinished placeholder released')
command('92479 progress');assert(shown.text:find('Human',1,true));assert(shown.text:find('Test%Hero',1,true))
command('5623');assert(shown.text:find(A.labels.priest,1,true))
playerSex=3;command('5623');assert(shown.text:find(A.labels.priestess,1,true));playerSex=2
command('91741');assert(shown.text:find('<',1,true) and shown.text:find('>',1,true),'Stage direction brackets lost')
command('16');assert(not A.window:IsShown())
command('16 progress');assert(A.window:IsShown())
command('783');assert(shown.text:find('Warrior',1,true))
command('7');assert(shown.text:find('Test%Hero',1,true))
assert(shown.text:find(A.labels.objective,1,true))
questID=7;fire('QUEST_DETAIL');flush();assert(A.window:IsShown())
assert(MMNorthshireCaptures[7].states.detail.detail=='Live English detail')
debugCommand('on')
clickDebug('english');assert(shown.text:find('Live English detail',1,true))
clickDebug('english');assert(shown.text:find('Test%Hero',1,true))
clickDebug('progress');assert(shown.note:find('PREVIEW',1,true) and shown.note:find('progress',1,true))
clickDebug('complete');assert(shown.note:find('complete',1,true))
clickDebug('detail');assert(shown.note:find('detail',1,true))
clickDebug('next');assert(shown.title~=A.quests[7].en)
clickDebug('previous');assert(shown.title==A.quests[7].en)
clickDebug('live');assert(shown.note:find('LIVE',1,true) and shown.note:find('detail',1,true))
clickDebug('auto');assert(A.debugButtons.auto.text=='Auto: OFF')
fire('QUEST_COMPLETE');flush();assert(not A.window:IsShown())
command('7') -- Explicit access remains available while automatic opening is off.
clickDebug('live');assert(A.window:IsShown() and shown.note:find('complete',1,true))
clickDebug('auto');assert(A.debugButtons.auto.text=='Auto: ON')
command('783 progress');assert(A.window:IsShown() and shown.text:find('No Myanmar draft',1,true))
clickDebug('english');assert(shown.text:find('No captured English',1,true))
clickDebug('live');clickDebug('english')
debugCommand('off');assert(not shown.text:find('Live completion.',1,true))
for _,b in pairs(A.debugButtons) do assert(not b:IsShown()) end
fire('QUEST_PROGRESS');flush();assert(shown.note:find('progress',1,true));assert(not shown.text:find(A.labels.objective,1,true))
fire('QUEST_COMPLETE');flush();assert(MMNorthshireCaptures[7].states.complete.complete=='Live completion.')
fire('QUEST_FINISHED');assert(not A.window:IsShown())
-- Expanded catalog must route real events to the same state, not just previews.
local eventMap={detail='QUEST_DETAIL',progress='QUEST_PROGRESS',complete='QUEST_COMPLETE'}
for id,q in pairs(A.quests) do
  questID=id
  for stage,event in pairs(eventMap) do
    fire(event);flush()
    assert(A.window:IsShown()==(q[stage]~=nil))
    assert(MMNorthshireCaptures[id].states[stage],'New quest capture missing')
    if q[stage] then
      assert(shown.title==q.en and shown.note:find(stage,1,true))
      assert(not shown.text:find('<[a-zA-Z/]+>'))
    end
  end
end
fire('QUEST_FINISHED');assert(not A.window:IsShown())
-- Pending NPC callbacks must not reopen stale content after closing or switching.
questID=7;fire('QUEST_DETAIL');fire('QUEST_FINISHED');flush();assert(not A.window:IsShown())
questID=7;fire('QUEST_DETAIL');questID=999999;fire('QUEST_DETAIL');flush();assert(not A.window:IsShown());assert(MMNorthshireCaptures[999999].states.detail)
questID=33;fire('QUEST_DETAIL');fire('QUEST_COMPLETE');flush();assert(shown.note:find('complete',1,true))
questID=783;fire('QUEST_PROGRESS');flush();assert(not A.window:IsShown())
fire('QUEST_FINISHED');questID=0;command('');assert(shown.title==A.quests[33].en)
command('999999');assert(not A.window:IsShown())
command('7 nonsense');assert(not A.window:IsShown())
command('7');A.window:SetSize(900,750);A.window:Hide()
assert(MMNorthshireSettings.width==900 and MMNorthshireSettings.height==750)
A.RestoreWindow(false);assert(A.window:GetWidth()==900)
command('reset');assert(A.window:GetWidth()==440 and MMNorthshireSettings.fontSize==16)
fontFailure=true;command('7')
local foundError=false
for _,o in ipairs(objects) do if o.text and o.text:find('Myanmar text could not load',1,true) then foundError=true end end
assert(foundError,'Font mismatch must expose readable error')
fontFailure=false;command('7')
A.increaseFont.scripts.OnClick()
assert(MMNorthshireSettings.fontSize==18)
command('debug');assert(A.debug==true)
command('debug');assert(A.debug==false)
for _,o in ipairs(objects) do
  assert(not(o.shown and o.text and o.text:find('Draft translation',1,true)), 'Diagnostics visible in normal mode')
end
MMNorthshireSettings={width=1000,height=950,fontSize=20}
A.RestoreWindow(false)
assert(A.window:GetWidth()==440 and A.window:GetHeight()==560 and MMNorthshireSettings.fontSize==20)
QuestFrame=make('Frame');function QuestFrame:GetRight() return 400 end
command('7');assert(A.window.point[2]==QuestFrame,'Default window should dock beside NPC quest')
-- Secret quest identifiers must not be inspected or used as table keys.
function issecretvalue(v) return v==999997 or (titleSecret and type(v)=='string' and v==GetTitleText()) end
questID=999997;fire('QUEST_DETAIL');flush();assert(not A.window:IsShown())
command('capture');assert(MMNorthshireCaptures[999997]==nil)
questID=999999;fire('QUEST_DETAIL');flush()
assert(MMNorthshireCaptures[999999].states.detail,'Unknown quests must be captured automatically')
command('capture');assert(MMNorthshireCaptures[999999].states.detail.detail=='Live English detail')
questID=999998;fire('QUEST_FINISHED');command('capture');assert(MMNorthshireCaptures[999998]==nil)
print('PASS: Lua 5.1; '..quests..' quests / '..states..' available and '..missing..' absent or held dialogue states; previews and real-event routing; recovered identities including race/class/name; font failure; saved UI; captures; stale/unknown/secret guards; unverified elf branch and placeholder held.')

-- Automatic captures do not require a Myanmar catalog record.
for _,case in ipairs({{'QUEST_DETAIL','detail'},{'QUEST_PROGRESS','progress'},{'QUEST_COMPLETE','complete'}}) do
  questID=999996;fire(case[1]);flush()
  assert(not A.window:IsShown(),'Unknown quest must retain native UI')
  assert(MMNorthshireCaptures[999996].states[case[2]],'Automatic capture state missing')
end
for _,bad in ipairs({0,-1,0.5,1000000000}) do
  questID=bad;fire('QUEST_DETAIL');flush();assert(MMNorthshireCaptures[bad]==nil)
end
command('96627');assert(shown.text:find('Test%Hero',1,true))
command('96627 complete');assert(shown.text:find('Warrior',1,true))
command('95998');assert(shown.text:find('Warrior',1,true))
command('96626');assert(shown.text:find('Warrior',1,true))
command('97924 complete');assert(not A.window:IsShown())
print('PASS: automatic capture of unknown quests in all 3 states, invalid/secret IDs rejected; new live quest identity markers and absent states.')

for _,id in ipairs({179,170,3107,3115,98423,86585,1097}) do command(tostring(id));assert(A.window:IsShown()) end
command('95213 complete');assert(not A.window:IsShown(),'Ambiguous NPC race field released')
for _,id in ipairs({5841,7673,7674,7675,7676,467,466,86776,256,2500,2501,3182}) do
  assert(not A.quests[id],'Out-of-scope/placeholder quest released')
end
command('257 complete');assert(shown.text:find('Test%Heroama',1,true),'Intentional name suffix lost')
command('258');assert(shown.text:find('Test%Heroath',1,true),'Intentional name suffix lost')
print('PASS: v0.3.0 route additions, class intros, source hold, exclusions and identity suffixes.')

-- Night Elf content and explicit fallback for the unverified captured name.
command('3118 progress');assert(not A.window:IsShown())
questID=3118;fire('QUEST_PROGRESS');flush();assert(not A.window:IsShown())
assert(MMNorthshireCaptures[3118].states.progress)
for _,id in ipairs({456,97977,934,983,4763,3116,3117,3118,3119,3120}) do
  command(tostring(id));assert(A.window:IsShown(),'Night Elf offer missing')
end
assert(SLASH_MMNORTHSHIRETEST2=='/mmforever')
assert(BINDING_HEADER_MYANMARFOREVER=='Myanmar Forever')
-- Inputs clamp at both ends, and do nothing while the reader is hidden.
command('4763');flush()
local scroll=MMNorthshireTestScroll
scroll:SetHeight(80);scroll.child:SetHeight(900)
MMForeverReaderAction('down');assert(scroll:GetVerticalScroll()==126)
MMForeverReaderAction('up');assert(scroll:GetVerticalScroll()==0)
A.ScrollReader(100000);assert(scroll:GetVerticalScroll()==820)
A.ScrollReader(-100000);assert(scroll:GetVerticalScroll()==0)
scroll.scripts.OnMouseWheel(scroll,-1);assert(scroll:GetVerticalScroll()==42)
command('down');assert(scroll:GetVerticalScroll()==168)
command('up');assert(scroll:GetVerticalScroll()==42)
for i=1,20 do MMForeverReaderAction('bigger') end
assert(MMNorthshireSettings.fontSize==28)
for i=1,20 do MMForeverReaderAction('smaller') end
assert(MMNorthshireSettings.fontSize==14)
command('bigger');assert(MMNorthshireSettings.fontSize==16)
command('smaller');assert(MMNorthshireSettings.fontSize==14)
MMForeverReaderAction('close');assert(not A.window:IsShown())
local savedScroll=scroll:GetVerticalScroll()
MMForeverReaderAction('down');MMForeverReaderAction('bigger')
assert(scroll:GetVerticalScroll()==savedScroll and MMNorthshireSettings.fontSize==14)
-- Closing a pending NPC event must cancel it. Toggle restores the latest context.
questID=4763;fire('QUEST_DETAIL');MMForeverReaderAction('close');flush()
assert(not A.window:IsShown(),'Binding close reopened a deferred quest')
fire('QUEST_DETAIL');flush();assert(A.window:IsShown())
MMForeverReaderAction('toggle');assert(not A.window:IsShown())
MMForeverReaderAction('toggle');assert(A.window:IsShown() and shown.title==A.quests[4763].en)
fire('QUEST_FINISHED');command('456');command('hide');command('toggle')
assert(A.window:IsShown() and shown.title==A.quests[456].en)
questID=456;fire('QUEST_DETAIL');command('hide');flush()
assert(not A.window:IsShown(),'Slash close reopened a deferred quest')
-- Execute the shipped XML binding bodies, not a separately maintained mapping.
for i,code in ipairs(BINDING_ACTIONS) do assert(loadstring(code))() end
assert(#BINDING_ACTIONS==6)
print('PASS: Night Elf offers and held-name fallback; six shipped XML bindings; scroll clamps; font-size limits; hidden-input guards; close cancellation and toggle; /mmforever alias.')

-- Orc/Troll identities must reflect the current character without treating % as a replacement escape.
for _,race in ipairs({'Orc','Troll'}) do
  playerRace=race
  command('6394')
  assert(A.window:IsShown() and shown.text:find(race,1,true) and shown.text:find('Test%Hero',1,true))
  playerClass='Shaman';command('96875')
  assert(A.window:IsShown() and shown.text:find('Shaman',1,true))
end
for _,id in ipairs({2383,3065,3082,3083,3084,3085,3086,3087,3088,3089,3090}) do
  command(tostring(id));assert(A.window:IsShown(),'Orc/Troll class introduction missing')
end
-- Ambiguous gender branches and a fixed player name stay in native English until live capture.
for _,sex in ipairs({2,3}) do
  playerSex=sex;questID=842;fire('QUEST_COMPLETE');flush()
  assert(not A.window:IsShown(),'Unverified Crossroads gender branch released')
  assert(MMNorthshireCaptures[842].states.complete)
end
questID=3083;fire('QUEST_PROGRESS');flush()
assert(not A.window:IsShown() and MMNorthshireCaptures[3083].states.progress,'Troll Rogue held-name fallback failed')
questID=97279;fire('QUEST_PROGRESS');flush()
assert(not A.window:IsShown() and MMNorthshireCaptures[97279].states.progress,'Absent custom progress fallback failed')
questID=926;fire('QUEST_COMPLETE');flush();assert(A.window:IsShown())
fire('QUEST_DETAIL');flush();assert(not A.window:IsShown(),'Completion-only quest invented an offer')
for _,id in ipairs({889,5042,5043,5044,5045,5046}) do
  questID=id;fire('QUEST_DETAIL');flush();assert(not A.window:IsShown(),'Repeatable turn-in invented an offer')
  fire('QUEST_PROGRESS');flush();assert(A.window:IsShown())
  fire('QUEST_COMPLETE');flush();assert(A.window:IsShown())
end
playerClass,playerRace,playerSex='Warrior','Human',2
print('PASS: Orc/Troll race, name and class substitutions; 11 class introductions; held gender/name fields captured with native fallback; absent custom progress and completion-only/repeatable turn-ins.')

-- A known numeric ID must never authorize a differently named live quest.
questID=788;titleOverride='A Completely Different Quest'
for event,stage in pairs({QUEST_DETAIL='detail',QUEST_PROGRESS='progress',QUEST_COMPLETE='complete'}) do
  fire(event);flush();assert(not A.window:IsShown(),'Mismatched quest title displayed a translation')
  local capture=MMNorthshireCaptures[788].states[stage]
  assert(capture.title==titleOverride and capture.catalogTitle==A.quests[788].en)
  assert(capture.titleMatch==false and capture.translationFallback=='title_mismatch')
end
MMForeverReaderAction('toggle');assert(not A.window:IsShown(),'Toggle bypassed title validation')
command('788');assert(A.window:IsShown() and shown.note:find('PREVIEW',1,true),'Explicit catalog preview blocked')
titleOverride=' |cffffffffCUTTING   TEETH|r ';fire('QUEST_DETAIL');flush()
assert(A.window:IsShown() and MMNorthshireCaptures[788].states.detail.titleMatch)
titleOverride='Cutting Teeth?';fire('QUEST_DETAIL');flush();assert(not A.window:IsShown(),'Punctuation mismatch was ignored')
titleOverride=nil
for _,mode in ipairs({'missing','error','secret'}) do
  titleUnavailable=mode=='missing';titleError=mode=='error';titleSecret=mode=='secret'
  fire('QUEST_DETAIL');flush();assert(not A.window:IsShown(),'Unverifiable title displayed a translation')
  assert(MMNorthshireCaptures[788].states.detail.translationFallback=='title_unavailable')
end
titleUnavailable,titleError,titleSecret=false,false,false
for _,id in ipairs({138,139,140}) do
  questID=id;titleOverride="Captain Sanders' Hidden Treasure"
  fire('QUEST_DETAIL');flush();assert(A.window:IsShown(),'Documented title alias failed')
end
titleOverride=nil;questID=788;fire('QUEST_DETAIL');flush();assert(A.window:IsShown())
MMForeverReaderAction('close');titleOverride='A Completely Different Quest'
MMForeverReaderAction('toggle');assert(not A.window:IsShown(),'Remembered live context bypassed revalidation')
fire('QUEST_FINISHED');titleOverride=nil;questID=0
selected=33;logTitleOverride='A Completely Different Quest';command('');assert(not A.window:IsShown())
logTitleOverride=nil;logTitleUnavailable=true;command('');assert(not A.window:IsShown())
logTitleUnavailable=false;command('');assert(A.window:IsShown() and shown.title==A.quests[33].en)
MMForeverReaderAction('close');MMForeverReaderAction('toggle');assert(A.window:IsShown(),'Log context was lost when toggling')
logTitleOverride='A Completely Different Quest';MMForeverReaderAction('close');MMForeverReaderAction('toggle')
assert(not A.window:IsShown(),'Log toggle bypassed title validation');logTitleOverride=nil
print('PASS: live NPC and quest-log title validation; wrong/missing/secret/error title fallback with captures; explicit previews; documented aliases; case/format normalization; punctuation protection; toggle revalidation.')

-- Tauren candidate: current source-sensitive offers remain held.
playerRace='Tauren'
for id,cl in pairs({[3091]='Warrior',[3092]='Hunter',[3093]='Shaman',[3094]='Druid'}) do
  playerClass=cl;questID=id
  for stage,event in pairs(eventMap) do
    fire(event);flush();assert(A.window:IsShown()==(A.quests[id][stage]~=nil))
    if A.window:IsShown() then assert(not shown.text:find('<[a-zA-Z/]+>'),'Tauren identity marker unexpanded') end
  end
end
playerClass='Warrior'
for _,id in ipairs({98435,99108}) do
  questID=id;fire('QUEST_DETAIL');flush();assert(not A.window:IsShown(),'Held Tauren offer displayed')
  assert(MMNorthshireCaptures[id].states.detail,'Held offer not captured')
end
assert(A.quests[745].objective==nil and A.quests[98435].objective==nil,'Conflicting objective released')
command('745');assert(A.window:IsShown() and not shown.text:find(A.labels.objective,1,true),'Held objective included in offer')
questID=747;titleOverride='A Different Tauren Quest';fire('QUEST_DETAIL');flush()
assert(not A.window:IsShown() and MMNorthshireCaptures[747].states.detail.translationFallback=='title_mismatch')
titleOverride=nil;fire('QUEST_DETAIL');flush();assert(A.window:IsShown())
for _,id in ipairs({95805,98424,99080,99101,99411}) do
  questID=id;fire('QUEST_COMPLETE');flush();assert(A.window:IsShown(),'Forever-added completion unavailable')
end
playerRace,playerClass='Human','Warrior'
print('PASS: Tauren Warrior/Hunter/Shaman/Druid introductions; preserved identity substitutions; conflicting goals and class-sensitive offers held with captures; new quest title mismatch fallback; Forever-added completion routing.')

-- v0.6.1: dynamic identity labels come from the catalog/font build, reset per
-- displayed section, and never reinterpret player-name percent/color tokens.
local function plainCount(s,term)
  local count,at=0,1
  while true do
    local first,last=s:find(term,at,true)
    if not first then return count end
    count=count+1;at=last+1
  end
end
local saved7=A.quests[7]
local savedClass,savedRace,savedName=UnitClass,UnitRace,UnitName
A.quests[7]={en=saved7.en,title='<class> <race>',detail='<Class> <class> <Race> <race> <name>',objective='<class> <race>',progress='<class> <class>',complete='<race> <race>'}
for token,record in pairs(A.identityLabels.class) do
  UnitClass=function() return 'Localized class',token end
  UnitRace=function() return 'Localized race','NightElf' end
  command('7')
  assert(plainCount(shown.text,record.full)==3,'Class annotation must occur once per title/offer/objective')
  assert(plainCount(shown.text,A.identityLabels.race.NightElf.full)==3,'Race annotation must reset per section')
  assert(plainCount(shown.text,record.en)==4,'Repeated class identity was lost')
  assert(shown.text:find('Test%Hero',1,true),'Name changed during identity annotation')
  command('7 progress');assert(plainCount(shown.text,record.full)==2,'Progress must have its own first use')
end
for token,record in pairs(A.identityLabels.race) do
  UnitRace=function() return 'Localized race',token end
  command('7 complete')
  assert(plainCount(shown.text,record.full)==2,'Race completion annotation failed')
end
UnitClass=function() return 'Warrior' end
UnitRace=function() return 'Orc' end
UnitName=function() return 'Name%Hero|cdeadbeef' end
command('7');assert(shown.text:find(A.identityLabels.class.WARRIOR.full,1,true))
assert(shown.text:find(A.identityLabels.race.Orc.full,1,true))
assert(shown.text:find('Name%Hero||cdeadbeef',1,true),'Player name must stay literal and escaped')
-- Exact literal labels preceding/following a dynamic marker must not double up.
A.quests[7].title='Title'
A.quests[7].objective=nil
A.quests[7].detail=A.identityLabels.class.WARRIOR.full..' <class> <class> '..A.identityLabels.class.WARRIOR.full
command('7');assert(plainCount(shown.text,A.identityLabels.class.WARRIOR.full)==1)
A.quests[7].detail='<class> '..A.identityLabels.class.WARRIOR.full
command('7');assert(plainCount(shown.text,A.identityLabels.class.WARRIOR.full)==1)
UnitClass=function() return 'Future%Class|name','FUTURE' end
A.quests[7].detail='<class> <class>'
command('7');assert(plainCount(shown.text,'Future%Class||name')==2,'Unknown identity must remain literal; no invented pronunciation')
UnitClass=function() error('Unavailable class') end
command('7');assert(plainCount(shown.text,'?')==2,'Identity getter errors must fail safely')
UnitClass=nil
command('7');assert(plainCount(shown.text,'?')==2,'Missing class API must not fall through to race identity')
local previousSecret=issecretvalue
issecretvalue=function(v) return v=='SECRET_CLASS' or v=='SECRET_TOKEN' or previousSecret(v) end
UnitClass=function() return 'SECRET_CLASS','SECRET_TOKEN' end
command('7');assert(not shown.text:find('SECRET',1,true),'Secret identity leaked')
issecretvalue=previousSecret
A.quests[7]=saved7;UnitClass,UnitRace,UnitName=savedClass,savedRace,savedName
-- Repeated transitions must display exactly the accepted ID and current state.
for _,id in ipairs({4641,783,179,956,747,99411}) do
  questID=id;titleOverride=nil
  for _,event in ipairs({'QUEST_DETAIL','QUEST_PROGRESS','QUEST_COMPLETE','QUEST_DETAIL'}) do
    fire(event);flush()
    local stage=({QUEST_DETAIL='detail',QUEST_PROGRESS='progress',QUEST_COMPLETE='complete'})[event]
    assert(A.window:IsShown()==(A.quests[id][stage]~=nil))
    if A.window:IsShown() then assert(shown.title==A.quests[id].en and shown.note:find(stage,1,true)) end
  end
  titleOverride='Changed accepted quest title'
  fire('QUEST_COMPLETE');flush();assert(not A.window:IsShown(),'Stage transition bypassed accepted-title guard')
  fire('QUEST_FINISHED');assert(not A.window:IsShown())
end
titleOverride=nil;questID=0
print('PASS: 17 preshaped class/race identities; first use resets per displayed field; repeated labels deduplicated; localized tokens, unknown/error/secret getters, literal player names; accepted-ID/title/state transitions.')
