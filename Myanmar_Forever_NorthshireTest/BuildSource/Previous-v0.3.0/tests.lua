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
function GetQuestID() return questID end
function GetTitleText() return 'Live English title' end
function GetQuestText() return 'Live English detail' end
function GetObjectiveText() return 'Kill 10 enemies.' end
function GetProgressText() return 'Live progress.' end
function GetRewardText() return 'Live completion.' end
function UnitName() return 'Test%Hero' end
function UnitClass() return 'Warrior' end
function UnitRace() return 'Human' end
local playerSex=2
function UnitSex() return playerSex end
function GetLocale() return 'enUS' end
function GetBuildInfo() return 'test-client' end
function time() return 123456 end
local selected=33
C_QuestLog={GetSelectedQuest=function() return selected end}
local function flush() local old=queue;queue={};for _,fn in ipairs(old) do fn() end end
local function fire(event,name) for _,o in ipairs(objects) do if o.events[event] then o.scripts.OnEvent(o,event,name) end end end
local A={}
for _,file in ipairs({'Catalogs/Northshire.lua','Renderer.lua','QuestBridge.lua'}) do assert(loadfile(ADDON_DIR..'/'..file))('Myanmar_Forever_NorthshireTest',A) end
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
assert(quests==353 and states==981 and missing==78)
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
function issecretvalue(v) return v==999997 end
questID=999997;fire('QUEST_DETAIL');flush();assert(not A.window:IsShown())
command('capture');assert(MMNorthshireCaptures[999997]==nil)
questID=999999;fire('QUEST_DETAIL');flush()
assert(MMNorthshireCaptures[999999].states.detail,'Unknown quests must be captured automatically')
command('capture');assert(MMNorthshireCaptures[999999].states.detail.detail=='Live English detail')
questID=999998;fire('QUEST_FINISHED');command('capture');assert(MMNorthshireCaptures[999998]==nil)
print('PASS: Lua 5.1; 353 quests / 981 available and 78 absent dialogue states; previews and real-event routing; recovered identities including race/class/name; font failure; saved UI; captures; stale/unknown/secret guards; unverified elf branch and placeholder held.')

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
