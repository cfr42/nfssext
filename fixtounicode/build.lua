-- $Id: build.lua 11011 2025-04-21 16:37:21Z cfrees $
-- Build configuration for fixtounicode
-------------------------------------------------------------------------------
-- l3build.pdf listing 1 tudalen 9
-------------------------------------------------------------------------------
module = "fixtounicode"
ctanpkg = module
-- maindir **must** be shared with dependencies
maindir = ".."
sourcefiledir = "."
sourcefiles = {"*.dtx","*.ins","*.lua"}
-- checkengines = {"pdftex"}
checkformat = "latex"
-- checksuppfiles = {"*.fd"}
manifestfile = "manifest.txt"
-- typesetdeps = {maindir .. "/cfr-lm"}
-- typesetopts = "-interaction=nonstopmode -cnf-line='TEXMFHOME=.' -cnf-line='TEXMFLOCAL=.' -cnf-line='TEXMFARCH=.'"
-- typesetsourcefiles = {"cfr-lm.sty", maindir .. "/cfr-lm/keep/*"}
-- typesetruns = 5
-------------------------------------------------------------------------------
dofile(maindir .. "/tag.lua")
date = "2025"
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
-- function docinit_hook ()
--   if not kpse.find_file("clm.map","map") then
--     if direxists(maindir .. "/cfr-lm/keep") then
--       local errorlevel = cp("*.*",maindir .. "/cfr-lm/keep",typesetdir) 
--       if errorlevel ~= 0 then 
--         print("Warning: could not copy cfr-lm keepfiles to typesetdir.") 
--       end
--     else
--       print("Warning: could not find directory cfr-lm in " .. maindir .. ".")
--     end
--   else
--     print("Warning: using installed copy of cfr-lm.")
--   end
--   return 0
-- end
-- vim: ts=2:sw=2:tw=80:nospell
