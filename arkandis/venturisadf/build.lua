-- $Id: build.lua 10416 2024-09-27 15:59:51Z cfrees $
-- Build configuration for venturisadf
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
ctanpkg = "venturisadf"
maindir = "../.."
module = "venturisadf"
vendor = "arkandis"
fnttestfds = {}
fnttestfds.venturis = { "t1yvt.fd", "t1yvtajw.fd", "t1yvtaw.fd", "t1yvtd.fd", "t1yvtj.fd", "t1yvtjw.fd", "t1yvtw.fd" , "t1yv1.fd", "t1yv1d.fd" } 
fnttestfds.venturis2 = { "t1yv2.fd" , "t1yv3.fd" } 
fnttestfds.venturisold = { "t1yvo.fd", "t1yvoa.fd", "t1yvoad.fd", "t1yvod.fd" } 
typesetfiles = { module .. ".dtx", "*-imp.dtx", "*-example.tex", "*-tables.tex" }
dofile(maindir .. "/fontinst.lua")
-- local srcfiles = { "lining.etx", "oldstyle.etx", "t1-dotalt-f_f.enc", "t1-dotalt-f_f.etx", "t1-f_f.enc", "t1-f_f.etx", "t1j-f_f.etx", "ts1-euro.enc", "ts1-euro.etx", "ucdotalt.etx" }
-- for i,j in ipairs(srcfiles) do table.insert(sourcefiles,j) end
-- angen TODO new TL installation
-- make tds archive for this one 
packtdszip = true
unpackdeps = {maindir .. "/fontscripts"}
tdslocations = {
	"fonts/afm/" .. vendor .. "/venturis/" .. "yvt*.afm",
	"fonts/afm/" .. vendor .. "/venturis2/" .. "yv2*.afm",
	"fonts/afm/" .. vendor .. "/venturisold/" .. "yvo*.afm",
	"fonts/afm/" .. vendor .. "/venturissans/" .. "yv1*.afm",
	"fonts/afm/" .. vendor .. "/venturissans2/" .. "yv3*.afm",
	"fonts/enc/dvips/" .. module .. "/" .. "*.enc",
  "fonts/map/dvips/venturis/yvt.map",
	"fonts/map/dvips/venturis2/yv2.map",
	"fonts/map/dvips/venturisold/yvo.map",
	"fonts/map/dvips/venturissans/yv1.map",
	"fonts/map/dvips/venturissans2/yv3.map",
  "fonts/opentype/" .. vendor .. "/venturis/" .. "VenturisADF-*.otf",
  "fonts/opentype/" .. vendor .. "/venturis/" .. "VenturisADFCd-*.otf",
  "fonts/opentype/" .. vendor .. "/venturis/" .. "VenturisADFHeavy*.otf",
  "fonts/opentype/" .. vendor .. "/venturis/" .. "VenturisADFStyle-*.otf",
  "fonts/opentype/" .. vendor .. "/venturis2/" .. "VenturisADFNo2*.otf",
  "fonts/opentype/" .. vendor .. "/venturisold/" .. "VenturisOldADF*.otf",
  "fonts/opentype/" .. vendor .. "/venturissans/" .. "VenturisSansADF-*.otf",
  "fonts/opentype/" .. vendor .. "/venturissans/" .. "VenturisSansADFCd-*.otf",
  "fonts/opentype/" .. vendor .. "/venturissans/" .. "VenturisSansADFEx-*.otf",
  "fonts/opentype/" .. vendor .. "/venturissans/" .. "VenturisSansADFLt-*.otf",
  "fonts/opentype/" .. vendor .. "/venturissans/" .. "VenturisSansADFHeavy*.otf",
  "fonts/opentype/" .. vendor .. "/venturissans2/" .. "VenturisSansADFNo2*.otf",
	"fonts/tfm/" .. vendor .. "/venturis/" .. "yvt*.tfm",
	"fonts/tfm/" .. vendor .. "/venturis2/" .. "yv2*.tfm",
	"fonts/tfm/" .. vendor .. "/venturisold/" .. "yvo*.tfm",
	"fonts/tfm/" .. vendor .. "/venturissans/" .. "yv1*.tfm",
	"fonts/tfm/" .. vendor .. "/venturissans2/" .. "yv3*.tfm",
  "fonts/pfb/" .. vendor .. "/venturis/" .. "yvt*.pfb",
	"fonts/pfb/" .. vendor .. "/venturis2/" .. "yv2*.pfb",
	"fonts/pfb/" .. vendor .. "/venturisold/" .. "yvo*.pfb",
	"fonts/pfb/" .. vendor .. "/venturissans/" .. "yv1*.pfb",
	"fonts/pfb/" .. vendor .. "/venturissans2/" .. "yv3*.pfb",
  "fonts/pfm/" .. vendor .. "/venturis/" .. "yvt*.pfm",
	"fonts/pfm/" .. vendor .. "/venturis2/" .. "yv2*.pfm",
	"fonts/pfm/" .. vendor .. "/venturisold/" .. "yvo*.pfm",
	"fonts/pfm/" .. vendor .. "/venturissans/" .. "yv1*.pfm",
	"fonts/pfm/" .. vendor .. "/venturissans2/" .. "yv3*.pfm",
  "fonts/vf/" .. vendor .. "/venturis/" .. "yvt*.vf",
	"fonts/vf/" .. vendor .. "/venturis2/" .. "yv2*.vf",
	"fonts/vf/" .. vendor .. "/venturisold/" .. "yvo*.vf",
	"fonts/vf/" .. vendor .. "/venturissans/" .. "yv1*.vf",
	"fonts/vf/" .. vendor .. "/venturissans2/" .. "yv3*.vf",
	"source/fonts/" .. module .. "/" .. "*.etx",
	"source/fonts/" .. module .. "/" .. "*.mtx",
	"source/fonts/" .. module .. "/" .. "*-drv.tex",
	"source/fonts/" .. module .. "/" .. "*-map.tex",
  "tex/latex/venturis/" .. "t1yvt*.fd",
	"tex/latex/venturis2/" .. "t1yv2*.fd",
	"tex/latex/venturisold/" .. "t1yvo*.fd",
	"tex/latex/venturissans/" .. "t1yv1*.fd",
	"tex/latex/venturissans2/" .. "t1yv3*.fd",
  "tex/latex/venturis/" .. "ts1yvt*.fd",
	"tex/latex/venturis2/" .. "ts1yv2*.fd",
	"tex/latex/venturisold/" .. "ts1yvo*.fd",
	"tex/latex/venturissans/" .. "ts1yv1*.fd",
	"tex/latex/venturissans2/" .. "ts1yv3*.fd",
	"tex/latex/" .. module .. "/" .. "*.sty"
}
textfiles = {"*.md", "*.txt", "COPYING"}
typesetruns = 5
--
uploadconfig = {
  -- *required* --
  -- announcement (don't include here?)
  announcement = "Belated update for (N)NFSS; add scaling options; switch to dtx/ins; includes OTF.",
	author     = "Hirwen Harendal; Clea F. Rees",
  -- email (don't include here!)
	ctanPath   = "/fonts/venturisadf",
	license    = {"lppl1.3","utopia"},
	pkg        = ctanpkg,
	summary    = "Support for VenturisADF on 8-bit engines",
  uploader   = "Clea F. Rees",
	version    = "v2.0",
  -- optional --
	bugtracker = {"https://codeberg.org/cfr/nfssext/issues"},
  -- description
  -- development {}
  -- home {}
	repository = {"https://codeberg.org/cfr/nfssext", "https://github.com/cfr42/nfssext"},
	-- note = "Repository mirrored at https://github.com/cfr42/nfssext",
  note       = "Creation of font definition files REQUIRES custom l3build target. I understand the lua scripts should not be included.",
	-- repository = "https://codeberg.org/cfr/nfssext",
  -- support {}
	topic      = {"font", "font-type1", "font-otf"},
	update     = true,
  -- files --
  -- announcement_file
  -- note_file
  -- curlopt_file
}
--
date = "2008-2024"
dofile(maindir .. "/arkandis/arkandis-manifest.lua")
function manifest_write_opening(filehandle)
  local date  = date or os.date()
  filehandle:write( "# Manifest for " .. ctanpkg .. "\n\nCopyright (C) " .. date .. " Clea F. Rees\n\n" )
  filehandle:write(
  [[This work may be distributed and/or modified under the conditions of the LaTeX
  Project Public License, either version 1.3 of this license or (at your option)
  any later version.  The latest version of this license is in
  https://www.latex-project.org/lppl.txt
  and version 1.3 or later is part of all distributions of LaTeX version
  2005/12/01 or later.

  This work has the LPPL maintenance status `maintained'.

  The Current Maintainer of this work is Clea F. Rees.

  This work consists of all files listed in manifest.txt.

  This file lists all files released under the LPPL. It does *not* list all files
  included in the package. See README for further details.

  This file was automatically generated by `l3build manifest`.]]
  )
end
-- os.execute ("printenv")
-- vim: ts=2:sw=2:tw=80:nospell
