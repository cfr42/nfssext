-- $Id: build.lua 12082 2026-09-30 02:01:40Z cfrees $
-------------------------------------------------------------------------------
-- This work, which consists of all files listed in manifest.txt, is released 
-- under the LaTeX Project Public Licence version 1.3c or later. See individual 
-- files for details.
-------------------------------------------------------------------------------
-- Build configuration for lua-font-config
-- l3build.pdf listing 1 tudalen 9
-------------------------------------------------------------------------------
module = "lua-font-config"
ctanpkg = "lua-font-config"
-- maindir **must** be shared with dependencies
-- but don't make lua-font-config a dependency or dependant
maindir = ".."
sourcefiledir = "."
sourcefiles = {"*.dtx", "*.ins", "lua-font-config.lua", "lfc*.lua"}
manifestfile = "manifest.txt"
installfiles = {"lua-font-config.lua", "lfc*.lua", "*.sty"}
-- local info = os.uname()
checkengines = {"luatex"}
-- 2 runs to avoid cache-creation messages in logs and ensure cache is used on
-- subsequent runs
checkruns = 2
checkopts = "-interaction=nonstopmode -cnf-line='TEXMFHOME=.' -cnf-line='TEXMFLOCAL=.' -cnf-line='TEXMFARCH=.' -cnf-line='TEXMFCACHE=.'"
versionpatterns = versionpatterns or {}
table.insert(versionpatterns, "SVN Rev: %d+")
table.insert(versionpatterns, "v%d+[%d%.]* %d+")
-- ignored if unpacked
-- demofiles = {"example-*.tex"}
-- typesetdeps = {maindir .. "/nfssext-cfr", maindir .. "/cfr-lm"}
-- typesetfiles = {"*-doc.tex", "*-code.tex"}
-- typesetfiles = {"*.tex", "*.dtx"}
typesetexe = "lualatex"
typesetopts = "-interaction=nonstopmode -cnf-line='TEXMFHOME=.' -cnf-line='TEXMFLOCAL=.' -cnf-line='TEXMFARCH=.'"
-- typesetruns = 5
--
-- docfiles = filelist(sourcefiledir,"fntbuild-*.lua")
-- table.insert(docfiles,"fntbuild.lua")
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
  local groups = {
    {
      subheading = "Source files",
    },
    {
      name = "Package files",
      dir = sourcefiledir,
      files = {"*.dtx","*.ins","*.lua","*.md"},
      exclude = {derivedfiles},
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
      name = "Typeset documentation",
      -- files = {typesetfiles,typesetdemofiles},
      files = {"*.pdf"},
      excludefiles = {".",".."},
      dir = sourcefiledir,
      -- rename = {"%.%w+$",".pdf"},
    },
  }
  return groups
end
-- see if this helps ...
packtdszip = true
tdslocations  = {
  "doc/lualatex/lua-font-config/*.md",
  "doc/lualatex/lua-font-config/*.pdf",
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
	license       = {"gpl2","lppl1.3c","SIL OFL"},
	pkg           = ctanpkg,
	summary       = "Lua-based opentype font configuration for LuaLaTeX.",
  uploader      = "Clea F. Rees",
	version       = "v0.0",
  -- optional --
	bugtracker    = {"https://codeberg.org/cfr/nfssext/issues"},
  description   = "Fast and simple opentype font configuration for LuaLaTeX.\z
    Aims to auto-generate families efficiently, providing easy access to the multiple shapes, weights, widths and features provided by many of today's fonts.\z
    Engine callbacks, LaTeX hooks and caching are used to eliminate pre-loading, reduce lookups and minimise pre-defining.\z
    This allows very rich font families to be quicky generated, with minimal user input and zero configuration files.\z
    The core code consists of two Lua modules: the first is taken as-is from ConTeXt (MKIV); the second provides a LaTeX interface for lookups and constructs NFSS families from the returned data.\z
    The package is highly experimental and, while already usable in many cases, currently provides only a small part of fontspec's functionality.\z
    Implemented features include configuration of the main document font families (roman, sans, typewriter), use of these families in maths mode, creation of additional families (text mode) and support for Unicode maths (using lua-unicode-math).\z
    Missing features include support for multi-lingual typesetting, variable fonts, spot colours etc. and an extremely rudimentary user interface.",
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
-------------------------------------------------------------------------------
-- workaround docstrip deficiency
function docinit_hook()
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

  files = filelist(unpackdir, "example*.tex")
  for _,f in ipairs(files) do 
    cp(f, unpackdir, typesetdir) 
    assert(tex(f, typesetdir))
    assert(cp((gsub(f, "%.tex$", ".pdf")), typesetdir, sourcefiledir))
  end

  return 0
end
-------------------------------------------------------------------------------
-- vim: ts=2:sw=2:tw=80:nospell
