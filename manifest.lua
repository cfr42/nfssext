-- $Id: manifest.lua 10839 2025-02-21 06:54:34Z cfrees $
---------------------------------------------------------------------
-- paid â defnyddio am packages arkandis - gweler arkandis-manifest.lua yn lle
-- y ffeil hwn
-- dim yn addas ar gyfer ffontiau yn gyffredinol
-- local derivedfiles = derivedfiles or {"*.cls", "*.sty"}
-- local buildscripts = buildscripts or  {"*.lua", "Makefile"}
-- local testfiles = testfiles or {"*.lvt","*.pvt","*.tlg","*.lve","*.tpf"}
----------------------------------------------------------------------
----------------------------------------------------------------------
local sourcefiledir = sourcefiledir or "."
local builddir = builddir or maindir .. "/build"
local unpackdir = unpackdir or builddir .. "/unpacked"
local derivedfiles = derivedfiles or {}
----------------------------------------------------------------------
----------------------------------------------------------------------
local function idxfiles(dir,globs)
  local m_files = {}
  globs = globs or {"*.*"}
  local t = {}
  for i,j in ipairs(globs) do
    if type(j) == "table" then
      for k, l in ipairs(j) do
        if l ~= nil then
          table.insert(t,l)
        end
      end
    else
      table.insert(t,j)
    end
  end
  for i,j in ipairs(t) do
    for k,l in ipairs(ordered_filelist(dir,j)) do
      m_files[l] = true
    end
  end
  m_files["."] = nil
  m_files[".."] = nil
  return m_files
end
----------------------------------------------------------------------
local function idxexcl(dir,files,exclfiles)
  local m_files = idxfiles(dir,files)
  local tmpt = {}
  if exclfiles ~= nil then
    for i,j in ipairs(exclfiles) do
      if type(j) == "table" then
        for k,l in ipairs(j) do
          if l ~= nil then
            table.insert(tmpt,l)
          end
        end
      else
        table.insert(tmpt,j)
      end
    end
    for i,j in ipairs(tmpt) do
      jfiles = ordered_filelist(dir,j)
      if jfiles ~= nil then
        for k,l in ipairs(jfiles) do
          m_files[l] = nil
        end
      end
    end
  end
  return m_files
end
----------------------------------------------------------------------
local function idxtable(tble)
  local t = {}
  for i,j in pairs(tble) do
    table.insert(t,i)
  end
  return t
end
----------------------------------------------------------------------
----------------------------------------------------------------------
-- concatenating strings is slow
-- concatenating tables is fast
-- https://www.lua.org/pil/11.6.html
local function bullets(items,idx)
  local bulleted = {}
  local first = true
  -- table.insert(bulleted,"")
  idx = idx or 2
  if idx == 1 then
    for i,j in pairs(items) do
      if first then
        table.insert(bulleted,"\n* " .. i)
        first = false
      else
        table.insert(bulleted,i)
      end
    end
  else
    for i,j in ipairs(items) do
      if first then
        table.insert(bulleted,"\n* " .. j)
        first = false
      else
        table.insert(bulleted,j)
      end
    end
  end
  return table.concat(bulleted,"\n* ")
end
----------------------------------------------------------------------
----------------------------------------------------------------------
local function populatescripts()
  local sourcefiledir = sourcefiledir or "."
  if buildscripts == nil then
    -- local bldscripts = {}
    local bldscripts = ""
    -- should really match on *.lua and whatever here?
    local possscripts = {sourcefiledir .. "/build.lua", sourcefiledir .. "/manifest.lua", sourcefiledir .. "/tag.lua", maindir .. "/tag.lua"}
    for i,j in ipairs(possscripts) do
      if fileexists(j) then
        bldscripts = bldscripts .. "\n* " .. basename(j) 
      end
    end
    if fileexists(sourcefiledir .. "/build.lua") then
      -- local f=assert(io.open(sourcefiledir .. "/build.lua","rb"))
      for line in io.lines(sourcefiledir .. "/build.lua") do
        if string.match(line,"dofile%(") then
          local tmpbscr = string.gsub(line,"^.*dofile%(.*/(.*%.lua).*","%1")
          bldscripts = bldscripts .. "\n* " .. tmpbscr
        end
      end
    else
      print("Could not find build.lua!\n")
      return 1
    end
    return bldscripts
  else
    return buildscripts
  end
end
----------------------------------------------------------------------
----------------------------------------------------------------------
-- override l3build
function manifest_write_opening(filehandle)
  local date  = date or os.date()
  filehandle:write( "# Manifest for " .. ctanpkg .. "\n\nCopyright (C) " .. date .. " Clea F. Rees\n\n" )
  filehandle:write(
    [[This work may be distributed and/or modified under the conditions of the LaTeX
Project Public License, either version 1.3c of this license or (at your option)
any later version.  The latest version of this license is in
      https://www.latex-project.org/lppl.txt
and version 1.3 or later is part of all distributions of LaTeX version 
2008-05-04 or later.

This work has the LPPL maintenance status `maintained'.

The Current Maintainer of this work is Clea F. Rees.

This work consists of all files listed in manifest.txt.

This file was automatically generated by `l3build manifest`.]]
  )
end
---------------------------------------------------------------------
-- override l3build
function manifest_setup ()
  bundleunpack({sourcefiledir,testfiledir})
  local tmpfiles = tmpfiles or {"*.aux","*.log"}
  local m_allsrc = {}
  for h,i in ipairs({sourcefiles,typesetfiles,typesetsourcefiles,typesetdemofiles}) do
    if i ~= nil then
      for j,k in ipairs(i) do
        if k ~= nil then
          m_allsrc[k] = true
        end
      end
    end
  end
  local allsrc = idxtable(m_allsrc)
  -- sources
  local m_sourcefiles = idxexcl(sourcefiledir,allsrc,{tmpfiles,derivedfiles})
  local srclist = idxtable(m_sourcefiles)
  -- source pkg
  local m_srcpkgfiles = idxexcl(sourcefiledir,srclist)
  local srcpkgfiles = idxtable(m_srcpkgfiles)
  -- additional test sources
  local m_srcchksuppfiles = idxexcl(testsuppdir,checksuppfiles,{".",".."})
  local srcchksuppfiles = bullets(m_srcchksuppfiles,1)
  -- derived development
  local m_devder = idxexcl(unpackdir, {srclist, sourcefiles, typesetfiles, typesetsourcefiles, typesetdemofiles})
  local devderlist = idxtable(m_devder)
  -- derived pkg
  local m_derfiles = idxexcl(unpackdir,{"*.*"},{sourcefiles,tmpfiles,devderlist})
  local derlist = idxtable(m_derfiles)
  -- text
  local m_txtfiles = idxexcl(sourcefiledir,{"README","*.md","*.txt"},arkandisfiles)
  local txtfiles = bullets(m_txtfiles,1)
  ---------------------------------------------------------------------
  -- populate
  -- we did do more this way, but it took forever not to work
  -- the current method doesn't work a bit quicker
  local buildscripts = populatescripts()
  ---------------------------------------------------------------------
  local moretests = moretests or ""
  if checkconfigs[1] ~= nil then
    local cadwcheckdeps = checkdeps
    local cadwcheckfiles = checkfiles
    local cadwcheckruns = checkruns
    local cadwchecksuppfiles = checksupfiles
    local cadwtestfiledir = testfiledir
    for x,y in ipairs(checkconfigs) do
      if y ~= "build" then
        buildscripts = buildscripts .. "\n* " .. y .. ".lua"
        dofile(y .. ".lua")
        local m_moretests = idxexcl(testfiledir,{"*.*"},{".",".."})
        moretests = moretests .. bullets(m_moretests,1)
        -- local moretests = idxtable(m_moretests)
      end
    end
    checkdeps = cadwcheckdeps
    checkfiles = cadwcheckfiles
    checkruns = cadwcheckruns
    checksuppfiles = cadwchecksuppfiles
    testfiledir = cadwtestfiledir
  end
  ---------------------------------------------------------------------
  -- I have no idea how to sort them (without gnu, that is)
  local groups = {
    {
      subheading = "Source files",
    },
    {
      name = "Package files",
      dir = sourcefiledir,
      files = {bibfiles,sourcefiles,typesetfiles,typesetsourcefiles,typesetdemofiles},
      exclude = {derivedfiles},
      description = txtfiles,
    },
    {
      name = "Development files",
      dir = testfiledir,
      files = {"*" .. lvtext, "*" .. lveext, "*" .. tlgext, "*" .. pvtext, "*" .. tpfext, "*.dtx", "*.ins"},
      description = buildscripts .. srcchksuppfiles .. moretests, 
      -- exclude = {ctanpkg .. "-test.lvt", module .. "-test.lvt"},
    },
    {
      subheading = "Derived files",
    },
    {
      name = "Package files",
      files = {"*.cls","*.sty","*.tex"},
      dir = unpackdir,
      exclude = {sourcefiles,typesetsourcefiles,typesetfiles,typesetdemofiles},
      -- description = derfiles,
    },
    {
      name = "Development files",
      dir = unpackdir,
      files = {"*" .. lvtext, "*" .. lveext, "*" .. tlgext, "*" .. pvtext, "*" .. tpfext},
      exclude = {sourcefiles,checksuppfiles},
      -- exclude = {ctanpkg .. "-test.lvt", module .. "-test.lvt"},
    },
    {
      name = "Typeset documentation",
      files = {typesetfiles,typesetdemofiles,textfiles},
      excludefiles = {".",".."},
      dir = typesetdir,
      rename = {"%.%w+$",".pdf"},
    },
  }
  return groups
end
---------------------------------------------------------------------
-- pwrpas? 
function manifest_write_group_file(filehandle,filename,param)
  filehandle:write("* " .. filename .. "\n")
end
---------------------------------------------------------------------
---------------------------------------------------------------------
-- vim: ts=2:sw=2:tw=80:nospell:
