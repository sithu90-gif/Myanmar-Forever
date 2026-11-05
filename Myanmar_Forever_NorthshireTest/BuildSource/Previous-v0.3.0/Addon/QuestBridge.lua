-- Adapted from the v0.3.1 QuestReader event/revision guard. Catalog stays separate.
local addonName, A = ...
local phase, revision = nil, 0
local selected,live=nil,nil
local english,auto=false,true
local events={QUEST_DETAIL="detail",QUEST_PROGRESS="progress",QUEST_COMPLETE="complete"}
local function read(fn,...)
  if type(fn)~="function" then return nil end
  local ok,v=pcall(fn,...)
  if not ok then return nil end
  if type(issecretvalue)=="function" then
    local safe,secret=pcall(issecretvalue,v)
    if not safe or secret then return nil end
  end
  return v
end
local function stringValue(fn,...)
  local v=read(fn,...); return type(v)=="string" and v or nil
end
local function safeIdentity(fn)
  return (stringValue(fn,"player") or "?"):gsub("|","||")
end
local function expand(text)
  -- These are editorial reference markers, not inferred raw Forever tokens.
  -- Function replacements prevent player-name percent characters acting as escapes.
  return (text:gsub("<([a-zA-Z/]+)>",function(originalMarker)
    local marker=originalMarker:lower()
    if marker=="name" then return safeIdentity(UnitName) end
    if marker=="class" then return safeIdentity(UnitClass) end
    if marker=="race" then return safeIdentity(UnitRace) end
    if marker=="priest/priestess" then
      return read(UnitSex,"player")==3 and A.labels.priestess or A.labels.priest
    end
    return "<"..originalMarker..">"
  end))
end
local function show(id,stage,preview)
  local q=A.quests[id]
  A.window:Hide()
  if not q then return false end
  if stage=="log" then stage="detail" end
  selected={id=id,stage=stage,preview=preview}
  local text=q[stage]
  local body,source
  if A.debug and english then
    local row=MMNorthshireCaptures and MMNorthshireCaptures[id]
    local entry=row and row.states and row.states[stage]
    text=entry and entry[stage]
    if text and stage=="detail" and entry.objective then text=text.."\n\nObjectives\n"..entry.objective end
    body=(text or "No captured English for this quest/state. Open that dialogue at its NPC to capture it."):gsub("|","||")
    source="Captured English"
  else
    if not text then
      if not A.debug then return false end
      body="No Myanmar draft for this quest/state."
    else
      if stage=="detail" and q.objective then text=text.."\n\n|cffffd200"..A.labels.objective.."|r\n"..q.objective end
      body=expand("|cffffd200"..q.title.."|r\n\n"..text)
    end
    source="Myanmar | Draft translation"
  end
  A.ShowText(q.en,body,(preview and "PREVIEW" or "LIVE").." | Quest "..id.." | "..stage.." | "..source)
  return true
end
local function capture(id,stage,manual)
  MMNorthshireCaptures=MMNorthshireCaptures or {}
  local row=MMNorthshireCaptures[id] or {states={}}
  local state={title=stringValue(GetTitleText),capturedAt=read(time),locale=read(GetLocale),build=read(GetBuildInfo),
    source="Live client getters; may contain substituted player values or other-addon translations, not guaranteed raw English."}
  if stage=="detail" then state.detail=stringValue(GetQuestText); state.objective=stringValue(GetObjectiveText)
  elseif stage=="progress" then state.progress=stringValue(GetProgressText)
  elseif stage=="complete" then state.complete=stringValue(GetRewardText) end
  row.states[stage]=state; MMNorthshireCaptures[id]=row
end
local listener=CreateFrame("Frame")
for event in pairs(events) do listener:RegisterEvent(event) end
listener:RegisterEvent("QUEST_FINISHED"); listener:RegisterEvent("ADDON_LOADED")
listener:SetScript("OnEvent",function(_,event,name)
  if event=="ADDON_LOADED" then
    if name==addonName then
      A.RestoreWindow(false)
    end
    return
  end
  revision=revision+1; local expectedRevision=revision
  live=nil
  phase=events[event]; local expectedPhase=phase
  A.window:Hide()
  if not phase then return end
  local function open()
    if revision~=expectedRevision or phase~=expectedPhase then return end
    local id=read(GetQuestID)
    if type(id)~="number" or id<=0 or id>=1000000000 or id~=math.floor(id) then return end
    capture(id,expectedPhase);live={id=id,stage=expectedPhase}
    if auto then show(id,expectedPhase,false) end
  end
  if C_Timer and C_Timer.After then C_Timer.After(0,open) else open() end
end)
SLASH_MMNORTHSHIRETEST1="/mmnorth"
SlashCmdList.MMNORTHSHIRETEST=function(message)
  local args=(message or ""):match("^%s*(.-)%s*$"):lower()
  if args=="debug" then SlashCmdList.MMFOREVERDEBUG(""); return end
  if args=="capture" then
    local id=read(GetQuestID)
    if phase and type(id)=="number" and id>0 and id<1000000000 and id==math.floor(id) then
      capture(id,phase,true)
      print("Northshire: captured Quest "..id.." | "..phase.." locally. /reload saves it to disk.")
    else print("Northshire: open an NPC quest dialogue before using /mmnorth capture.") end
    return
  end
  if args=="reset" then A.RestoreWindow(true); print("Northshire window reset."); return end
  if args=="hide" then A.window:Hide(); return end
  if args=="help" or args=="list" then
    local ids={};for id in pairs(A.quests) do ids[#ids+1]=id end;table.sort(ids)
    for i,id in ipairs(ids) do ids[i]=tostring(id) end
    print("Northshire quest IDs: "..table.concat(ids,", "))
    print("/mmnorth ID; add progress or complete. /mmnorth capture saves an untranslated NPC quest; /mmnorth reset.")
    return
  end
  local id,stage,preview
  if args~="" then
    local digits,s=args:match("^(%d+)%s*(%a*)$")
    id=tonumber(digits); stage=(s and s~="") and s or "detail"; preview=true
    if stage~="detail" and stage~="progress" and stage~="complete" and stage~="log" then id=nil end
  else
    if phase then id=read(GetQuestID); stage=phase end
    if not id or id==0 then id=C_QuestLog and read(C_QuestLog.GetSelectedQuest); stage="log" end
  end
  if not id or not show(id,stage or "detail",preview) then
    A.window:Hide()
    print("Northshire: no packaged text for that quest/state. /mmnorth help.")
  end
end

-- Developer controls belong to this window, not the separate HumanTest addon.
local ids={};for id in pairs(A.quests) do ids[#ids+1]=id end;table.sort(ids)
A.debugButtons={}
local function control(key,label,column,row,fn)
  local b=CreateFrame("Button",nil,A.window,"UIPanelButtonTemplate")
  b:SetSize(100,25);b:SetPoint("BOTTOMLEFT",18+column*105,20+row*30)
  b:SetText(label);b:SetScript("OnClick",function() if A.debug then fn() end end)
  b:Hide();A.debugButtons[key]=b
end
local function redraw()
  if selected then show(selected.id,selected.stage,selected.preview) end
end
local function step(delta)
  local index=1
  for i,id in ipairs(ids) do if selected and selected.id==id then index=i;break end end
  english=false;show(ids[(index-1+delta)%#ids+1],"detail",true)
end
control("previous","Previous quest",0,2,function() step(-1) end)
control("next","Next quest",1,2,function() step(1) end)
control("english","English / MM",2,2,function() english=not english;redraw() end)
for i,item in ipairs({{"detail","Offer"},{"progress","Progress"},{"complete","Complete"}}) do
  local stage=item[1]
  control(stage,item[2],i-1,1,function() show(selected and selected.id or 783,stage,true) end)
end
control("auto","Auto: ON",0,0,function() auto=not auto;A.RefreshDebugControls() end)
control("live","Live",1,0,function()
  if live then english=false;show(live.id,live.stage,false)
  else print("Northshire: no supported NPC dialogue is currently open.") end
end)
function A.RefreshDebugControls()
  for _,b in pairs(A.debugButtons) do if A.debug then b:Show() else b:Hide() end end
  A.debugButtons.auto:SetText(auto and "Auto: ON" or "Auto: OFF")
end
function A.OnDebugChanged()
  if not A.debug then
    english=false
    if selected and A.window:IsShown() then redraw() end
  end
end

-- Shared session-only command: both addon variants can coexist without stealing it.
MMForeverDebugHandlers=MMForeverDebugHandlers or {}
SLASH_MMFOREVERDEBUG1="/mmdebug"
SlashCmdList.MMFOREVERDEBUG=function(message)
    local arg=(message or ""):match("^%s*(.-)%s*$"):lower()
    local enabled
    if arg=="on" then enabled=true
    elseif arg=="off" then enabled=false
    elseif arg=="" then enabled=not MMForeverDebugEnabled
    else print("/mmdebug [on|off]");return end
    MMForeverDebugEnabled=enabled
    for _,apply in pairs(MMForeverDebugHandlers) do apply(enabled) end
    print("Myanmar debug: "..(enabled and "ON" or "OFF"))
end

MMForeverDebugHandlers.Northshire=function(enabled)
    if (A.debug==true)~=enabled then A.ToggleDebug() end
end
MMForeverDebugHandlers.Northshire(MMForeverDebugEnabled==true)
