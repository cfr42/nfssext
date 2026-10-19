-- $Id: build.lua 12137 2026-10-19 05:38:21Z cfrees $
-- Build configuration for cfr-lm
-------------------------------------------------------------------------------
-- l3build.pdf listing 1 tudalen 9
--[[
	os.setenv requires shell-escape (which l3build always enables) but will 
	*appear** to set the variable anyway i.e will report the value even though
	it isn't set
	os.execute("env") can be used to show the environment
	os.setenv is luatex and not in the standard builtin os lua library
	ref. https://tex.stackexchange.com/questions/720446/how-can-i-export-variables-to-the-environment-when-running-l3build?noredirect=1#comment1791863_720446
--]]
-------------------------------------------------------------------------------
ctanpkg = "cfr-lm"
-- exclude tfms from lm we used just to correct erroneous font dimens in the afms 
excludefiles =  {"*~","*.afm","build.lua","config-*.lua","ec-*.tfm","*.otf","*.pfm", "*.pfb"}
maindir = ".."
module = "cfr-lm"
fnt = {}
fnt.vendor = "public"
fnt.autotestfds = { "t1clm.fd", "t1clm2.fd", "t1clm2d.fd", "t1clm2dj.fd", "t1clm2j.fd", "t1clm2jqs.fd", "t1clm2js.fd", "t1clm2jt.fd", "t1clm2jv.fd", "t1clm2qs.fd", "t1clm2s.fd", "t1clm2t.fd", "t1clm2v.fd", "t1clmd.fd", "t1clmdj.fd", "t1clmj.fd", "t1clmjqs.fd", "t1clmjs.fd", "t1clmjt.fd", "t1clmjv.fd", "t1clmqs.fd", "t1clms.fd", "t1clmt.fd", "t1clmv.fd" }
checkconfigs = {"build", "config-tu"}
dofile(maindir .. "/fontscripts/fntbuild.lua")
-- local srcfiles = {"dotsc2.etx", "dotscbuild.mtx", "dotscmisc.mtx", "newlatin-dotsc.mtx", "t1-dotinf.etx", "t1-dotsup.etx", "ts1-dotinf.etx", "ts1-dotsup.etx"}
-- for i,j in ipairs(srcfiles) do table.insert(sourcefiles,j) end
-------------------------------------------------------------------------------
-- TC subset defns
-------------------------------------------------------------------------------
-- add subset defns to fds, but don't hardcode them 
-- note that this relies on implementation details, so maybe some fallback in the stys would be good, too?
-- I just can't come up with a better idea right now
fnt.subset = true
fnt.subsetdefns.clm = "lmr" 
fnt.subsetdefns.clm2 = "lmr" 
fnt.subsetdefns.clm2d = "lmdh"
fnt.subsetdefns.clm2dj = "lmdh"
fnt.subsetdefns.clm2j = "lmr"
fnt.subsetdefns.clm2jqs = "lmssq"
fnt.subsetdefns.clm2js = "lmssq"
fnt.subsetdefns.clm2jt = "lmtt"
fnt.subsetdefns.clm2jv = "lmvtt"
fnt.subsetdefns.clm2qs = "lmssq"
fnt.subsetdefns.clm2s = "lmss" 
fnt.subsetdefns.clm2t = "lmtt" 
fnt.subsetdefns.clm2v = "lmvtt" 
fnt.subsetdefns.clmd = "lmdh" 
fnt.subsetdefns.clmdj = "lmdh" 
fnt.subsetdefns.clmj = "lmr" 
fnt.subsetdefns.clmjqs = "lmssq" 
fnt.subsetdefns.clmjs = "lmss" 
fnt.subsetdefns.clmjt = "lmtt" 
fnt.subsetdefns.clmjv = "lmvtt" 
fnt.subsetdefns.clmqs = "lmssq" 
fnt.subsetdefns.clms = "lmss" 
fnt.subsetdefns.clmt = "lmtt" 
fnt.subsetdefns.clmv = "lmvtt" 
fnt.subsettemplate = "\\ExpandArgs {nnc} \\DeclareEncodingSubset {TS1} {$FONTFAMILY} {TS1:$SUBSET}"
-------------------------------------------------------------------------------
-- Opentype
-------------------------------------------------------------------------------
local pre = function(current, pat1, pat2)
  local t = {}
  for i,j in pairs(current) do
    local imod = (string.gsub(i, pat1, pat2))
    t[imod] = j
  end
  return t
end
fnt.transformfds = {
  defaults = {
    mappings = {
      fonts = {
        clmtti8t10 = "lmmono10-italic.otf",
        clmtt8t10 = "lmmono10-regular.otf",
        clmtt8t12 = "lmmono12-regular.otf",
        clmtt8t8 = "lmmono8-regular.otf",
        clmtt8t9 = "lmmono9-regular.otf",
        clmtcso8t10 = "lmmonocaps10-oblique.otf",
        clmtcsc8t10 = "lmmonocaps10-regular.otf",
        clmtk8t10 = "lmmonolt10-bold.otf",
        clmtko8t10 = "lmmonolt10-boldoblique.otf",
        clmtlo8t10 = "lmmonolt10-oblique.otf",
        clmtl8t10 = "lmmonolt10-regular.otf",
        clmtlco8t10 = "lmmonoltcond10-oblique.otf",
        clmtlc8t10 = "lmmonoltcond10-regular.otf",
        clmvtto8t10 = "lmmonoprop10-oblique.otf",
        clmvtt8t10 = "lmmonoprop10-regular.otf",
        clmvtk8t10 = "lmmonoproplt10-bold.otf",
        clmvtko8t10 = "lmmonoproplt10-boldoblique.otf",
        clmvtlo8t10 = "lmmonoproplt10-oblique.otf",
        clmvtl8t10 = "lmmonoproplt10-regular.otf",
        clmtto8t10 = "lmmonoslant10-regular.otf",
        clmbx8t10 = "lmroman10-bold.otf",
        clmbxi8t10 = "lmroman10-bolditalic.otf",
        clmri8t10 = "lmroman10-italic.otf",
        clmr8t10 = "lmroman10-regular.otf",
        clmbx8t12 = "lmroman12-bold.otf",
        clmri8t12 = "lmroman12-italic.otf",
        clmr8t12 = "lmroman12-regular.otf",
        clmr8t17 = "lmroman17-regular.otf",
        clmbx8t5 = "lmroman5-bold.otf",
        clmr8t5 = "lmroman5-regular.otf",
        clmbx8t6 = "lmroman6-bold.otf",
        clmr8t6 = "lmroman6-regular.otf",
        clmbx8t7 = "lmroman7-bold.otf",
        clmri8t7 = "lmroman7-italic.otf",
        clmr8t7 = "lmroman7-regular.otf",
        clmbx8t8 = "lmroman8-bold.otf",
        clmri8t8 = "lmroman8-italic.otf",
        clmr8t8 = "lmroman8-regular.otf",
        clmbx8t9 = "lmroman9-bold.otf",
        clmri8t9 = "lmroman9-italic.otf",
        clmr8t9 = "lmroman9-regular.otf",
        clmcsco8t10 = "lmromancaps10-oblique.otf",
        clmcsc8t10 = "lmromancaps10-regular.otf",
        clmbo8t10 = "lmromandemi10-oblique.otf",
        clmb8t10 = "lmromandemi10-regular.otf",
        clmdunh8t10 = "lmromandunh10-oblique.otf",
        clmduno8t10 = "lmromandunh10-regular.otf",
        clmbxo8t10 = "lmromanslant10-bold.otf",
        clmro8t10 = "lmromanslant10-regular.otf",
        clmro8t12 = "lmromanslant12-regular.otf",
        clmro8t17 = "lmromanslant17-regular.otf",
        clmro8t8 = "lmromanslant8-regular.otf",
        clmro8t9 = "lmromanslant9-regular.otf",
        clmu8t10 = "lmromanunsl10-regular.otf",
        clmssbx8t10 = "lmsans10-bold.otf",
        clmssbo8t10 = "lmsans10-boldoblique.otf",
        clmsso8t10 = "lmsans10-oblique.otf",
        clmss8t10 = "lmsans10-regular.otf",
        clmsso8t12 = "lmsans12-oblique.otf",
        clmss8t12 = "lmsans12-regular.otf",
        clmsso8t17 = "lmsans17-oblique.otf",
        clmss8t17 = "lmsans17-regular.otf",
        clmsso8t8 = "lmsans8-oblique.otf",
        clmss8t8 = "lmsans8-regular.otf",
        clmsso8t9 = "lmsans9-oblique.otf",
        clmss8t9 = "lmsans9-regular.otf",
        clmssdo8t10 = "lmsansdemicond10-oblique.otf",
        clmssdc8t10 = "lmsansdemicond10-regular.otf",
        clmssqbx8t8 = "lmsansquot8-bold.otf",
        clmssqbo8t8 = "lmsansquot8-boldoblique.otf",
        clmssqo8t8 = "lmsansquot8-oblique.otf",
        clmssq8t8 = "lmsansquot8-regular.otf",
      },
      enc = { T1 = "TU" },
    },
    defeat = "\\UnicodeFontTeXLigatures\\clm@patch",
  },
  { fd = "t1clm.fd",
    feat = "\\clm@rm@zero+tnum;+lnum;",
  },
  { fd = "t1clm2.fd",
    feat = "\\clm@rm@zero+pnum;+lnum;",
    pre = function(current) return pre(current, "(clm[^oi]*)([oi]?8t)", "%12%2") end,
  },
  { fd = "t1clm2d.fd",
    feat = "\\clm@rm@zero+pnum;+lnum;",
    pre = function(current) return pre(current, "(clmdunh?)(o?8t)", "%12%2") end,
  },
  { fd = "t1clm2dj.fd",
    feat = "\\clm@rm@zero+pnum;+onum;",
    pre = function(current) return pre(current, "(clmdunh?)(o?8t)", "%12j%2") end,
  },
  { fd = "t1clm2j.fd",
    feat = "\\clm@rm@zero+pnum;+onum;",
    pre = function(current) return pre(current, "(clm[^io]*)(i?)(o?8t)", "%12%2j%3") end,
  },
  { fd = "t1clm2jqs.fd",
    feat = "\\clm@sf@zero+pnum;+onum;",
    pre = function(current) return pre(current, "(clmssq[bx]*)(o?)", "%12j%2") end,
  },
  { fd = "t1clm2js.fd",
    feat = "\\clm@sf@zero+pnum;+onum;",
    pre = function(current) return pre(current, "(clmssd?b?x?c?)(o?)", "%12j%2") end,
  },
  { fd = "t1clm2jt.fd",
    feat = "\\clm@tt@zero-liga;-tlig;+tnum;+onum;", -- don't make mono proportional
    pre = function(current) return pre(current, "(clmt[^o8]*)(o?8t)", "%1j%2") end,
  },
  { fd = "t1clm2jv.fd",
    feat = "\\clm@tt@zero+pnum;+onum;",
    pre = function(current) return pre(current, "(vt[^o8]*)", "%12j") end,
  },
  { fd = "t1clm2qs.fd",
    feat = "\\clm@sf@zero+pnum;+lnum;",
    pre = function(current) return pre(current, "(clmssq[^o8]*)", "%12") end,
  },
  { fd = "t1clm2s.fd",
    feat = "\\clm@sf@zero+pnum;+lnum;",
    pre = function(current) return pre(current, "(clmss[obd]?[xc]*)(o?)", "%12%2") end,
  },
  { fd = "t1clm2t.fd",
    feat = "\\clm@tt@zero-liga;-tlig;+tnum;+lnum;",  -- don't make mono proportional
  },
  { fd = "t1clm2v.fd",
    feat = "\\clm@tt@zero+pnum;+lnum;",
    pre = function(current) return pre(current, "(clmvt[tkl])(o?)", "%12%2") end,
  },
  { fd = "t1clmd.fd",
    feat = "\\clm@rm@zero+tnum;+lnum;",
  },
  { fd = "t1clmdj.fd",
    feat = "\\clm@rm@zero+tnum;+onum;",
    pre = function(current) return pre(current, "(clmdunh?)(o?)", "%1j%2") end,
  },
  { fd = "t1clmj.fd",
    feat = "\\clm@rm@zero+tnum;+onum;",
    pre = function(current) return pre(current, "(clm[^io8]*)", "%1j") end,
  },
  { fd = "t1clmjqs.fd",
    feat = "\\clm@sf@zero+tnum;+onum;",
    pre = function(current) return pre(current, "([^o8])(o?8t)", "%1j%2") end,
  },
  { fd = "t1clmjs.fd",
    feat = "\\clm@sf@zero+tnum;+onum;",
    pre = function(current) return pre(current, "([^o8])(o?8t)", "%1j%2") end,
  },
  { fd = "t1clmjt.fd",
    feat = "\\clm@tt@zero-liga;-tlig;+tnum;+onum;",
    pre = function(current) return pre(current, "([^o8])(o?8t)", "%1j%2") end,
  },
  { fd = "t1clmjv.fd",
    feat = "\\clm@tt@zero+tnum;+onum;",
    pre = function(current) return pre(current, "([^o8])(o?8t)", "%1j%2") end,
  },
  { fd = "t1clmqs.fd",
    feat = "\\clm@sf@zero+tnum;+lnum;",
  },
  { fd = "t1clms.fd",
    feat = "\\clm@sf@zero+tnum;+lnum;",
  },
  { fd = "t1clmt.fd",
    feat = "\\clm@tt@zero-liga;-tlig;+tnum;+lnum;",
  },
  { fd = "t1clmv.fd",
    feat = "\\clm@tt@zero+tnum;+lnum;",
  },
}
-------------------------------------------------------------------------------
typesetdeps = {maindir .. "/nfssext-cfr"}
typesetopts = "-interaction=nonstopmode -cnf-line='TEXMFHOME=.' -cnf-line='TEXMFLOCAL=.' -cnf-line='TEXMFARCH=.'"
typesetruns = 5
-------------------------------------------------------------------------------
-- CTAN upload 
-------------------------------------------------------------------------------
uploadconfig = {
  -- *required* --
  -- announcement (don't include here?)
  -- announcement  = "Subset declarations -> font defn files; remove from sty for current LaTeX; + nomaths/nomath option",
	author     = "Clea F. Rees",
  -- email (don't include here!)
	ctanPath   = "/fonts/cfr-lm",
	license    = {"lppl1.3c"},
	pkg        = ctanpkg,
	summary    = "Extended support for Latin Modern on all engines",
  uploader   = "Clea F. Rees",
	version    = "v1.9",
  -- optional --
	bugtracker = {"https://codeberg.org/cfr/nfssext/issues"},
  -- description
  -- development {}
  -- home {}
  note       = "Note that cfr-lm-tables.pdf is automatically generated by l3build using a template from fontscripts. cfr-lm-tables.tex is not included as it is a generated intermediary rather than source.",
	-- note       = "The catalogue currently shows the package as included only in MikTeX, but it is also included in TeX Live. Any chance this could be corrected?",
	repository = {"https://codeberg.org/cfr/nfssext", "https://github.com/cfr42/nfssext"},
  -- support {}
	topic      = {"font", "font-type1", "font-otf"},
	update     = true,
  -- files --
  -- announcement_file
  -- note_file
  -- curlopt_file
}
-------------------------------------------------------------------------------
-- manifest
-------------------------------------------------------------------------------
date = "2008-2025"
dofile(maindir .. "/fnt-manifest.lua")
-------------------------------------------------------------------------------
-- pull afms & tfms from dist tree
-------------------------------------------------------------------------------
cleandir(sourcefiledir .. "/afm")
cleandir(sourcefiledir .. "/tfm") 
local str = kpse.var_value("TEXMFDIST")
print(str)
for _,i in ipairs(filelist(str .. "/fonts/afm/public/lm","*.afm")) do
  cp(i,str .. "/fonts/afm/public/lm",sourcefiledir .. "/afm")
end
for _,i in ipairs(filelist(str .. "/fonts/tfm/public/lm","ec-*")) do
  cp(i,str .. "/fonts/tfm/public/lm",sourcefiledir .. "/tfm")
end
-------------------------------------------------
function normalize_log_hook(line)
  return (string.gsub(line, "(%(function: 0x)%x+%)", "%1...)"))
end
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- vim: ts=2:sw=2:tw=0:nospell
