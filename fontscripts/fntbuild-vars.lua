-- $Id: fntbuild-vars.lua 10659 2024-11-21 06:49:20Z cfrees $
-- fntbuild variables
-------------------------------------------------
-------------------------------------------------
-- l3build variables needed before l3build defines them
-------------------------------------------------
sourcefiledir = sourcefiledir or "."
maindir = maindir or sourcefiledir
-- builddir
-- should be global? or local is better?
builddir = builddir or maindir .. "/build"
-------------------------------------------------
-- l3build variables with changed defaults
-------------------------------------------------
-- also very easy for font files not to get installed properly and the old ones used
-- note this overrides the l3build default
checksearch = false
-- maindir before checkdeps
-- maindir = "../.."
checkdeps = { maindir .. "/fnt-tests" }
checkengines = { "pdftex" } 
checkformat = "latex"
-- cleanfiles changed below 
installfiles = {"*.afm", "*.cls", "*.enc", "*.fd", "*.map", "*.otf", "*.pfb", "*.pfm", "*.sty", "*.tfm", "*.ttf", "*.vf"}
-- need module test or default?
sourcefiles = {"*.afm", "afm/*.afm", "*.pfb", "*.pfm", "*.dtx", "*.ins", "opentype/*.otf", "*.otf", "tfm/*.tfm", "truetype/*.ttf", "*.ttf", "type1/*.pfb", "type1/*.pfm"}
-- tdslocations changed below
typesetexe = "TEXMFDOTDIR=.:../local: pdflatex"
typesetfiles = typesetfiles or  {"*.dtx", "*-tables.tex", "*-example.tex"}
-- typesetsourcefiles changed below
-------------------------------------------------
-------------------------------------------------
-- additional variables
-------------------------------------------------
-------------------------------------------------
-- font definitions to use when auto-generating tests
---@see fnt_test() checkinit_hook() fnttestfds
---@usage public
autotestfds = autotestfds or {}
binaryfiles = {"*.pdf", "*.zip", "*.vf", "*.tfm", "*.pfb", "*.pfm", "*.ttf", "*.otf", "*.tar.gz"}
-- script containing commands to convert pl and vpl files to binary form
---@see fontinst()
---@usage public
binmakers = binmakers or {"*-pltotf.sh"}
---@usage public
-- it is way too easy to pick up the same package's files in the dist tree
-- when that happens, some installation tools fail to generate duplicate files
-- once the update goes to ctan, the files disappear ...
buildsearch = false
-------------------------------------------------
builddeps = builddeps or {}
-- should use existing fnt variables, I think
buildfiles = buildfiles or { "*.afm", "*.enc", "*.etx", "*.fd", "*.lig", "*.make", "*.map", "*.mtx", "*.nam", "*.otf", "*.pe", "*.tex" , "*.tfm" }
buildsuppfiles_sys = buildsuppfiles_sys or {}
-- sys replaces defaults; add ads to them
checksuppfiles_sys = checksuppfiles_sys or {}
checksuppfiles_add = checksuppfiles_add or {}
cleanfiles = {keeptempfiles}
-- \TeX{} files to compile to produce pl, vpl etc.
---@see fontinst()
---@usage public
familymakers = familymakers or {"*-drv.tex"}
fntdir = fntdir or builddir .. "/fnt"
-- font definitions to use when auto-generating tests
---@see fnt_test() checkinit_hook() autotestfds
---@usage public
fnttestfds = fnttestfds or {}
mapfiles_sys = mapfiles_sys or {}
mapfiles_add = mapfiles_add or {}
-- sourcefiledir must be specified first
-- directory to store build products
---@usage public
keepdir = keepdir or sourcefiledir .. "/keep"
-- directory to store keeptempfiles
---@usage public
keeptempdir = keeptempdir or sourcefiledir .. "/keeptemp"
-- build products
---@usage public
keepfiles = keepfiles or {"*.enc", "*.fd", "*.map", "*.tfm", "*.vf"}
-- files to keep for diagnostics, but which shouldn't be packaged
---@usage public
keeptempfiles = keeptempfiles or {"*.mtx", "*.pl", "*-pltotf.sh", "*-rec.tex", "*.vpl", "*.zz"}
-- \TeX{} files to compile to produce map file fragments etc.
---@see fontinst()
---@usage public
mapmakers = mapmakers or {"*-map.tex"}
-- vendor and module must be specified before tdslocations
---@usage public
vendor = vendor or "public"
tdslocations = {
	"fonts/afm/" .. vendor .. "/" .. module .. "/" .. "*.afm",
	"fonts/enc/dvips/" .. module .. "/" .. "*.enc",
	"fonts/map/dvips/" .. module .. "/" .. "*.map",
	"fonts/opentype/" .. vendor .. "/" .. module .. "/" .. "*.otf",
	"fonts/tfm/" .. vendor .. "/" .. module .. "/" .. "*.tfm",
	"fonts/truetype/" .. vendor .. "/" .. module .. "/" .. "*.ttf",
	"fonts/type1/" .. vendor .. "/" .. module .. "/" .. "*.pfb",
	"fonts/type1/" .. vendor .. "/" .. module .. "/" .. "*.pfm",
	"fonts/vf/" .. vendor .. "/" .. module .. "/" .. "*.vf",
	"source/fonts/" .. module .. "/" .. "*.etx",
	"source/fonts/" .. module .. "/" .. "*.mtx",
	"source/fonts/" .. module .. "/" .. "*-drv.tex",
	"source/fonts/" .. module .. "/" .. "*-map.tex",
	"tex/latex/" .. module .. "/" .. "*.fd",
	"tex/latex/" .. module .. "/" .. "*.sty"
}
typesetsourcefiles = {keepdir .. "/*"}
-------------------------------------------------
-------------------------------------------------
-------------------------------------------------
-- vim: ts=2:sw=2:et:foldmethod=marker:
