-- Modified for MyanmarForever v0.4.0-beta on 2026-10-07; see CREDITS.txt.
-- Reuses v0.4.3's pre-shaped FontString call sequence and v0.3.1's scroll reader.
-- No shaping, quest translations or English-source assumptions belong here.
local _, A = ...
local font = "Interface\\AddOns\\Myanmar_Forever_NorthshireTest\\fonts\\NorthshireShaped.ttf"
local frame = CreateFrame("Frame", "MMNorthshireTestWindow", UIParent, "BackdropTemplate")
A.window = frame
frame:SetSize(440, 560)
frame:SetPoint("CENTER")
frame:SetFrameStrata("DIALOG")
frame:SetClampedToScreen(true)
frame:SetMovable(true)
frame:SetResizable(true)
frame:EnableMouse(true)
frame:Hide()
frame:SetBackdrop({edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",edgeSize=24})
local bg = frame:CreateTexture(nil, "BACKGROUND")
bg:SetPoint("TOPLEFT",7,-7); bg:SetPoint("BOTTOMRIGHT",-7,7)
-- v0.2-style translucent surface. A solid tint fills every resized dimension;
-- no fixed quest-page texture or opaque header block is stretched over it.
bg:SetColorTexture(0.025,0.022,0.018,0.78)
local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 22, -18); title:SetPoint("TOPRIGHT", -105, -18)
title:SetJustifyH("LEFT"); title:SetHeight(25)
local status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
status:SetPoint("TOPLEFT", 20, -46); status:SetPoint("TOPRIGHT", -25, -46)
status:SetJustifyH("LEFT"); status:SetHeight(30)
status:Hide()
local scroll = CreateFrame("ScrollFrame", "MMNorthshireTestScroll", frame, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 24, -64); scroll:SetPoint("BOTTOMRIGHT", -36, 24)
local content = CreateFrame("Frame", nil, scroll)
content:SetSize(550, 1); scroll:SetScrollChild(content)
local body = content:CreateFontString(nil, "OVERLAY")
body:SetPoint("TOPLEFT", 0, 0); body:SetJustifyH("LEFT"); body:SetJustifyV("TOP")
body:SetTextColor(0.96, 0.95, 0.92)
local current, size, manualPosition = nil, 16, false
local function save()
  if not MMNorthshireSettings then return end
  local point, _, relativePoint, x, y = frame:GetPoint()
  MMNorthshireSettings = {width=frame:GetWidth(), height=frame:GetHeight(),
    point=point, relativePoint=relativePoint, x=x, y=y, fontSize=size,
    appearanceVersion=2,manualPosition=manualPosition}
end
local function limits()
  local maxW, maxH = math.max(320, UIParent:GetWidth()-30), math.max(300, UIParent:GetHeight()-30)
  local minW, minH = math.min(360,maxW), math.min(340,maxH)
  if frame.SetResizeBounds then frame:SetResizeBounds(minW,minH,maxW,maxH)
  elseif frame.SetMinResize then frame:SetMinResize(minW,minH); frame:SetMaxResize(maxW,maxH) end
  return minW,minH,maxW,maxH
end
local function render(resetScroll)
  if A.RefreshDebugControls then A.RefreshDebugControls() end
  if not current or not frame:IsShown() then return end
  title:SetText(current.title)
  status:SetText(A.debug and current.status or "")
  status:SetTextColor(0.8,0.8,0.75)
  if A.debug then status:Show() else status:Hide() end
  scroll:ClearAllPoints()
  scroll:SetPoint("TOPLEFT",24,A.debug and -92 or -64)
  scroll:SetPoint("BOTTOMRIGHT",-36,A.debug and 124 or 24)
  local width = math.max(100, frame:GetWidth()-65)
  content:SetWidth(width); body:SetWidth(width); body:SetHeight(0); body:Show()
  -- Keep the working sequence: SetFont -> SetSpacing -> SetText -> GetFont.
  local fontOK = pcall(body.SetFont, body, font, size*A.scale, "")
  body:SetSpacing(3)
  local textOK = pcall(body.SetText, body, current.text)
  local actual = body:GetFont()
  local matches = type(actual)=="string" and actual:gsub("/","\\"):lower()==font:lower()
  if not fontOK or not textOK or not matches then
    body:Hide(); content:SetHeight(1)
    status:SetText("Myanmar text could not load. Please restart World of Warcraft.")
    status:Show()
    return
  end
  if A.debug then status:SetText(current.status.."\nMyanmar font loaded | Draft quest catalog") end
  local height = math.max(1, body:GetStringHeight()+size)
  body:SetHeight(height); content:SetHeight(height+10)
  local maximum = math.max(0, content:GetHeight()-scroll:GetHeight())
  scroll:SetVerticalScroll(resetScroll and 0 or math.min(scroll:GetVerticalScroll(),maximum))
end
local drag = CreateFrame("Frame", nil, frame)
drag:SetPoint("TOPLEFT"); drag:SetPoint("TOPRIGHT"); drag:SetHeight(42)
drag:EnableMouse(true); drag:RegisterForDrag("LeftButton")
drag:SetScript("OnDragStart", function() frame:StartMoving() end)
drag:SetScript("OnDragStop", function() frame:StopMovingOrSizing(); manualPosition=true; save() end)
local function button(label, x, fn)
  local b=CreateFrame("Button",nil,drag)
  b:SetSize(27,25); b:SetPoint("TOPRIGHT",x,-13)
  local caption=b:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
  caption:SetAllPoints();caption:SetText(label)
  b:SetScript("OnClick",fn)
  b:SetScript("OnEnter",function() caption:SetTextColor(1,1,1) end)
  b:SetScript("OnLeave",function() caption:SetTextColor(1,0.82,0) end)
  return b
end
function A.ChangeFont(delta)
  if not frame:IsShown() then return end
  size=math.max(14,math.min(28,size+delta)); render(false); save()
end
local smaller=button("A-",-72,function() A.ChangeFont(-2) end)
local larger=button("A+",-43,function() A.ChangeFont(2) end)
local close=CreateFrame("Button",nil,drag,"UIPanelCloseButton")
close:SetPoint("TOPRIGHT",-4,-7);close:SetSize(32,32)
close:SetScript("OnClick",function() if A.DismissReader then A.DismissReader() else frame:Hide() end end)
A.increaseFont=larger
local resize=CreateFrame("Button",nil,frame)
resize:SetPoint("BOTTOMRIGHT",-3,3); resize:SetSize(24,24)
resize:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resize:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resize:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
resize:SetScript("OnMouseDown",function(_,buttonName) if buttonName=="LeftButton" then frame:StartSizing("BOTTOMRIGHT") end end)
resize:SetScript("OnMouseUp",function() frame:StopMovingOrSizing(); save() end)
frame:SetScript("OnSizeChanged",function() render(false) end)
frame:SetScript("OnHide",function() frame:StopMovingOrSizing(); save() end)
scroll:EnableMouseWheel(true)
function A.ScrollReader(pixels)
  if not frame:IsShown() then return end
  local maximum=math.max(0,content:GetHeight()-scroll:GetHeight())
  scroll:SetVerticalScroll(math.max(0,math.min(maximum,scroll:GetVerticalScroll()+pixels)))
end
scroll:SetScript("OnMouseWheel",function(_,delta) A.ScrollReader(-delta*42) end)
table.insert(UISpecialFrames,"MMNorthshireTestWindow")
function A.RestoreWindow(reset)
  local s=not reset and MMNorthshireSettings or {}
  if type(s)~="table" then s={} end
  -- Migrate oversized test-panel geometry once. Captures and text remain intact.
  if s.appearanceVersion~=2 then s={fontSize=s.fontSize} end
  manualPosition=s.manualPosition==true
  local minW,minH,maxW,maxH=limits()
  size=math.max(14,math.min(28,tonumber(s.fontSize) or 16))
  frame:SetSize(math.max(minW,math.min(maxW,tonumber(s.width) or 440)),math.max(minH,math.min(maxH,tonumber(s.height) or 560)))
  frame:ClearAllPoints()
  local points={CENTER=true,TOP=true,BOTTOM=true,LEFT=true,RIGHT=true,TOPLEFT=true,TOPRIGHT=true,BOTTOMLEFT=true,BOTTOMRIGHT=true}
  if points[s.point] and points[s.relativePoint] then
    frame:SetPoint(s.point,UIParent,s.relativePoint,tonumber(s.x) or 0,tonumber(s.y) or 0)
  else frame:SetPoint("CENTER") end
  MMNorthshireSettings=MMNorthshireSettings or {}; save(); render(false)
end
function A.ShowText(header,text,note)
  current={title=header,text=text,status=note}
  if not manualPosition and QuestFrame and QuestFrame:IsShown() then
    frame:ClearAllPoints()
    local right=QuestFrame:GetRight()
    if right and right+frame:GetWidth()+8<UIParent:GetWidth() then
      frame:SetPoint("TOPLEFT",QuestFrame,"TOPRIGHT",4,-12)
    else frame:SetPoint("RIGHT",UIParent,"RIGHT",-12,0) end
  end
  -- A hidden parent's FontString may not have usable first-frame metrics yet.
  -- Show before measuring, then reflow once after the client has laid it out.
  frame:Show(); render(true)
  local expected = current
  if C_Timer and C_Timer.After then
    C_Timer.After(0,function()
      -- Never reopen a dismissed window or redraw a superseded quest.
      if frame:IsShown() and current==expected then render(false) end
    end)
  end
end
function A.ToggleDebug()
  A.debug=not A.debug
  if A.OnDebugChanged then A.OnDebugChanged() end
  render(false)
end
