-- $Id: fntbuild-config.lua 10631 2024-11-14 05:26:44Z cfrees $
-- configuration for nfssext
-------------------------------------------------
sourcefiledir = sourcefiledir or "."
maindir = maindir or ".." 
bakext = ".bkup"
checkdeps = {maindir .. "/nfssext-cfr", maindir .. "/fnt-tests"}
ctanreadme = "README.md"
demofiles = {"*-example.tex"}
flatten = true
flattentds = false
manifestfile = "manifest.txt"
packtdszip = false
tagfiles = {"*.dtx", "*.ins", "manifest.txt", "MANIFEST.txt", "README", "README.md"}
typesetdeps = {maindir .. "/nfssext-cfr"}
typesetsourcefiles = {keepdir .. "/*", "nfssext-cfr*.sty"}
unpackexe = "pdflatex"
unpackfiles = {"*.ins"}
-------------------------------------------------
builddeps = { maindir .. "/fontscripts" } 
-------------------------------------------------
-- tag.lua
tagfile = tagfile or maindir .. "/tag.lua"
if fileexists(tagfile) then
  dofile(tagfile)
end
-------------------------------------------------
-------------------------------------------------
-- vim: ts=2:sw=2:et:foldmethod=marker:
