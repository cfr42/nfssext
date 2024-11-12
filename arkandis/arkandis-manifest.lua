-- $Id: arkandis-manifest.lua 10612 2024-11-12 17:21:11Z cfrees $
---------------------------------------------------------------------
---------------------------------------------------------------------
-- local derivedfiles = derivedfiles or {"*.cls","*.enc","*.fd","*.map","*.sty","*.tfm","*.vf"}
-- local arkandisfiles = arkandisfiles or {"*.afm","*.otf","*.pfb",".pfm","*.ttf","NOTICE.txt","COPYING"}
-- local fnttestfiles = fnttestfiles or {"fnt-tests.tex", "fnt-test.lvt"} 
-- local buildscripts = buildscripts or  {"*.lua", "Makefile", "../arkandis/*.lua", "../../fntbuild.lua"}
-- local fnttestdir = fnttestdir or maindir .. "/fnt-tests"
-- local testfiles = testfiles or {"*.lvt","*.pvt","*.tlg","*.lve","*.tpf"}
-- local addetx = addetx or filelist(sourcefiledir,"*.etx")      
-- local addmtx = addmtx or filelist(sourcefiledir,"*.mtx")      
-- local fntmkfiles = fntmkfiles or {}
-- local fntmksrc = fntmksrc or {} 
----------------------------------------------------------------------
----------------------------------------------------------------------
-- This is WAY too complicated for what is essentially a failed attempt to list 
-- a few files!!
----------------------------------------------------------------------
----------------------------------------------------------------------
local fnttestfiles = fnttestfiles or "* fnt-tests.tex\n* fnt-test.lvt"
local fnttablestemplate = fnttablestemplate or "\n* fnt-tables.tex"
local sourcefiledir = sourcefiledir or "."
local builddir = builddir or maindir .. "/build"
local unpackdir = unpackdir or builddir .. "/unpacked"
local arkandisfiles = arkandisfiles or {"*.afm","COPYING","NOTICE","*.otf","*.pfb","*.pfm"}
local arkandisders = arkandisders or {}
local derivedfiles = derivedfiles or {}
table.insert(derivedfiles,"*-tables.tex")
----------------------------------------------------------------------
----------------------------------------------------------------------
function idxfiles(dir,globs)
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
function idxexcl(dir,files,exclfiles)
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
function idxtable(tble)
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
function bullets(items,idx)
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
function populatescripts()
  local arkandisdir = arkandisdir or maindir .. "/arkandis"
  local sourcefiledir = sourcefiledir or "."
  if buildscripts == nil then
    -- local bldscripts = {}
    local bldscripts = ""
    local possscripts = {sourcefiledir .. "/build.lua", maindir .. "/fntbuild.lua", maindir .. "/tag.lua", arkandisdir .. "/arkandis-manifest.lua"}
    for i,j in ipairs(possscripts) do
      if fileexists(j) then
        bldscripts = bldscripts .. "\n* " .. basename(j) 
        -- table.insert(bldscripts, basename(j))
      end
    end
    return bldscripts
  else
    return buildscripts
  end
