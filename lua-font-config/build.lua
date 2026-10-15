-- $Id: build.lua 12125 2026-10-15 04:05:25Z cfrees $
--------------------------------------------------------------------------------
-- This package combines files released under distinct licences. 
--
-- lfc-context-font-syn.lua is a simple copy of context-font-syn.lua and
-- released under GPL v2, in accordance with the original licence. It is 
-- included for convenience, so that the package may be used without installing
-- ConTeXt.
--
-- The work itself, which consists of all files listed in manifest.txt, is 
-- released under the LaTeX Project Public Licence version 1.3c or later. See
-- individual files for details.
--------------------------------------------------------------------------------
-- Build configuration for lua-font-config
-- l3build.pdf listing 1 tudalen 9
--------------------------------------------------------------------------------
-- Why does this end up copying fontscripts in as a dependency when typesetting?
--------------------------------------------------------------------------------
module = "lua-font-config"
ctanpkg = module
-- maindir **must** be shared with dependencies
-- But don't make lua-font-config a dependency or dependant. <-- Doesn't work.
maindir = ".."
sourcefiledir = "."
sourcefiles = {"*.dtx", "*.ins", "lua-font-config.lua", "lfc-context-font-syn.lua"}
-- excludefiles = {"scratch.lua", "lfc-fea-lookup.lua"}
manifestfile = "manifest.txt"
installfiles = {"lua-font-config.lua", "lfc-context-font-syn.lua", "*.sty"}
checkengines = {"luatex"}
-- 2 runs to avoid cache-creation messages in logs and ensure cache is used on
-- subsequent runs.
checkruns = 2
checkopts = "-interaction=nonstopmode -cnf-line='TEXMFHOME=.' -cnf-line='TEXMFLOCAL=.' -cnf-line='TEXMFARCH=.' -cnf-line='TEXMFCACHE=.'"
-- checkconfigs = {"build", "config-once"}
excludetests = {"test-msg"}
versionpatterns = versionpatterns or {}
table.insert(versionpatterns, "SVN Rev: %d+")
table.insert(versionpatterns, "v%d+[%d%.]* %d+")
-- ignored if unpacked
-- demofiles = {"example-*.tex"}
typesetexe = "lualatex"
typesetopts = "-interaction=nonstopmode -cnf-line='TEXMFHOME=.' -cnf-line='TEXMFLOCAL=.' -cnf-line='TEXMFARCH=.'"
date = "2026"
if fileexists(maindir .. "tag.lua") then
  dofile(maindir .. "/tag.lua")
elseif direxists(sourcefiledir .. "/../../adnoddau/l3build") then
  dofile(sourcefiledir .. "/../../adnoddau/l3build/tag.lua")
end
if fileexists(maindir .. "/manifest.lua") then
  dofile(maindir .. "/manifest.lua")
elseif direxists(sourcefiledir .. "/../../adnoddau/l3build") then
  dofile(sourcefiledir .. "/../../adnoddau/l3build/manifest.lua")
end
function manifest_setup ()
  unpack()
  local devfiles = {}
  local t = {testfiledir, sourcefiledir .. "/testfiles-once"}
  for _,curr in ipairs(t) do 
    for item in lfs.dir(curr) do
      local attr = lfs.attributes(curr .. "/" .. item, "mode")
      if attr == "file" then
        table.insert(devfiles, item)
      elseif attr == "directory" and item ~= "." and item ~= ".." then
        for this in lfs.dir(curr .. "/" .. item) do
          if lfs.attributes(curr .. "/" .. item .. "/" .. this, "mode") == "file" then
            table.insert(devfiles, this)
          end
        end
      end
    end
  end
  local groups = {
    {
      subheading = "Source files",
    },
    {
      name = "Package files",
      dir = sourcefiledir,
      files = {"*.dtx","*.ins","lua-font-config.lua","*.md"},
      exclude = {derivedfiles,excludefiles},
      description= "** NB lfc-context-font-syn.lua NOT included here **\n"
    },
    {
      name = "Development files",
      files = {"build.lua", "config-once.lua"},
      dir = sourcefiledir,
      description = "* " .. table.concat(devfiles, "\n* ")
    },
    {
      subheading = "Derived files",
    },
    {
      name = "Package files",
      dir = unpackdir,
      files = {"*.cls","*.sty"},
      exclude = sourcefiles,
      description = "* manifest.txt",
    },
    { 
      name = "Example files",
      dir = unpackdir,
      files = {"example-*.tex"},
    },
    {
      name = "Typeset documentation",
      files = typesetfiles,
      excludefiles = {".",".."},
      dir = sourcefiledir,
      rename = {"%.%w+$",".pdf"},
    },
  }
  return groups
end
-- see if this helps ...
packtdszip = true
tdslocations  = {
  "doc/lualatex/lua-font-config/*.md",
  "doc/lualatex/lua-font-config/*.pdf",
  "doc/lualatex/lua-font-config/example-*.tex",
  "doc/lualatex/lua-font-config/example-*.pdf",
  "doc/lualatex/lua-font-config/*.txt",
  "source/lualatex/lua-font-config/*.dtx",
  "source/lualatex/lua-font-config/*.ins",
  "tex/lualatex/lua-font-config/*.sty",
  "tex/lualatex/lua-font-config/*.lua",
}
unpackexe = "pdftex"
--
uploadconfig = {
  -- *required* --
  -- announcement (don't include here?)
	author        = "Clea F. Rees",
  -- email (don't include here!)
	ctanPath      = "/tex/lualatex/lua-font-config",
	license       = {"gpl2","lppl1.3c"}, -- "SIL OFL"}, -- SIL OFL only applies to the .ttc, which isn't intended for CTAN
	pkg           = ctanpkg,
	summary       = "Lua-based opentype font configuration for LuaLaTeX.",
  uploader      = "Clea F. Rees",
	version       = "v0.0",
  -- optional --
	bugtracker    = {"https://codeberg.org/cfr/nfssext/issues"},
  description   = "Fast and simple opentype font configuration for LuaLaTeX.\z
    Efficient auto-generation of font families providing easy access to the multiple shapes, weights, widths and features provided by many of today's fonts.\z
    Engine callbacks, LaTeX hooks and caching are used to eliminate pre-loading, reduce lookups and minimise pre-defining.\z
    This allows very rich font families to be quicky generated, with minimal user input and zero configuration files.\z
    The core code consists of two Lua modules: one taken as-is from ConTeXt (MKIV) and one providing the LaTeX interface and data processing.\n\n\z
    The package is experimental and, while already usable in many cases, currently(?) provides only a small part of fontspec's functionality.\z
    Implemented features include configuration of the main document font families (roman, sans, typewriter), use of these families in maths mode, creation of additional families (text mode) and support for Unicode maths (via lua-unicode-math).\z
    Missing features include support for multi-lingual typesetting, variable fonts, spot colours etc. and a user interface beyond the rudimentary.",
  -- development {}
  -- home {}
	-- note          = "",
	repository    = {"https://codeberg.org/cfr/nfssext", "https://github.com/cfr42/nfssext"},
  -- support {}
	topic         = {"font-mgmt", "font-sel", "font-use", "luatex", "tagged-pdf"},
	update        = false,
  -- files --
  -- announcement_file
  -- note_file
  -- curlopt_file
}
--------------------------------------------------------------------------------
function docinit_hook()
  -- Work around docstrip deficiency.
  local find, gsub = string.find, string.gsub
  local insert = table.insert
  local amp = "A!M!P!E!R!S!A!N!D_R!E!P!L!A!C!E!M!E!N!T"
  local mod = "__lfc"
  local files 

  files = filelist(typesetdir, "*.dtx")
  for _,f in ipairs(files) do 
    print(f)
    local t = {}
    for line in io.lines(f) do
      if not find(line, "^%%<@@") then
        -- Recipe from docstrip.
        -- 1. First, deal with @@@@ as a special case (by using a temporary disguise).
        line = (gsub(line, "@@@@", amp))
        -- 2. Then change all __@@ to __⟨module⟩.
        -- 3. Then change all remaining _@@ to __⟨module⟩.
        -- 4. Then change all remaining @@ to __⟨module⟩.
        line = (gsub(line, "_?_?@@", mod))
        -- 5. Finally, tidy up by changing each “disguised @@@@” to @@.
        line = (gsub(line, amp, "@@"))
      end
      insert(t, line)
    end
    -- Don't zap the source, please!
    local out = io.open(typesetdir .. "/" .. f, "w")
    out:write(table.concat(t, "\n"))
    out:close()
  end

  -- Work around l3build deficiency/designed limitation/feature.
  files = filelist(unpackdir, "example*.tex")
  for _,f in ipairs(files) do 
    local modf = "mod-" .. f
    cp(f, unpackdir, typesetdir) 
    local t = {}
    local dc = false
    for line in io.lines(typesetdir .. "/" .. f) do
      if not find(line, "^%%") then
        if not dc and find(line, "\\documentclass{article}") then
          dc = true
          insert(t, "\\documentclass[varwidth,border=2.5pt]{standalone}")
        elseif not dc and find(line, "\\documentclass{ltx-talk}") then
          dc = true
          insert(t, line)
        else
          insert(t, line)
        end
      end
    end
    local mf = io.open(typesetdir .. "/" .. modf, "w")
    assert(mf)
    mf:write(table.concat(t, "\n"))
    mf:close()
    -- This doesn't typeset the talk one enough, but it doesn't matter here.
    -- We just don't include the final page.
    assert(tex(modf, typesetdir))
    local mpf, pf = (gsub(modf, "%.tex$", ".pdf")), (gsub(f, "%.tex$", ".pdf"))
    assert(ren(typesetdir, mpf, pf))
  end

  return 0
end
--------------------------------------------------------------------------------
local kpse_texmfdist = (string.gsub(kpse.expand_var("$TEXMFDIST"), "%-", "%%-"))
function normalize_log_hook(line)
  return (string.gsub(line, kpse_texmfdist, "TEXMFDIST"))
end
--------------------------------------------------------------------------------
-- vim: ts=2:sw=2:tw=80:nospell
