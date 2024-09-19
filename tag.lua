-- $Id: tag.lua 10365 2024-09-18 14:22:33Z cfrees $
--------------------------------------------------------------------------------
os.setenv ("PATH", "/usr/local/texlive/bin:/usr/bin:")
os.setenv ("TEXMFHOME", ".")
os.setenv ("TEXMFLOCAL", ".")
os.setenv ("TEXMFARCH", ".")
--------------------------------------------------------------------------------
-- *angen* global
tagfiles = tagfiles or {"*.dtx", "*.ins", "manifest.txt", "MANIFEST.txt", "README", "README.md"}
--------------------------------------------------------------------------------
function update_tag (file,content,tagname,tagdate)
  -- stolen from l2e build-config.lua
  local year = os.date("%Y")
  local dyddiad = os.date("%Y-%m-%d")
  if string.match(content,"%%+ +[ a-zA-Z0-9]* [Cc]opyright %([Cc]%) %d%d%d%d-%d%d%d%d Clea F%. Rees") then
    content = string.gsub(content,
    "[cC]opyright %([cC]%) (%d%d%d%d)%-%d%d%d%d Clea F%. Rees",
    "Copyright (C) %1-" .. year .. " Clea F. Rees")
  elseif string.match(content,"%%+ +[ a-zA-Z0-9]* [cC]opyright %([cC]%) %d%d%d%d Clea F%. Rees") then
    local oldyear = string.match(content,"%%+ +[a-zA-Z0-9 ]* [cC]opyright %([cC]%) (%d%d%d%d) Clea F%. Rees")
    if year ~= oldyear then
      content = string.gsub(content,
      "[cC]opyright %([cC]%) %d%d%d%d Clea F%. Rees",
      "Copyright (C) " .. oldyear .. "-" .. year .. " Clea F. Rees")
    end
  end
  if string.match (file,"%.ins$") or string.match (file,"%.txt$") or string.match (file,"%.md$")  then
    if string.match(content,"^[Cc]opyright %([cC]%) %d%d%d%d-%d%d%d%d Clea F%. Rees\n") then
      content = string.gsub(content,
      "[cC]opyright %([cC]%) (%d%d%d%d)%-%d%d%d%d Clea F%. Rees\n",
      "Copyright (C) %1-" .. year .. " Clea F. Rees\n")
    elseif string.match(content,"[cC]opyright %([cC]%) %d%d%d%d Clea F%. Rees\n") then
      local oldyear = string.match(content,"[cC]opyright %([cC]%) (%d%d%d%d) Clea F%. Rees\n")
      if year ~= oldyear then
        content = string.gsub(content,
        "[cC]opyright %([cC]%) %d%d%d%d Clea F%. Rees\n",
        "Copyright (C) " .. oldyear .. "-" .. year .. " Clea F. Rees\n")
      end
    end
  end
  local vtagname = string.gsub(tagname, "^v*(%d)", "v%1")
  tagname = string.gsub(tagname, "^v*(%d)", "%1")
  if string.match (file,"%.dtx$") and string.match(content,"\\changes%{v0%.0%}%{0000[%/%-]00[%/%-]00%}") then
    content = string.gsub(content,
    "(\\changes%{)v0%.0(%}%{)0000[%/%-]00[%/%-]00(%})", 
    "%1" .. vtagname .. "%2" .. dyddiad .. "%3")
  end
  if string.match (file,"%.dtx$") and string.match(content,"\\ProvidesPackageSVN") then
    return string.gsub (content,
    "(\\ProvidesPackageSVN%[[^%]]*%]%{%$[^%}]*%$%} *%[)v%d[%d%.]*( *\\revinfo)",
    "%1" .. vtagname .. "%2")
  end
  if string.match (file,"%.dtx$") or string.match (file,"%.ins") then
    return string.gsub (content,
    "(\\ProvidesFileSVN%{%$[^%}]*%$%} *%[)v%d[%d%.]*( *\\revinfo)",
    "%1" .. vtagname .. "%2")
  elseif string.match (file,"%.md$") or string.match (file, "README*") then
    if string.match (content,"\nVersion %d[%d%.]* *\n") then
      return string.gsub (content,
      "(\nClea F%. Rees *\nVersion )%d[%.%d]* *\n%d%d%d*[%/%-]%d%d%d*[%/%-]%d%d%d* *(\n)",
      "%1" .. tagname .. "\n" .. dyddiad .. "%2")
    else return string.gsub (content,
      "(\nClea F%. Rees *\n)%d%d%d*[%/%-]%d%d%d*[%/%-]%d%d%d* *(\n)",
      "%1Version " .. tagname .. "\n" .. dyddiad .. "%2")
    end
  end
  return content
end
--------------------------------------------------------------------------------
-- vim: ts=2:sw=2:
