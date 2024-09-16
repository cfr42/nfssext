-- $Id: build.lua 10344 2024-09-13 20:17:16Z cfrees $
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
-- unpackfiles = {"*.ins"}
-- maindir **must** be shared with dependencies
maindir = ".."
-- auxfiles = {"*.aux"}
sourcefiles = {"*.dtx","*.ins"}
checkengines = {"pdftex"}
checkformat = "latex"
checksuppfiles = {"*.fd"}
manifestfile = {"manifest.txt"}
-- checkdeps = {maindir .. "/cfr-lm"}
typesetdeps = {maindir .. "/cfr-lm"}
typesetsourcefiles = {"cfr-lm.sty", maindir .. "/cfr-lm/keep/*"}
typesetruns = 5
--
-- os.execute ("printenv")
-- vim: ts=2:sw=2:tw=80:nospell