end
----------------------------------------------------------------------
----------------------------------------------------------------------
function manifest_write_opening(filehandle)
  local date  = date or os.date()
  filehandle:write( "# Manifest for " .. ctanpkg .. "\n\nCopyright (C) " .. date .. " Clea F. Rees\n\n" )
  filehandle:write(
    [[This work may be distributed and/or modified under the conditions of the LaTeX
Project Public License, either version 1.3c of this license or (at your option)
any later version.  The latest version of this license is in
      https://www.latex-project.org/lppl.txt
and version 1.3c or later is part of all distributions of LaTeX version 
2008-05-04 or later.

This work has the LPPL maintenance status `maintained'.

The Current Maintainer of this work is Clea F. Rees.

This work consists of all files listed in manifest.txt.

This file lists all files released under the LPPL. It does *not* list all files
included in the package. See README for further details.

This file was automatically generated by `l3build manifest`.]]
  )
end
---------------------------------------------------------------------
-- maniwl t 36
-- manifest_sort_within_group = function(files)
--   local f = files
--   table.sort(f)
--   return f
-- end
---------------------------------------------------------------------
function manifest_setup ()
  if not ( fileexists(unpackdir .. "/" .. module .. ".sty") or fileexists(unpackdir .. "/" .. ctanpkg .. ".sty") ) then
    unpack()
  end
  local tmpfiles = tmpfiles or {"*.aux","*.log"}
  local m_allsrc = {}
  for h,i in ipairs({sourcefiles,typesetfiles,typesetsourcefiles,typesetdemofiles,fnttablestemplate}) do
    if i ~= nil then
      for j,k in ipairs(i) do
        if k ~= nil then
          m_allsrc[k] = true
        end
      end
    end
  end
  local allsrc = idxtable(m_allsrc)
  -- fnt makers
  local fntmkglobs = {"*.enc","*.etx","*.lig","*.mtx","*.nam","*.pe","*-drv.tex","*-map.tex","*-rename.tex","Makefile"}
  -- sources
  local m_sourcefiles = idxexcl(sourcefiledir,allsrc,{arkandisfiles,arkandisders,tmpfiles,derivedfiles})
  local srclist = idxtable(m_sourcefiles)
  -- source fnt makers
  local m_fntmkfiles = idxfiles(sourcefiledir,fntmkglobs)
  local fntmklist = idxtable(m_fntmkfiles)
  -- source pkg
  local m_srcpkgfiles = idxexcl(sourcefiledir,srclist,{fntmklist})
  local srcpkgfiles = idxtable(m_srcpkgfiles)
  -- generated
  local m_genfntfiles = idxexcl(keepdir,{"*.*"},arkandisders) 
  local genlist = idxtable(m_genfntfiles)
  -- derived development
  local m_devder = idxexcl(unpackdir, {"Makefile.*", "*.etx","*.lig","*.mtx","*.nam","*.pe","*-drv.tex","*-encs.tex","*-map.tex","*-tables.tex","*-auto-test*.lvt"}, {srclist, sourcefiles, typesetfiles, typesetsourcefiles, typesetdemofiles, fnttablestemplate, genlist})
  local devderlist = idxtable(m_devder)
  -- derived pkg
  local m_derfiles = idxexcl(unpackdir,{"*.*"},{sourcefiles,arkandisfiles,arkandisders,tmpfiles,devderlist})
  local derlist = idxtable(m_derfiles)
  -- text
  local m_txtfiles = idxexcl(sourcefiledir,{"README","*.md","*.txt"},arkandisfiles)
  local txtfiles = bullets(m_txtfiles,1)
  -- derived fnt makers
  -- why is it necessary to exclude derlist? w/o, I get .enc files - not all,
  -- mind, but some - but they don't match any of the patterns
  local m_derfntmk = idxexcl(unpackdir,fntmkglobs,{fntmklist,derlist})
  local derfntmklist = idxtable(m_derfntmk)
  ---------------------------------------------------------------------
  -- populate
  -- we did do more this way, but it took forever not to work
  -- the current method doesn't work a bit quicker
  local buildscripts = populatescripts()
  ---------------------------------------------------------------------
  if noautotest then fnttestfiles = "" end
  ---------------------------------------------------------------------
  -- I have no idea how to sort them (without gnu, that is)
  local groups = {
    {
      subheading = "Source files",
    },
    {
      name = "Package files",
      description = txtfiles,
      dir = sourcefiledir,
      files = srcpkgfiles,
      -- files = srclist,
      -- files = allsrc,
      -- exclude = fntmklist,
      exclude = {derivedfiles,arkandisfiles},
      -- description = txtfiles,
    },
    {
      name = "Development files",
      dir = testfiledir,
      files = {"*" .. lvtext, "*" .. lveext, "*" .. tlgext, "*" .. pvtext, "*" .. tpfext},
      description = "Note that tests containing '-auto' are automatically generated by l3build from fnt-test.lvt.\n\n" ..  fnttestfiles .. buildscripts .. bullets(m_fntmkfiles,1) .. fnttablestemplate, 
      exclude = {"*-auto-test" .. lvtext, "*-auto-test-ly1" .. lvtext},
    },
    {
      subheading = "Derived files",
    },
    -- {
    --   name = "Package files",
    --   files = {"*.cls","*.sty"},
    --   dir = unpackdir,
    --   -- description = genlist,
    -- },
    {
      name = "Package files",
      -- name = "Font files",
      -- files = {"*.enc","*.fd","*.map","*.tfm","*.vf"},
      files = {derlist},
      description = bullets(genlist,2),
      dir = unpackdir,
      -- exclude = {"*.cls","*.sty"},
      -- exclude = {"*.afm","*.otf","*.pfb",".*pfm","*.ttf","NOTICE.txt","COPYING",".",".."},
      -- description = "Inc. directly derived & generated.\n\n" .. derfntfiles,
    },
    {
      name = "Development files",
      -- files = {"Makefile.*", "*.etx","*.lig","*.mtx","*.nam","*.pe","*-drv.tex","*-map.tex"},
      files = {devderlist,derfntmklist},
      dir = unpackdir,
      -- exclude = {fntmklist},
      -- can't include buildscripts here (wrong type)
      exclude = {sourcefiles, typesetfiles, typesetsourcefiles, typesetdemofiles, fnttablestemplate, srclist,fntmklist},
    },
    {
      name = "Typeset documentation",
      -- files = {typesetfiles,typesetdemofiles},
      files = {"*.pdf"},
      dir = sourcefiledir,
      exclude = {".",".."},
      -- dir = unpackdir,
      -- rename = {"%.%w+$",".pdf"},
      description = "Note that font tables are automatically generated by l3build from fnt-tables.tex.\n",
    },
  }
  return groups
end
----------------------------------------------------------------------
---------------------------------------------------------------------
-- vim: ts=2:sw=2:tw=80:nospell:
