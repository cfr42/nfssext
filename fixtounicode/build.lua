-- $Id: build.lua 11669 2026-02-22 07:48:33Z cfrees $
-- Build configuration for fixtounicode
-------------------------------------------------------------------------------
-- l3build.pdf listing 1 tudalen 9
-------------------------------------------------------------------------------
module = "fixtounicode"
ctanpkg = module
-- maindir **must** be shared with dependencies
maindir = ".."
sourcefiledir = "."
-- none of these actually work for lua fragments, so they get copied by hand
-- below
sourcefiles = {"*.dtx","*.ins","*.lua"}
scriptfiles = {"*.lua"}
checksuppfiles = {"*.lua"}
typesetsuppfiles = {"*.lua"}
checkdeps = { maindir .. "/arkandis/adforn", maindir .. "/arkandis/adfsymbols" }
checkconfigs = { "build" , "config-dev", "config-dvi" }
checkformat = "latex"
recordstatus = true
specialformats = specialformats or {}
specialformats["latex-dev"] = {
  luatex = {
    binary = "luahbtex-dev", 
    format = "lualatex-dev", 
    tokens = "\\PassOptionsToPackage{dev}{fixtounicode}",
  }
}
manifestfile = "manifest.txt"
-------------------------------------------------------------------------------
dofile(maindir .. "/tag.lua")
date = "2025-2026"
if direxists(sourcefiledir .. "/../../adnoddau/l3build") then
  dofile(sourcefiledir .. "/../../adnoddau/l3build/manifest.lua")
end
-------------------------------------------------------------------------------
uploadconfig = {
  -- *required* --
  -- announcement (don't include here?)
  announcement  = "Utility functions in expl3 and 2e syntax for setting tounicode mappings for 7/8 bit fonts. Implements workarounds for limitations of LuaTeX.",
	author     = "Clea F. Rees",
  -- email (don't include here!)
	ctanPath   = "/macros/contrib/latex/fixtounicode",
	license    = {"lppl1.3c"},
	pkg        = ctanpkg,
	summary    = "Utility functions in expl3 and 2e syntax for setting tounicode mappings for 7/8 bit fonts.",
  uploader   = "Clea F. Rees",
	version    = "v0.1",
  -- optional --
	bugtracker = {"https://codeberg.org/cfr/nfssext/issues"},
  description= "Utility functions in expl3 and 2e syntax for setting tounicode mappings for 7/8 bit fonts. The package provides a unified interface which enables mappings for both pdfTeX and luaTeX. The aim is to make it easier to make legacy (text) symbol packages, which often use arbitary glyph names and encodings, accessible for the two engines currently capable of producing accessible PDFs. More specifically, the package works around limitations of LuaTeX which make the provision of such mappings more challenging. No knowledge of Lua is necessary to use the package.",
  -- development {}
  -- home {}
	note       = "I'm not sure if luatex is an appropriate tag. The package includes luatex-specific and pdftex-specific support.",
	repository = {"https://codeberg.org/cfr/nfssext", "https://github.com/cfr42/nfssext"},
  -- support {}
	topic      = {"accessible", "expl3", "font-supp", "latex3", "luatex", "pdf-feat"},
	update     = false,
  -- files --
  -- announcement_file
  -- note_file
  -- curlopt_file
}
-------------------------------------------------------------------------------
-- l3build manual tudalennau 24-25
-- l3build reads l3build-variables.lua *ar ôl* i'r ffeil hwn | *after* this file
test_types = test_types or {}
test_types.uni = {
  test = ".uvt",
  reference = ".uref",
  generated = ".pdf",
  rewrite = function(source, normalized, engine, errorcode)
    local gentxt = string.gsub(source, string.gsub(pdfext, "%.", "%%.") .. "$", ".txt")
    os.execute(string.format("pdftotext %s %s", source, gentxt))
    local normtxt = string.gsub(source, string.gsub(pdfext, "%.", "%%.") .. "$", "." .. engine .. ".txt")
    os.execute(string.format("cp %s %s", gentxt, normtxt))
  end,
  compare = function (difffile, tlgfile, logfile, cleanup, name, engine)
    local normtxtfile = string.gsub(logfile, string.gsub(pdfext, "%.", "%%.") .. "$", ".txt")
    return compare_tlg (difffile, tlgfile, normtxtfile, cleanup, name, "wibble")
  end,
}
-- test_order = {"uni"}
test_order = {"log", "uni"}
-------------------------------------------------------------------------------
-- rhaid i vars addasol fodoli? | suitable vars must exist?
function checkinit_hook ()
  local f
  if fileexists(testdir,"fixtounicode.sty") then
    f = testdir .. "/fixtounicode.sty"
  elseif fileexists(unpackdir,"fixtounicode.sty") then
    f = unpackdir .. "/fixtounicode.sty"
  else
    error("No fixtounicode.sty found!")
  end
  local l = {}
  for line in io.lines(f) do
    if (string.match(line, "\\ExplFileVersion%}")) then
      table.insert(l, (string.gsub(line, "\\ExplFileVersion", "ExplFileVersion")))
    else
      table.insert(l, line)
    end
  end
  local file = io.open(f,"w")
  file:write(table.concat(l,"\n") .. "\n")
  file:close()
  -- tests have not yet been copied to testdir
  return cp("fixtounicode.lua",unpackdir,testdir)
end
function docinit_hook ()
  return cp("fixtounicode.lua",unpackdir,typesetdir)
end
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- vim: ts=2:sw=2:tw=80
