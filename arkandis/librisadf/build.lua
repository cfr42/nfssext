-- $Id: build.lua 10538 2024-10-28 16:07:36Z cfrees $
-- Build configuration for librisadf
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
ctanpkg = "libris"
maindir = "../.."
module = "libris"
vendor = "arkandis"
autotestfds = {  "t1yly.fd", "t1ylyw.fd" }
dofile(maindir .. "/fontinst.lua")
-- local srcfiles = {"t1-cfr.etx", "ts1-euro.etx", "t1-cfr.enc", "ts1-euro.enc"}
-- for i,j in ipairs(srcfiles) do table.insert(sourcefiles,j) end
textfiles = {"*.md", "*.txt", "COPYING"}
typesetruns = 5
-- angen ../../TODO
checkdeps = {maindir .. "/nfssext-cfr"}
typesetdeps = {maindir .. "/nfssext-cfr"}
unpackdeps = {maindir .. "/fontscripts"}
--
uploadconfig = {
  -- *required* --
  -- announcement (don't include here?)
	author     = "Hirwen Harendal; Clea F. Rees",
  -- email (don't include here!)
	ctanPath   = "/fonts/libris",
	license    = {"lppl1.3c","GPL 2 with font exception"},
	pkg        = ctanpkg,
	summary    = "Support for LibrisADF on 8-bit engines",
  uploader   = "Clea F. Rees",
	version    = "v1.1",
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
