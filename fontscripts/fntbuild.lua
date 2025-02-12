-- $Id: fntbuild.lua 10802 2025-02-12 20:11:33Z cfrees $
-------------------------------------------------
-------------------------------------------------
-- I don't know how to bootstrap this ... 
-- these are needed when fontscripts is part of the same repo
-------------------------------------------------
sourcefiledir = sourcefiledir or "."
maindir = maindir or sourcefiledir
-------------------------------------------------
-- namespace
---@usage ??
fnt = fnt or {}
-- error-tracking
---@usage private
fnt.nifergwall = 0
-- target names
-- fnttarg
---@usage private
local ntarg = "fnttarg"
-- uniquifyencs
---@usage private
local utarg = "uniquifyencs"
-------------------------------------------------
-- fnt.gwall {{{
---@param msg string 
---@param file string
---@param rtn number 
---@see 
---@usage private
function fnt.gwall (msg,file,rtn)
  file = file or "current file"
  msg = msg or "Error:"
  rtn = rtn or 0
  if rtn ~= 0 then 
    fnt.nifergwall = fnt.nifergwall + rtn
    print (msg, file, "failed (" .. rtn .. ")\n")
  end
end
-- }}}
-------------------------------------------------
-------------------------------------------------
local possplaces = { sourcefiledir, maindir, maindir .. "/fontscripts" }
for _,i in ipairs (possplaces) do
  if fileexists( i .. "/fntbuild.lua" ) then
    fnt.fntbuild_home = i
    break
  end
end
print("fnt.fntbuild_home:", fnt.fntbuild_home)
if fnt.fntbuild_home == nil then
  -- dwyn o Joseph Wright: l3build.lua
  -- ar gael am fod Joseph yn wneud kpse.set_program_name("kpsewhich")
  -- gweler texdoc luatex
  local p = kpse.find_file("fntbuild.lua", "lua")
  if p ~= nil and p ~= "" then
    fnt.fntbuild_home = dirname(p)
  else
    fnt.gwall("Search for ","self",1)
  end
end
-------------------------------------------------
print("Found myself in", fnt.fntbuild_home)
-------------------------------------------------
-- dwyn o Joseph Wright: l3build.lua
local function fntbuild_require (frag)
  require(kpse.lookup("fntbuild-" .. frag .. ".lua", { path = fnt.fntbuild_home }))
end
-------------------------------------------------
fntbuild_require("vars")
fntbuild_require("utils")
fntbuild_require("build")
fntbuild_require("check")
fntbuild_require("doc")
fntbuild_require("ctan")
-------------------------------------------------
-- load user config
-- local (if fnt.buildsearch) - maindir -- sourcefiledir
-------------------------------------------------
-- execute before testing afmtotfm so fnttarg is correct in case the 
-- config sets it true
fnt.build_config()
-------------------------------------------------
-------------------------------------------------
-- fontinst must be specified first
-- it just ain't TeX
-- ntarg {{{
target_list[ntarg] = {
	func = fnt.fontinst,
  desc = "Creates TeX font file",
  pre = function(names)
    if names then
      print("fontinst does not need names\n")
      help()
      exit(1)
    end
    return 0
  end
}
-- }}}
-- utarg {{{
target_list[utarg] = {
  func = fnt.uniquify,
  desc = "Uniquifies encodings ONLY",
  pre = function(names)
    fnt.standalone = true
    if names and #names > 1 then
      print("Too many encoding tags specified; no more than one allowed")
      help()
      exit(1)
    else
      names = names or fnt.encodingtag or ""
    end
    return 0
  end
}
-- }}}
-- diwedd targets
-------------------------------------------------
-------------------------------------------------
-- fnt.afmtotfm -> fnttarg {{{
if fnt.afmtotfm then
  target_list[ntarg] = {
    func = fnt.afm2tfm,
    desc = "Creates TeX font files",
    pre = function(names)
      if names then
        print("fntmake does not need names\n")
        help()
        exit(1)
      end
      return 0
    end
  }
end
-- }}}
-------------------------------------------------
-------------------------------------------------
if options["target"] == "install" then
  table.insert(sourcefiles,fnt.keepdir .. "/*.*")
end
-------------------------------------------------
-------------------------------------------------
-- override l3build functions {{{
checkinit_hook = fnt.checkinit_hook
copyctan = fnt.copyctan
docinit_hook = fnt.docinit_hook
-- }}}
-- other exports {{{
fnt.ntarg = ntarg
-- }}}
-------------------------------------------------
-------------------------------------------------
-- vim: ts=2:sw=2:et:foldmethod=marker:
