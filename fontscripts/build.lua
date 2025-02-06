-- $Id: build.lua 10776 2025-02-06 02:43:08Z cfrees $
-------------------------------------------------------------------------------
-- This work, which consists of all files listed in manifest.txt, is released 
-- under the LaTeX Project Public Licence version 1.3c or later. See individual 
-- files for details.
-------------------------------------------------------------------------------
-- Build configuration for fontscripts
-- l3build.pdf listing 1 tudalen 9
-------------------------------------------------------------------------------
module = "fontscripts"
ctanpkg = "fontscripts"
-- maindir **must** be shared with dependencies
-- but don't make fontscripts a dependency or dependant
maindir = ".."
sourcefiledir = "."
sourcefiles = {"*.dtx", "*.ins"}
installfiles = {"*.etx", "*.mtx", "*.lvt", "fnt-*.tex"}
manifestfile = "manifest.txt"
scriptfiles = {"*.lua"}
typesetdeps = {maindir .. "/nfssext-cfr", maindir .. "/cfr-lm"}
typesetfiles = {"*-doc.tex", "*-code.tex"}
typesetruns = 5
--
docfiles = filelist(sourcefiledir,"fntbuild-*.lua")
table.insert(docfiles,"fntbuild.lua")
-- there must be a variable I can set for this!
function docinit_hook()
  for _,i in ipairs(docfiles) do
    local errorlevel = cp(i,sourcefiledir,typesetdir)
    if not errorlevel == 0 then
      print("Could not copy " .. i .. " from " .. sourcefiledir .. " to " .. typesetdir .. ".")
      return 1
    end
  end
  local errorlevel = cp("build.lua",maindir .. "/arkandis/berenisadf",typesetdir)
  if errorlevel == 0 then
    errorlevel = ren(typesetdir,"build.lua","berenis-build.lua")
    if errorlevel ~= 0 then 
      print("Could not rename berenisadf's build.lua to berenis-build.lua in " ..  typesetdir .. ".")
      return 1
    end
  else
    print("Could not copy " .. maindir .. "/arkandis/berenisadf/build.lua to " .. typesetdir .. ".")
    return 1
  end
  return 0
end
date = "2024-2025"
if direxists(sourcefiledir .. "/../../adnoddau/l3build") then
  dofile(maindir .. "/tag.lua")
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
      files = {"*.dtx","*.ins","fntbuild.lua","fntbuild-*.lua","*.md"},
      exclude = {derivedfiles},
    },
    {
      subheading = "Derived files",
    },
    {
      name = "Package files",
      dir = unpackdir,
      files = {"*.cls","*.etx","fnt-test.lvt","*.mtx","*.sty","*.tex","*.txt"},
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
  "doc/latex/fontscripts/*.md",
  "doc/latex/fontscripts/*.pdf",
  "doc/latex/fontscripts/*.txt",
  "scripts/fontscripts/fntbuild*.lua",
  "source/latex/fontscripts/*.dtx",
  "source/latex/fontscripts/*.ins",
  "tex/fontinst/fontscripts/*.etx",
  "tex/fontinst/fontscripts/*.mtx",
  "tex/latex/fontscripts/fnt-tables.tex",
  "tex/latex/fontscripts/fnt-test.lvt",
  "tex/latex/fontscripts/fnt-tests.tex",
}
unpackexe = "pdflatex"
--
uploadconfig = {
  -- *required* --
  -- announcement (don't include here?)
  announcement  = "Restructuring and update. An attempt has been made to make the script more modular. Insertion of Text Companion encoding fnt.subset declarations into font definition files is now supported. This functionality must be explicitly enabled. Basic support for sandboxing font builds is provided. This is enabled by default for fontinst, but can be used independently if other tools are utilised.",
	author        = "Clea F. Rees",
  -- email (don't include here!)
	ctanPath      = "/fonts/utilities/fontscripts",
	license       = {"lppl1.3c"},
	pkg           = ctanpkg,
	summary       = "Font encodings, metrics and Lua script fragments for generating font support packages for 8-bit engines with l3build.",
  uploader      = "Clea F. Rees",
	version       = "v0.2",
  -- optional --
	bugtracker    = {"https://codeberg.org/cfr/nfssext/issues"},
  description   = "Font encodings, metrics and Lua script fragments for generating font support packages for 8-bit engines with l3build. Optional template-based system enables the automatic generation of font tables and l3build tests. Easy addition of variable scaling to fd files (unsupported by some tools). Primarily designed for fontinst, but can be adapted for use with other programmes. Default configuration is intended to be cross-platform and require only tools included in TeX Live, but the documentation includes a simple adaption for integration with FontForge and GNU make.",
  -- development {}
  -- home {}
	-- note          = "The catalogue currently shows the package as included only in MikTeX, but it is also included in TeX Live. Any chance this could be corrected?",
	repository    = {"https://codeberg.org/cfr/nfssext", "https://github.com/cfr42/nfssext"},
  -- support {}
	topic         = {"font-cvt", "package-devel", "ctan"},
	update        = true,
  -- files --
  -- announcement_file
  -- note_file
  -- curlopt_file
}
-------------------------------------------------------------------------------
-- vim: ts=2:sw=2:tw=80:nospell
