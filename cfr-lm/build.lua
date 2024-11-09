-- $Id: build.lua 10582 2024-11-06 03:32:11Z cfrees $
-- Build configuration for cfr-lm
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
ctanpkg = "cfr-lm"
-- exclude tfms from lm we used just to correct erroneous font dimens in the afms 
excludefiles =  {"*~","*.afm","build.lua","config-*.lua","ec-*.tfm","*.otf","*.pfm","*.pfb"}
maindir = ".."
module = "cfr-lm"
vendor = "public"
autotestfds = { "t1clm.fd", "t1clm2.fd", "t1clm2d.fd", "t1clm2dj.fd", "t1clm2j.fd", "t1clm2jqs.fd", "t1clm2js.fd", "t1clm2jt.fd", "t1clm2jv.fd", "t1clm2qs.fd", "t1clm2s.fd", "t1clm2t.fd", "t1clm2v.fd", "t1clmd.fd", "t1clmdj.fd", "t1clmj.fd", "t1clmjqs.fd", "t1clmjs.fd", "t1clmjt.fd", "t1clmjv.fd", "t1clmqs.fd", "t1clms.fd", "t1clmt.fd", "t1clmv.fd" }
dofile(maindir .. "/fontinst.lua")
-- local srcfiles = {"dotsc2.etx", "dotscbuild.mtx", "dotscmisc.mtx", "newlatin-dotsc.mtx", "t1-dotinf.etx", "t1-dotsup.etx", "ts1-dotinf.etx", "ts1-dotsup.etx"}
-- for i,j in ipairs(srcfiles) do table.insert(sourcefiles,j) end
typesetdeps = {maindir .. "/nfssext-cfr"}
typesetruns = 5
--
uploadconfig = {
  -- *required* --
  -- announcement (don't include here?)
  announcement  = "Belated update for (N)NFSS (marginally improve consistency for some documents). Remove dependency on xkeyval. Switch to dtx/ins. Use l3build.",
	author     = "Clea F. Rees",
  -- email (don't include here!)
	ctanPath   = "/fonts/cfr-lm",
	license    = {"lppl1.3c"},
	pkg        = ctanpkg,
	summary    = "Extended support for Latin Modern on 8-bit engines",
  uploader   = "Clea F. Rees",
	version    = "v1.7",
  -- optional --
	bugtracker = {"https://codeberg.org/cfr/nfssext/issues"},
  -- description
  -- development {}
  -- home {}
	-- note       = "The catalogue currently shows the package as included only in MikTeX, but it is also included in TeX Live. Any chance this could be corrected?",
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
date = "2008-2024"
dofile(maindir .. "/fnt-manifest.lua")
-- os.execute ("printenv")
-- vim: ts=2:sw=2:tw=0:nospell
