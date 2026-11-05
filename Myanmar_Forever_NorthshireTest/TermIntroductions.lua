-- Concise term meanings are learned per character only after a visible live render.
-- Catalog/font generation owns every label. This module never changes prose.
local _, A = ...
local T = {}
A.TermIntroductions = T
local contextID, contextStage, active

function T.Restore()
  local saved = MMNorthshireTermSeen
  if type(saved)~="table" or saved.version~=1 or type(saved.seen)~="table" then
    saved={version=1,seen={}}
    MMNorthshireTermSeen=saved
  end
  return saved
end
function T.Invalidate()
  contextID,contextStage,active=nil,nil,nil
end
function T.SetContext(id,stage)
  if stage=="log" then stage="detail" end
  if contextID~=id or contextStage~=stage then
    contextID,contextStage,active=id,stage,nil
  end
end
local function copySeen(source)
  local result={}
  for key,value in pairs(source or {}) do if value==true then result[key]=true end end
  return result
end
local function identitySignature(identities)
  local result={}
  for _,kind in ipairs({"class","race","priest"}) do
    local record=identities[kind] or {}
    for _,field in ipairs({"en","full","termKey"}) do
      local value=record[field] or ""
      result[#result+1]=#value..":"..value
    end
  end
  return table.concat(result,"|")
end
local function bare(short)
  return (short or ""):match("^(.-)%s*%(") or short
end
local function boundary(text,first,last)
  -- A known label cannot be the suffix of a longer English name, such as
  -- "Elder Warrior (...)". Source Myanmar surrounding it is not word syntax.
  local before=text:sub(1,first-1):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
  local after=text:sub(last+1):gsub("^|r","")
  return not before:match("[%w_'%-][ \t]*$") and not after:match("^[%w_]")
end
local function fieldExcluded(id,field,key,alias)
  local fields=A.termFieldExceptions and A.termFieldExceptions[id]
  local excluded=fields and fields[field]
  if excluded and excluded[key] then return true end
  local exceptions=alias and alias.excludedFields
  return exceptions and (exceptions[tostring(id)..":"..field] or exceptions[field])
end
local function buildAliases()
  local buckets,exact={},{}
  for _,alias in ipairs(A.termAliases or {}) do
    if type(alias.text)=="string" and alias.text~="" then
      local first=alias.text:sub(1,1)
      buckets[first]=buckets[first] or {}
      buckets[first][#buckets[first]+1]=alias
      exact[alias.text]=alias
    end
  end
  for _,list in pairs(buckets) do
    table.sort(list,function(a,b)
      if #a.text~=#b.text then return #a.text>#b.text end
      if a.text~=b.text then return a.text<b.text end
      return (a.key or "")<(b.key or "")
    end)
  end
  return buckets,exact
end

-- Fields arrive in display order. Identity values are resolved before this
-- scan, but names and all generated labels are inserted once and never scanned.
function T.Prepare(id,stage,preview,fields,identities)
  identities=identities or {}
  local saved=T.Restore()
  local signature=identitySignature(identities)
  local snapshot
  if preview then
    snapshot={learned={}}
  else
    T.SetContext(id,stage)
    if not active or active.saved~=saved or active.seen~=saved.seen or active.signature~=signature then
      active={saved=saved,seen=saved.seen,signature=signature,learned=copySeen(saved.seen)}
    end
    snapshot=active
  end
  local introduced,viewSeen={},{}
  local buckets,exact=buildAliases()
  local results={}
  for index,entry in ipairs(fields) do
    local text=type(entry)=="table" and entry.text or entry
    local field=type(entry)=="table" and entry.field or tostring(index)
    local fieldSeen={}
    local function label(record,alias,dynamic)
      local key=record.termKey or record.key
      local canonical=key and A.termGlossary and A.termGlossary[key]
      local short=record.full or record.short or (canonical and canonical.short) or record.en
      local intro=record.intro or (canonical and canonical.intro) or short
      local en=record.en or bare(short)
      if not key or not canonical then return short or en or "?" end
      if not dynamic and fieldExcluded(id,field,key,alias) then return alias and alias.text or short end
      if fieldSeen[en] then return en end
      fieldSeen[en]=true
      if not viewSeen[key] then
        viewSeen[key]=true
        if not snapshot.learned[key] then introduced[key]=true;return intro end
      end
      return short
    end
    local pieces,at,start={},1,1
    while at<=#text do
      local replacement,last
      if text:sub(at,at)=="<" then
        local marker=text:sub(at):match("^<([a-zA-Z/]+)>")
        if marker then
          local lower=marker:lower()
          if lower=="name" then replacement=identities.name or "?"
          elseif lower=="class" or lower=="race" then
            replacement=label(identities[lower] or {en="?"},nil,true)
          elseif lower=="priest/priestess" then
            local priest=identities.priest or {en="?"}
            local alias=exact[priest.full or priest.en]
            replacement=label(alias or priest,alias,true)
          end
          if replacement then last=at+#marker+1 end
        end
      end
      if not replacement then
        for _,alias in ipairs(buckets[text:sub(at,at)] or {}) do
          local finish=at+#alias.text-1
          if text:sub(at,finish)==alias.text and boundary(text,at,finish) then
            replacement=label(alias,alias);last=finish;break
          end
        end
      end
      if replacement then
        pieces[#pieces+1]=text:sub(start,at-1)
        pieces[#pieces+1]=replacement
        at=last+1;start=at
      else at=at+1 end
    end
    pieces[#pieces+1]=text:sub(start)
    results[index]=table.concat(pieces)
  end
  local committed=false
  local function commit()
    if preview or committed or active~=snapshot or MMNorthshireTermSeen~=saved or saved.version~=1 or saved.seen~=snapshot.seen then return end
    committed=true
    for key in pairs(introduced) do saved.seen[key]=true end
  end
  return results,commit
end
