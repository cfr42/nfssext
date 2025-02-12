-- $Id: fntbuild-vars.lua 10802 2025-02-12 20:11:33Z cfrees $
-- fntbuild variables
-------------------------------------------------
-------------------------------------------------
-- l3build variables needed before l3build defines them {{{
-------------------------------------------------
sourcefiledir = sourcefiledir or "."
maindir = maindir or sourcefiledir
-- builddir
-- should be global? or local is better?
builddir = builddir or maindir .. "/build"
-- }}}
-------------------------------------------------
-- l3build variables with changed defaults {{{
-------------------------------------------------
binaryfiles = {"*.pdf", "*.zip", "*.vf", "*.tfm", "*.pfb", "*.pfm", "*.ttf", 
  "*.otf", "*.tar.gz"}
-- also very easy for font files not to get installed properly and the old ones used
-- note this overrides the l3build default
checksearch = false
-- maindir before checkdeps
-- maindir = "../.."
-- checkdeps = { maindir .. "/fnt-tests" }
checkengines = { "pdftex" } 
checkformat = "latex"
-- cleanfiles changed below 
installfiles = {"*.afm", "*.cls", "*.enc", "*.fd", "*.map", "*.otf", "*.pfb", 
  "*.pfm", "*.sty", "*.tfm", "*.ttf", "*.vf"}
-- need module test or default?
sourcefiles = {"*.afm", "afm/*.afm", "*.pfb", "*.pfm", "*.dtx", "*.ins", 
  "opentype/*.otf", "*.otf", "tfm/*.tfm", "truetype/*.ttf", "*.ttf", 
  "type1/*.pfb", "type1/*.pfm"}
-- tdslocations changed below
typesetexe = "TEXMFDOTDIR=.:../local: pdflatex"
typesetfiles = typesetfiles or  {"*.dtx", "*-tables.tex", "*-example.tex"}
-- typesetsourcefiles changed below
-- }}}
-------------------------------------------------
-------------------------------------------------
-- additional variables (inc. dependant changes) {{{
-------------------------------------------------
-------------------------------------------------
-- font definitions to use when auto-generating tests
---@see fnt_test() checkinit_hook() fnt.fnttestfds
---@usage public
fnt.autotestfds = fnt.autotestfds or {}
-- script containing commands to convert pl and vpl files to binary form
---@see fontinst()
---@usage public
fnt.binmakers = fnt.binmakers or {"*-pltotf.sh"}
---@usage public
-- it is way too easy to pick up the same package's files in the dist tree
-- when that happens, some installation tools fail to generate duplicate files
-- once the update goes to ctan, the files disappear ...
fnt.buildsearch = false
fnt.builddeps = fnt.builddeps or {}
-- should use existing fnt variables, I think
fnt.buildfiles = fnt.buildfiles or { "*.afm", "*.enc", "*.etx", "*.fd", "*.lig", 
  "*.make", "*.map", "*.mtx", "*.nam", "*.otf", "*.pe", "*.tex" , "*.tfm" }
fnt.buildsuppfiles_sys = fnt.buildsuppfiles_sys or {}
-- sys replaces defaults; add ads to them
fnt.checksuppfiles_sys = fnt.checksuppfiles_sys or {}
fnt.checksuppfiles_add = fnt.checksuppfiles_add or {}
-- \TeX{} files to compile to produce pl, vpl etc.
---@see fontinst()
---@usage public
fnt.familymakers = fnt.familymakers or {"*-drv.tex"}
fnt.fntdir = fnt.fntdir or builddir .. "/fnt"
-- font definitions to use when auto-generating tests
---@see fnt_test() checkinit_hook() fnt.autotestfds
---@usage public
fnt.fnttestfds = fnt.fnttestfds or {}
fnt.mapfiles_sys = fnt.mapfiles_sys or {}
fnt.mapfiles_add = fnt.mapfiles_add or {}
-- sourcefiledir must be specified first
-- directory to store build products
---@usage public
fnt.keepdir = fnt.keepdir or sourcefiledir .. "/keep"
-- directory to store keeptempfiles
---@usage public
fnt.keeptempdir = fnt.keeptempdir or sourcefiledir .. "/keeptemp"
-- build products
---@usage public
fnt.keepfiles = fnt.keepfiles or {"*.enc", "*.fd", "*.map", "*.tfm", "*.vf"}
-- files to keep for diagnostics, but which shouldn't be packaged
---@usage public
fnt.keeptempfiles = fnt.keeptempfiles or {"*.mtx", "*.pl", "*-pltotf.sh", "*-rec.tex", 
  "*.vpl", "*.zz"}
cleanfiles = {fnt.keeptempfiles}  -- ** changed default
-- \TeX{} files to compile to produce map file fragments etc.
---@see fontinst()
---@usage public
fnt.mapmakers = fnt.mapmakers or {"*-map.tex"}
-- file containing regression tests
---@see check_init() in fntbuild-check.lua
---@usage public
fnt.regress = fnt.regress or "fntbuild-regression-test.tex"
-- should fontinst files be available during build?
-- @see buildinit_fontinst() in fntbuild-build.lua
---@usage public
---@boolean
---@description whether to copy contents of texmf-dist/tex/fontinst to fnt.fntdir during build
fnt.needs_fontinst = true
---@see utarg in fntbuild.lua
---@usage private
---@boolean
fnt.standalone = false
---@see fntsubsetter()
---@usage public
---@boolean
---@description whether to add fnt.subset defns to fd files for TC encodings
fnt.subset = false
---@see fntsubsetter()
---@usage public
---@usage fnt.subsetdefns.<family> = <fnt.subset>
---@description table: list of TC fds to insert fnt.subset defns into
---@description entry keys should be family names; entry values should be values
---@description for fnt.subsetdefns.<key> = <value>,
---@description   <key>   will be substituted for $FONTFAMILY and 
---@description   <value> will be substituted for $SUBSET into the fnt.subsettemplate
fnt.subsetdefns = fnt.subsetdefns or {}
---@see fntsubsetter()
---@usage public
---@usage value should be list of filenames as table
---@description list of font defn files to insert fnt.subset defns into
---@description defaults to all fds matching [Tt][Ss]1.*\.fd
fnt.subsetfiles = fnt.subsetfiles or {}
---@see fntsubsetter()
---@description $FONTFAMILY and $SUBSET may be used as placeholders 
---@description template for inserted lines specifying TS1 encoding subsets in 
---@description fnt.subsetfiles
---@usage public
fnt.subsettemplate = fnt.subsettemplate or 
  "\\DeclareEncodingSubset{TS1}{$FONTFAMILY}{$SUBSET}"
-- file to use as template for tables
---@see doc_init() in fntbuild-doc.lua
---@usage public
fnt.tablestemp = fnt.tablestemp or "fntbuild-tables.tex"
-- file to use as template for tests
---@see check_init() in fntbuild-check.lua
---@usage public
fnt.testtemp = fnt.testtemp or "fntbuild-test.lvt"
-------------------------------------------------
-- fnt.vendor and module must be specified before tdslocations
---@usage public
fnt.vendor = fnt.vendor or "public"
tdslocations = {  -- ** changed default
	"fonts/afm/" .. fnt.vendor .. "/" .. module .. "/" .. "*.afm",
	"fonts/enc/dvips/" .. module .. "/" .. "*.enc",
	"fonts/map/dvips/" .. module .. "/" .. "*.map",
	"fonts/opentype/" .. fnt.vendor .. "/" .. module .. "/" .. "*.otf",
	"fonts/tfm/" .. fnt.vendor .. "/" .. module .. "/" .. "*.tfm",
	"fonts/truetype/" .. fnt.vendor .. "/" .. module .. "/" .. "*.ttf",
	"fonts/type1/" .. fnt.vendor .. "/" .. module .. "/" .. "*.pfb",
	"fonts/type1/" .. fnt.vendor .. "/" .. module .. "/" .. "*.pfm",
	"fonts/vf/" .. fnt.vendor .. "/" .. module .. "/" .. "*.vf",
	"source/fonts/" .. module .. "/" .. "*.etx",
	"source/fonts/" .. module .. "/" .. "*.mtx",
	"source/fonts/" .. module .. "/" .. "*-drv.tex",
	"source/fonts/" .. module .. "/" .. "*-map.tex",
	"tex/latex/" .. module .. "/" .. "*.fd",
	"tex/latex/" .. module .. "/" .. "*.sty"
}
typesetsourcefiles = {fnt.keepdir .. "/*"}  -- ** changed default
-- }}}
-------------------------------------------------
-------------------------------------------------
-------------------------------------------------
-- vim: ts=2:sw=2:et:foldmethod=marker:
