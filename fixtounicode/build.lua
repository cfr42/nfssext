-- $Id: build.lua 11683 2026-02-24 03:57:46Z cfrees $
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
sourcefiles = {"*.dtx","*.ins","fixtounicode.lua"}
scriptfiles = {"*.lua"}
checksuppfiles = {"*.lua"}
checkdeps = { maindir .. "/arkandis/adforn", maindir .. "/arkandis/adfsymbols" }
-- checkconfigs = { "build" , "config-dev", "config-dvi" }
checkconfigs = { "build" , "config-dvi" }
checkformat = "latex"
excludetests = { "fixtounicode-marvosym", "fixtounicode-marvosym-uni" }
recordstatus = true
-- specialformats = specialformats or {}
-- specialformats["latex-dev"] = {
--   luatex = {
--     binary = "luahbtex-dev", 
--     format = "lualatex-dev", 
--     tokens = "\\PassOptionsToPackage{dev}{fixtounicode}",
--   }
-- }
typesetsuppfiles = {"*.lua"}
typesetruns = 4
manifestfile = "manifest.txt"
-------------------------------------------------------------------------------
-- dofile(maindir .. "/tag.lua")
date = "2025-2026"
if direxists(sourcefiledir .. "/../../adnoddau/l3build") then
  dofile(sourcefiledir .. "/../../adnoddau/l3build/manifest.lua")
  dofile(sourcefiledir .. "/../../adnoddau/l3build/tag.lua")
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
	version    = "v0.1.1",
  -- optional --
	bugtracker = {"https://codeberg.org/cfr/nfssext/issues"},
  description= "Utility functions in expl3 and 2e syntax for setting tounicode mappings for 7/8 bit fonts. The package provides a unified interface which enables mappings for both pdfTeX and LuaTeX. The aim is to make it easier to make legacy (text) symbol packages, which often use arbitary glyph names and encodings, accessible for the two engines currently capable of producing accessible PDFs. The package provides a limited workaround for LuaTeX 1.22 and earlier, which make the provision of such mappings more challenging. Full support requires pdfTeX or LuaTeX 1.24 or later.",
  -- development {}
  -- home {}
	note       = "I'm not sure if luatex is an appropriate tag. The package includes luatex-specific and pdftex-specific support.",
	repository = {"https://codeberg.org/cfr/nfssext", "https://github.com/cfr42/nfssext"},
  -- support {}
	topic      = {"accessible", "expl3", "font-supp", "latex3", "luatex", "pdf-feat", "tagged-pdf"},
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
test_order = {"log", "uni"}
-------------------------------------------------------------------------------
-- rhaid i vars addasol fodoli? | suitable vars must exist?
function checkinit_hook ()
  local files = {}
  if fileexists(testdir,"fixtounicode.sty") then
    table.insert(files, testdir .. "/fixtounicode.sty")
  elseif fileexists(unpackdir,"fixtounicode.sty") then
    table.insert(files, unpackdir .. "/fixtounicode.sty")
  else
    error("No fixtounicode.sty found!")
  end
  for _,i in ipairs({"adforn","adfbullets","adfarrows"}) do
    if fileexists(testdir, i .. ".sty") then
      table.insert(files, testdir .. "/" .. i .. ".sty")
    elseif fileexists(localdir, i .. ".sty") then
      table.insert(files, localdir .. "/" .. i .. ".sty")
    end
  end
  local l 
  local f, file
  for _,f in ipairs(files) do
    l = {}
    for line in io.lines(f) do
      if (string.match(line, "\\ExplFileVersion%}")) then
        table.insert(l, (string.gsub(line, "\\ExplFileVersion", "ExplFileVersion")))
      elseif (string.match(line, "\\revinfo")) then
        table.insert(l, (string.gsub(line, "\\revinfo", "revinfo")))
      else
        table.insert(l, line)
      end
    end
    file = io.open(f,"w")
    file:write(table.concat(l,"\n") .. "\n")
    file:close()
  end
  -- tests have not yet been copied to testdir
  return cp("fixtounicode.lua",unpackdir,testdir)
end
-------------------------------------------------------------------------------
function docinit_hook ()
  local lines = {}
  local srcs = {}
  for _,i in ipairs(sourcefiles) do
    for _,j in ipairs(filelist(typesetdir, i)) do
      if string.match(j, "%.dtx") then
        table.insert(srcs,j)
      end
    end
  end
  for _,i in ipairs(srcs) do
    lines = {}
    for line in io.lines(typesetdir .. "/" .. i) do
      table.insert(lines, (string.gsub(line,"%_*%@%@%_","__fixtounicode_")))
    end
    local f = assert(io.open(typesetdir .. "/" .. i, "w"))
    f:write(table.concat(lines,"\n") .. "\n")
    f:close()
  end
  return cp("fixtounicode.lua",unpackdir,typesetdir)
end
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- vim: ts=2:sw=2:tw=80
