-- $Id: build.lua 10746 2025-01-29 06:47:44Z cfrees $
-- Build configuration for adfsymbols
-- l3build.pdf listing 1 tudalen 9
--[[
	os.setenv requires shell-escape (which l3build always enables) but will 
	*appear** to set the variable anyway i.e will report the value even though
	it isn't set
	os.execute("env") can be used to show the environment
	os.setenv is luatex and not in the standard builtin os lua library
	ref. https://tex.stackexchange.com/questions/720446/how-can-i-export-variables-to-the-environment-when-running-l3build?noredirect=1#comment1791863_720446
--]]
-------------------------------------------------
-- copy non-public things from l3build
-- local os_newline_cp = "\n"
-- if os.type == "windows" then
--   if tonumber(status.luatex_version) < 100 or
--      (tonumber(status.luatex_version) == 100
--        and tonumber(status.luatex_revision) < 4) then
--     os_newline_cp = "\r\n"
--   end
-- end
-------------------------------------------------
--
ctanpkg = "adfsymbols"
maindir = "../.."
module = "adfsymbols"
textfiles = {"*.md","*.txt","COPYING","NOTICE"}
fnt = {}
fnt.vendor = "arkandis"
-- fnt.autotestfds = {  "uarrowsadf.fd" , "ubulletsadf.fd" }
fnt.autotestfds = { }
fnt.keepfiles = { "*.map", "*.tfm" }
-- RHAID ei osod cyn i ddarllen fntbuild.lua!
fnt.afmtotfm = true
fnt.encs = fnt.encs or {}
fnt.encs["ArrowsADF"] = "SymbolsADF.enc"
fnt.encs["BulletsADF"] = "SymbolsADF.enc"
print(fnt.encs["ArrowsADF"])
dofile(maindir .. "/fontscripts/fntbuild.lua")
function fnt.test (fntpkgname,fds,content,maps,fdsdir)
  return 0
end
typesetdeps = {maindir .. "/nfssext-cfr", maindir .. "/cfr-lm"}
typesetfiles = { module .. ".dtx" }
typesetruns = 4
--
uploadconfig = {
  -- *required* --
  -- announcement (don't include here?)
	author     = "Hirwen Harendal; Clea F. Rees",
  -- email (don't include here!)
	ctanPath   = "/fonts/adfsymbols",
	license    = {"lppl1.3c","GPL 2 with font exception"},
	pkg        = ctanpkg,
	summary    = "Support for SymbolsADF on 8-bit engines",
  uploader   = "Clea F. Rees",
	version    = "v1.3",
  -- optional --
	bugtracker = {"https://codeberg.org/cfr/nfssext/issues"},
  -- description
  -- development {}
  -- home {}
	-- note       = "The catalogue currently shows the package as included only in MikTeX, but it is also included in TeX Live. Any chance this could be corrected?",
	repository = {"https://codeberg.org/cfr/nfssext", "https://github.com/cfr42/nfssext"},
  -- support {}
	topic      = {"font", "font-type1", "font-ornmnt", "font-supp"},
	update     = true,
  -- files --
  -- announcement_file
  -- note_file
  -- curlopt_file
}
--
arkandis = arkandis or {}
arkandis.noautotest = true
dofile(maindir .. "/arkandis/arkandis-manifest.lua")
-- os.execute ("printenv")
-- vim: ts=2:sw=2:tw=80:nospell
