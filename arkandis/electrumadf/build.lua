-- $Id: build.lua 10582 2024-11-06 03:32:11Z cfrees $
-- Build configuration for electrumadf
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
ctanpkg = "electrumadf"
maindir = "../.."
module = "electrum"
vendor = "arkandis"
autotestfds = {  "t1yes.fd", "t1yesj.fd", "t1yesjw.fd", "t1yesw.fd" }
textfiles = {"*.md","*.txt","COPYING"}
dofile(maindir .. "/fontinst.lua")
-- local srcfiles = {"dotsc2.etx", "dotscbuild.mtx", "dotscmisc.mtx", "newlatin-dotsc.mtx", "t1-dotinf.etx", "t1-dotsup.etx", "ts1-dotinf.etx", "ts1-dotsup.etx"}
-- for i,j in ipairs(srcfiles) do table.insert(sourcefiles,j) end
typesetdeps = {maindir .. "/nfssext-cfr"}
unpackdeps = {maindir .. "/fontscripts"}
--
uploadconfig = {
  -- *required* --
  -- announcement (don't include here?)
	author     = "Hirwen Harendal; Clea F. Rees",
  -- email (don't include here!)
	ctanPath   = "/fonts/electrumadf",
	license    = {"lppl1.3c","GPL 2 with font exception"},
	pkg        = ctanpkg,
	summary    = "Support for ElectrumADF on 8-bit engines",
  uploader   = "Clea F. Rees",
	version    = "v1.1",
  -- optional --
	bugtracker = {"https://codeberg.org/cfr/nfssext/issues"},
  -- description
  -- development {}
  -- home {}
	note       = "The catalogue currently shows the package as included only in MikTeX, but it is also included in TeX Live. Any chance this could be corrected?",
	repository = {"https://codeberg.org/cfr/nfssext", "https://github.com/cfr42/nfssext"},
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
