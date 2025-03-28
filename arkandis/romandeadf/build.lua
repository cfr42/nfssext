-- $Id: build.lua 10974 2025-03-28 20:14:48Z cfrees $
-- Build configuration for romandeadf
-- l3build.pdf listing 1 tudalen 9
--[[
	os.setenv requires shell-escape (which l3build always enables) but will 
	*appear** to set the variable anyway i.e will report the value even though
	it isn't set
	os.execute("env") can be used to show the environment
	os.setenv is luatex and not in the standard builtin os lua library
	ref. https://tex.stackexchange.com/questions/720446/how-can-i-export-variables-to-the-environment-when-running-l3build?noredirect=1#comment1791863_720446
--]]
--
ctanpkg = "romandeadf"
maindir = "../.."
module = "romande"
fnt = {}
fnt.vendor = "arkandis"
fnt.autotestfds = {  "t1yrd.fd", "t1yrda.fd", "t1yrdaw.fd", "t1yrdw.fd" }
dofile(maindir .. "/fontscripts/fntbuild.lua")
-- local srcfiles = { "ts1-euro.etx", "ts1-euro.enc" }
-- for i,j in ipairs(srcfiles) do table.insert(sourcefiles,j) end
-- angen TODO new TL installation
unpackdeps = {maindir .. "/fontscripts"}
textfiles = {"*.md", "*.txt", "COPYING"}
typesetdeps = {maindir .. "/nfssext-cfr"}
typesetopts = "-interaction=nonstopmode -cnf-line='TEXMFHOME=.' -cnf-line='TEXMFLOCAL=.' -cnf-line='TEXMFARCH=.'"
typesetruns = 5
--
uploadconfig = {
  -- *required* --
  -- announcement (don't include here?)
	author     = "Hirwen Harendal; Clea F. Rees",
  -- email (don't include here!)
	ctanPath   = "/fonts/romandeadf",
	license    = {"lppl1.3c","GPL 2 with font exception"},
	pkg        = ctanpkg,
	summary    = "Support for RomandeADF on 8-bit engines",
  uploader   = "Clea F. Rees",
	version    = "v2.1",
  -- optional --
	bugtracker = {"https://codeberg.org/cfr/nfssext/issues"},
  -- description
  -- development {}
  -- home {}
	-- repository = {"https://codeberg.org/cfr/nfssext", "https://github.com/cfr42/nfssext"},
	note = "Repository mirrored at https://github.com/cfr42/nfssext",
	repository = "https://codeberg.org/cfr/nfssext",
  -- support {}
	topic      = {"font", "font-type1"},
	update     = true,
  -- files --
  -- announcement_file
  -- note_file
  -- curlopt_file
}
--
dofile(maindir .. "/arkandis/arkandis-manifest.lua")
-- os.execute ("printenv")
-- vim: ts=2:sw=2:tw=80:nospell
