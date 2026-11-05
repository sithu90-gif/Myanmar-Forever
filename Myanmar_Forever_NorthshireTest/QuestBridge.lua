-- Modified for MyanmarForever v0.6.2-beta-candidate on 2026-10-11; see CREDITS.txt.
-- Adapted from the v0.3.1 QuestReader event/revision guard. Catalog stays separate.
local addonName, A = ...
local phase, revision = nil, 0
local selected,live=nil,nil
local currentView
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
local function normalizedTitle(title)
  if type(title)~="string" or title=="" then return nil end
  -- Formatting and case do not change identity. Do not use fuzzy matching or
  -- discard punctuation: differently named quests can share an old beta ID.
  title=title:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
  title=title:gsub("\226\128\152","'"):gsub("\226\128\153","'")
    :gsub("\226\128\156",'"'):gsub("\226\128\157",'"')
  title=title:match("^%s*(.-)%s*$"):gsub("%s+"," "):lower()
  return title~="" and title or nil
end
local function matchesTitle(q,title)
  local actual=normalizedTitle(title)
  if not actual then return false end
  if actual==normalizedTitle(q.en) then return true end
  for _,alias in ipairs(q.enAliases or {}) do
    if actual==normalizedTitle(alias) then return true end
  end
  return false
end
local function contextTitle(id,stage)
  if stage=="log" then
    return C_QuestLog and stringValue(C_QuestLog.GetTitleForQuestID,id)
  end
  -- A remembered NPC selection is not proof that its dialogue is still open.
  if phase and read(GetQuestID)==id then return stringValue(GetTitleText) end
end
local function identityLabel(kind,fn)
  local raw=safeIdentity(fn)
  local labels=A.identityLabels and A.identityLabels[kind]
  if not labels then return {en=raw} end
  -- UnitClass/UnitRace's second return is the locale-independent identity.
  -- Read it through the same error/secret-value guard as every other getter.
  local token
  if type(fn)=="function" then
    token=stringValue(function() local _,v=fn("player");return v end)
  end
  local record=token and labels[token]
  if not record then
    for _,candidate in pairs(labels) do
      if candidate.en==raw then record=candidate;break end
    end
  end
  return record or {en=raw}
end
local function identityFunction(kind)
  if kind=="class" then return UnitClass end
  return UnitRace
end
local function identities()
  local priest=read(UnitSex,"player")==3 and A.labels.priestess or A.labels.priest
  return {name=safeIdentity(UnitName),
    class=identityLabel("class",identityFunction("class")),
    race=identityLabel("race",identityFunction("race")),priest={en=priest,full=priest}}
end
local function show(id,stage,preview)
  local requestedStage=stage
  local q=A.quests[id]
  currentView=nil
  A.window:Hide()
  if not preview then A.TermIntroductions.SetContext(id,stage) end
  if not q then return false end
  -- Explicit catalog previews remain available for reviewing translations.
  -- Live NPC/log displays require an English title that identifies this quest.
  if not preview and not matchesTitle(q,contextTitle(id,stage)) then return false end
  selected={id=id,stage=stage,preview=preview}
  if stage=="log" then stage="detail" end
  local text=q[stage]
  local body,source,onVisible
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
      local fields={{field="title",text=q.title},{field=stage,text=text}}
      if stage=="detail" and q.objective then fields[#fields+1]={field="objective",text=q.objective} end
      local expanded,commit=A.TermIntroductions.Prepare(id,stage,preview,fields,identities())
      body="|cffffd200"..expanded[1].."|r\n\n"..expanded[2]
      if expanded[3] then body=body.."\n\n|cffffd200"..A.labels.objective.."|r\n"..expanded[3] end
      if not preview then
        local ticket,expectedRevision={},revision
        currentView=ticket
        onVisible=function()
          if currentView==ticket and revision==expectedRevision and A.window:IsShown() and not (A.debug and english)
            and matchesTitle(q,contextTitle(id,requestedStage)) then commit() end
        end
      end
    end
    source="Myanmar | Draft translation"
  end
  A.ShowText(q.en,body,(preview and "PREVIEW" or "LIVE").." | Quest "..id.." | "..stage.." | "..source,onVisible)
  return true
end
local function capture(id,stage,manual)
  MMNorthshireCaptures=MMNorthshireCaptures or {}
  local row=MMNorthshireCaptures[id] or {states={}}
  local state={title=stringValue(GetTitleText),capturedAt=read(time),locale=read(GetLocale),build=read(GetBuildInfo),
    source="Live client getters; may contain substituted player values or other-addon translations, not guaranteed raw English."}
  local q=A.quests[id]
  state.catalogTitle=q and q.en or nil
  state.titleMatch=q and matchesTitle(q,state.title) or false
  if not q then state.translationFallback="quest_not_in_catalog"
  elseif not normalizedTitle(state.title) then state.translationFallback="title_unavailable"
  elseif not state.titleMatch then state.translationFallback="title_mismatch"
  elseif q[stage]==nil then state.translationFallback="state_absent_or_held" end
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
      A.TermIntroductions.Restore()
      A.RestoreWindow(false)
    end
    return
  end
  revision=revision+1; local expectedRevision=revision
  live=nil;currentView=nil
  if event=="QUEST_FINISHED" then A.TermIntroductions.Invalidate() end
  phase=events[event]; local expectedPhase=phase
  A.window:Hide()
  if not phase then return end
  local function open()
    if revision~=expectedRevision or phase~=expectedPhase then return end
    local id=read(GetQuestID)
    if type(id)~="number" or id<=0 or id>=1000000000 or id~=math.floor(id) then return end
    A.TermIntroductions.SetContext(id,expectedPhase)
    capture(id,expectedPhase);live={id=id,stage=expectedPhase}
    if auto then show(id,expectedPhase,false) end
  end
  if C_Timer and C_Timer.After then C_Timer.After(0,open) else open() end
end)
function A.DismissReader()
  -- Invalidate pending NPC callbacks as well as hiding the visible reader.
  revision=revision+1;currentView=nil
  A.window:Hide()
end
function A.ToggleReader()
  if A.window:IsShown() then A.DismissReader(); return end
  if live then show(live.id,live.stage,false)
  elseif selected then show(selected.id,selected.stage,selected.preview)
  else SlashCmdList.MMNORTHSHIRETEST("") end
end
SLASH_MMNORTHSHIRETEST1="/mmnorth"
SLASH_MMNORTHSHIRETEST2="/mmforever"
SlashCmdList.MMNORTHSHIRETEST=function(message)
  local args=(message or ""):match("^%s*(.-)%s*$"):lower()
  if args=="debug" then SlashCmdList.MMFOREVERDEBUG(""); return end
  if args=="capture" then
    local id=read(GetQuestID)
    if phase and type(id)=="number" and id>0 and id<1000000000 and id==math.floor(id) then
      capture(id,phase,true)
      print("Myanmar Forever: captured Quest "..id.." | "..phase.." locally. /reload saves it to disk.")
    else print("Myanmar Forever: open an NPC quest dialogue before using /mmnorth capture.") end
    return
  end
  if args=="reset" then A.RestoreWindow(true); print("Myanmar Forever window reset."); return end
  if args=="hide" then A.DismissReader(); return end
  if args=="up" then A.ScrollReader(-126); return end
  if args=="down" then A.ScrollReader(126); return end
  if args=="bigger" then A.ChangeFont(2); return end
  if args=="smaller" then A.ChangeFont(-2); return end
  if args=="toggle" then A.ToggleReader(); return end
  if args=="help" or args=="list" then
    local ids={};for id in pairs(A.quests) do ids[#ids+1]=id end;table.sort(ids)
    for i,id in ipairs(ids) do ids[i]=tostring(id) end
    print("Myanmar Forever quest IDs: "..table.concat(ids,", "))
    print("/mmforever ID [progress|complete]; /mmforever capture; /mmforever reset.")
    print("Reader: /mmforever up, down, bigger, smaller, toggle, hide. Bind keys or gamepad buttons under Myanmar Forever in Key Bindings.")
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
    print("Myanmar Forever: no packaged text for that quest/state. /mmnorth help.")
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
  else print("Myanmar Forever: no supported NPC dialogue is currently open.") end
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
