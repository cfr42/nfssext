-- $Id: tag.lua 12063 2026-09-22 23:49:55Z cfrees $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- *angen* global
tagfiles = tagfiles or {"*.dtx", "*.ins", "manifest.txt", "MANIFEST.txt", "README", "README.md"}
local find, gsub, match = string.find, string.gsub, string.match
--------------------------------------------------------------------------------
function update_tag (file,content,tagname,tagdate)
  -- stolen from l2e build-config.lua
  local year = os.date("%Y")
  local dyddiad = os.date("%Y-%m-%d")
  if find(content,"%%+ +[ a-zA-Z0-9]* [Cc]opyright %([Cc]%) %d%d%d%d-%d%d%d%d Clea F%. Rees") then
    content = gsub(content,
    "[cC]opyright %([cC]%) (%d%d%d%d)%-%d%d%d%d Clea F%. Rees",
    "Copyright (C) %1-" .. year .. " Clea F. Rees")
  elseif find(content,"%%+ +[ a-zA-Z0-9]* [cC]opyright %([cC]%) %d%d%d%d Clea F%. Rees") then
    local oldyear = match(content,"%%+ +[a-zA-Z0-9 ]* [cC]opyright %([cC]%) (%d%d%d%d) Clea F%. Rees")
    if year ~= oldyear then
      content = gsub(content,
      "[cC]opyright %([cC]%) %d%d%d%d Clea F%. Rees",
      "Copyright (C) " .. oldyear .. "-" .. year .. " Clea F. Rees")
    end
  end
  if find (file,"%.ins$") or find (file,"%.txt$") or find (file,"%.md$")  then
    if find(content,"^[Cc]opyright %([cC]%) %d%d%d%d-%d%d%d%d Clea F%. Rees\n") then
      content = gsub(content,
      "[cC]opyright %([cC]%) (%d%d%d%d)%-%d%d%d%d Clea F%. Rees\n",
      "Copyright (C) %1-" .. year .. " Clea F. Rees\n")
    elseif find(content,"[cC]opyright %([cC]%) %d%d%d%d Clea F%. Rees\n") then
      local oldyear = match(content,"[cC]opyright %([cC]%) (%d%d%d%d) Clea F%. Rees\n")
      if year ~= oldyear then
        content = gsub(content,
        "[cC]opyright %([cC]%) %d%d%d%d Clea F%. Rees\n",
        "Copyright (C) " .. oldyear .. "-" .. year .. " Clea F. Rees\n")
      end
    end
  end
  local vtagname = gsub(tagname, "^v*(%d)", "v%1")
  tagname = gsub(tagname, "^v*(%d)", "%1")
  if find (file,"%.dtx$") then
    -- if neither date nor version
    if find(content,"\\changes%{v0%.0%}%{0000[%/%-]00[%/%-]00%}") then
      content = gsub(content,
      "(\\changes%{)v0%.0(%}%{)0000[%/%-]00[%/%-]00(%})", 
      "%1" .. vtagname .. "%2" .. dyddiad .. "%3")
    end
    -- if date specified but not version
    if find(content,"\\changes%{v0%.0%}") then
      content = gsub(content,
      "(\\changes%{)v0%.0(%}%{)", "%1" .. vtagname .. "%2")
    end
    if find(content,"\\ProvidesPackageSVN") then
      content = gsub (content,
      "(\\ProvidesPackageSVN%[[^%]]*%]%{%$[^%}]*%$%} *%[)v%d[%d%.]*( *\\revinfo)",
      "%1" .. vtagname .. "%2")
    end
  end
  if find (file,"%.dtx$") or find (file,"%.ins") then
    return gsub (content,
    "(\\ProvidesFileSVN%{%$[^%}]*%$%} *%[)v%d[%d%.]*( *\\revinfo)",
    "%1" .. vtagname .. "%2")
  elseif find (file,"%.md$") or find (file, "README*") then
    if find (content,"\nVersion %d[%d%.]* *\n") then
      return gsub (content,
      "(\nClea F%. Rees *\nVersion )%d[%.%d]* *\n%d%d%d*[%/%-]%d%d%d*[%/%-]%d%d%d* *(\n)",
      "%1" .. tagname .. "\n" .. dyddiad .. "%2")
    else return gsub (content,
      "(\nClea F%. Rees *\n)%d%d%d*[%/%-]%d%d%d*[%/%-]%d%d%d* *(\n)",
      "%1Version " .. tagname .. "\n" .. dyddiad .. "%2")
    end
  end
  return content
end
--------------------------------------------------------------------------------
-- vim: ts=2:sw=2:
