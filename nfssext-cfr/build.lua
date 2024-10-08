-- $Id: build.lua 10484 2024-10-08 04:36:01Z cfrees $
-- Build configuration for nfssext-cfr
-- l3build.pdf listing 1 tudalen 9
--[[
	os.setenv requires shell-escape (which l3build always enables) but will 
	*appear** to set the variable anyway i.e will report the value even though
	it isn't set
	os.execute("env") can be used to show the environment
	os.setenv is luatex and not in the standard builtin os lua library
	ref. https://tex.stackexchange.com/questions/720446/how-can-i-export-variables-to-the-environment-when-running-l3build?noredirect=1#comment1791863_720446
--]]
os.setenv ("PATH", "/usr/local/texlive/bin:/usr/bin:")
os.setenv ("TEXMFHOME", ".")
os.setenv ("TEXMFLOCAL", ".")
os.setenv ("TEXMFARCH", ".")
--
module = "nfssext-cfr"
ctanpkg = module
-- unpackfiles = {"*.ins"}
-- maindir **must** be shared with dependencies
maindir = ".."
sourcedir = "."
-- auxfiles = {"*.aux"}
sourcefiles = {"*.dtx","*.ins"}
checkengines = {"pdftex"}
checkformat = "latex"
checksuppfiles = {"*.fd"}
manifestfile = "manifest.txt"
-- checkdeps = {maindir .. "/cfr-lm"}
typesetdeps = {maindir .. "/cfr-lm"}
typesetsourcefiles = {"cfr-lm.sty", maindir .. "/cfr-lm/keep/*"}
typesetruns = 5
--
dofile(maindir .. "/tag.lua")
date = "2008-2024"
if direxists(sourcedir .. "/../../adnoddau/l3build") then
  dofile(sourcedir .. "/../../adnoddau/l3build/manifest.lua")
end
--
uploadconfig = {
  -- *required* --
  -- announcement (don't include here?)
  announcement  = "",--Belated update for (N)NFSS. Implement new package options. Switch to dtx/ins. Use l3build.",
	author     = "Clea F. Rees",
  -- email (don't include here!)
	ctanPath   = "/macros/contrib/latex/nfssext-cfr",
	license    = {"lppl1.3c"},
	pkg        = ctanpkg,
	summary    = "Extended font selection commands for LaTeX's (New) New Font Selection Scheme",
  uploader   = "Clea F. Rees",
	version    = "v1.1",
  -- optional --
	bugtracker = {"https://codeberg.org/cfr/nfssext/issues"},
  description= "An extension and modification of Philipp Lehman's nfssext which provides extended font selection commands modelled on those provided by LaTeX 2e.",
  -- development {}
  -- home {}
	note       = "My apologies. I ought to have caught this.",
	repository = {"https://codeberg.org/cfr/nfssext", "https://github.com/cfr42/nfssext"},
  -- support {}
	topic      = {"font-sel", "font-use", "font-supp"},
	update     = true,
  -- files --
  -- announcement_file
  -- note_file
  -- curlopt_file
}
-- os.execute ("printenv")
-- vim: ts=2:sw=2:tw=80:nospell
