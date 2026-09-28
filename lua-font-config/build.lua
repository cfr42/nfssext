-- $Id: build.lua 12074 2026-09-28 17:04:10Z cfrees $
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
-- typesetdeps = {maindir .. "/nfssext-cfr", maindir .. "/cfr-lm"}
-- typesetfiles = {"*-doc.tex", "*-code.tex"}
-- local info = os.uname()
checkengines = {"luatex"}
-- 2 runs to avoid cache-creation messages in logs and ensure cache is used on
-- subsequent runs
checkruns = 2
versionpatterns = versionpatterns or {}
table.insert(versionpatterns, "SVN Rev: %d+")
table.insert(versionpatterns, "v%d+[%d%.]* %d+")
demofiles = {"example-*.tex"}
typesetexe = "lualatex"
typesetopts = "-interaction=nonstopmode -cnf-line='TEXMFHOME=.' -cnf-line='TEXMFLOCAL=.' -cnf-line='TEXMFARCH=.' -cnf-line='TEXMFCACHE=.'"
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
	license       = {"gpl2","lppl1.3c","GUST-FONT-NOSOURCE-LICENSE","SIL OFL"},
	pkg           = ctanpkg,
	summary       = "Lua-based opentype font configuration for LuaLaTeX.",
  uploader      = "Clea F. Rees",
	version       = "v0.0",
  -- optional --
	bugtracker    = {"https://codeberg.org/cfr/nfssext/issues"},
  description   = "Opentype font configuration for LuaLaTeX written primarily in Lua.\z
    Engine callbacks, LaTeX hooks and caching are used to eliminate pre-loading and minimise pre-defining.\z
    This allows very rich font families to be quicky generated, with minimal user input and no configuration files.\z
    The Lua module uses code from ConTeXt(MKIV), which incurs a short delay the first time the package is used.\z
    The aim is to auto-generate families which provide fast, easy access to multiple shapes, weights, widths etc. within a single family.\z
    The package is currently experimental and, while already usable in simpler cases, the package currently provides only a small part of fontspec's functionality.\z
    Multi-lingual typesetting, variable fonts, spot colours etc. are not (yet?) supported and the user interface is extremely rudimentary.",
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
-- vim: ts=2:sw=2:tw=80:nospell
