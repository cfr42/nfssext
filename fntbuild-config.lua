-- $Id: fntbuild-config.lua 11692 2026-02-25 04:38:01Z cfrees $
-- configuration for nfssext
-------------------------------------------------
sourcefiledir = sourcefiledir or "."
maindir = maindir or ".." 
bakext = ".bkup"
checkdeps = {maindir .. "/nfssext-cfr", maindir .. "/fontscripts"}
ctanreadme = "README.md"
demofiles = {"*-example.tex"}
flatten = true
flattentds = false
manifestfile = "manifest.txt"
packtdszip = false
tagfiles = {"*.dtx", "*.ins", "manifest.txt", "MANIFEST.txt", "README", "README.md"}
typesetdeps = {maindir .. "/nfssext-cfr", maindir .. "/fontscripts"}
-- use only where we don't need to find clm
-- typesetopts = "-interaction=nonstopmode -cnf-line='TEXMFHOME=.' -cnf-line='TEXMFLOCAL=.' -cnf-line='TEXMFARCH=.'"
typesetopts = "-interaction=nonstopmode -cnf-line='TEXMFARCH=.'"
typesetsourcefiles = {fnt.keepdir .. "/*", "nfssext-cfr*.sty"}
unpackexe = "pdflatex"
unpackfiles = {"*.ins"}
-------------------------------------------------
fnt.builddeps = { maindir .. "/fontscripts" } 
fnt.checksuppfiles_add = {
  "/fonts/enc/dvips/lm",
  "/fonts/tfm/public/lm",
  "/fonts/type1/public/lm",
  "etoolbox.sty",
  "ly1enc.def",
  "ly1enc.dfu",
  "ly1lmr.fd",
  "ly1lmss.fd",
  "ly1lmtt.fd",
  "omllmm.fd",
  "omllmr.fd",
  "omslmr.fd",
  "omslmsy.fd",
  "omxlmex.fd",
  "ot1lmr.fd",
  "ot1lmss.fd",
  "ot1lmtt.fd",
  "svn-prov.sty",
  "ts1lmdh.fd",
  "ts1lmr.fd",
  "ts1lmss.fd",
  "ts1lmssq.fd",
  "ts1lmtt.fd",
  "ts1lmvtt.fd",
}
-------------------------------------------------
-- local buildinit_hook() {{{
local function buildinit_hook()
  local t = {"etx","mtx"}
  for _,i in ipairs(t) do
    local files = filelist(fnt.fntdir,"fontscripts-*." .. i)
    for _,j in ipairs(files) do
      local k = (string.gsub(j,"^fontscripts%-",""))
      if not fileexists(fnt.fntdir .. "/" .. k) then
        ren(fnt.fntdir,j,k)
        for n,m in ipairs(fnt.buildsuppfiles_sys) do
          if m == j then
            fnt.buildsuppfiles_sys[n] = k
          end
        end
      end
    end
  end
  return 0
end
-- }}}
-------------------------------------------------
-- tag.lua
tagfile = tagfile or maindir .. "/tag.lua"
if fileexists(tagfile) then
  dofile(tagfile)
end
-------------------------------------------------
local function docmetadata ()
  for _,i in ipairs({
    "/tex/latex/latex-lab",
    "/tex/latex/pdfmanagement-testphase",
    "/tex/latex/tagpdf",
    "/tex/latex/amsmath",
    "/tex/luatex/luaotfload",
    "/tex/luatex/luatexbase",
    "/tex/luatex/lualibs",
    "/tex/luatex/lua-uni-algos",
    "/tex/generic/unicode-data",
    "ltluatex.lua",
    "ltluatex.tex",
    "array.sty",
    "glyphtounicode.tex",
    "lualatexquotejobname.lua",
    "expl3.lua",
  }) do
    table.insert(fnt.checksuppfiles_add, i)
  end
end
local function suppluafiles ()
  for _,i in ipairs({
    "/tex/latex/amsmath",
    "/tex/luatex/luaotfload",
    "/tex/luatex/luatexbase",
    "/tex/luatex/lualibs",
    "/tex/luatex/lua-uni-algos",
    "/tex/generic/unicode-data",
    "ltluatex.lua",
    "ltluatex.tex",
    "lualatexquotejobname.lua",
    "expl3.lua",
  }) do
    table.insert(fnt.checksuppfiles_add, i)
  end
end
local function suppxefiles ()
  for _,i in ipairs({
    "lmroman10-regular.otf",
  }) do
    table.insert(fnt.checksuppfiles_add, i)
  end
end
-------------------------------------------------
fnt.buildinit_hook = buildinit_hook
fnt.docmetadata = docmetadata
fnt.suppluafiles = suppluafiles
fnt.suppxefiles = suppxefiles
-------------------------------------------------
-------------------------------------------------
-- vim: ts=2:sw=2:et:foldmethod=marker:
