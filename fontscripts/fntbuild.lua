-- $Id: fntbuild.lua 10659 2024-11-21 06:49:20Z cfrees $
-------------------------------------------------
-------------------------------------------------
-- I don't know how to bootstrap this ... 
-- these are needed when fontscripts is part of the same repo
-------------------------------------------------
sourcefiledir = sourcefiledir or "."
maindir = maindir or sourcefiledir
-------------------------------------------------
-- error-tracking
---@usage private
nifergwall = 0
-- target names
-- fnttarg
---@usage private
ntarg = "fnttarg"
-- uniquifyencs
---@usage private
utarg = "uniquifyencs"
-------------------------------------------------
-- gwall {{{
---@param msg string 
---@param file string
---@param rtn number 
---@see 
---@usage private
function gwall (msg,file,rtn)
  file = file or "current file"
  msg = msg or "Error: "
  rtn = rtn or 0
  if rtn ~= 0 then 
    nifergwall = nifergwall + rtn
    print (msg .. file .. " failed (" .. rtn .. ")\n")
  end
end
-- }}}
-------------------------------------------------
-------------------------------------------------
local possplaces = { sourcefiledir, maindir, maindir .. "/fontscripts" }
for _,i in ipairs (possplaces) do
  if fileexists( i .. "/fntbuild.lua" ) then
    print(i)
    fntbuild_home = i
    break
  end
end
print(fntbuild_home)
if fntbuild_home == nil then
  -- dwyn o Joseph Wright: l3build.lua
  -- ar gael am fod Joseph yn wneud kpse.set_program_name("kpsewhich")
  -- gweler texdoc luatex
  local p = kpse.find_file("fntbuild.lua", "lua")
  if p ~= nil and p ~= "" then
    fntbuild_home = dirname(p)
  else
    gwall("Search for ","self",1)
  end
end
-------------------------------------------------
print("Found myself in " .. fntbuild_home)
-------------------------------------------------
-- dwyn o Joseph Wright: l3build.lua
local function fntbuild_require (frag)
  require(kpse.lookup("fntbuild-" .. frag .. ".lua", { path = fntbuild_home }))
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
-- local (if buildsearch) - maindir -- sourcefiledir
-------------------------------------------------
-- execute before testing afmtotfm so fnttarg is correct in case the config sets it true
build_config()
-------------------------------------------------
-------------------------------------------------
-- fontinst must be specified first
-- it just ain't TeX
-- ntarg {{{
target_list[ntarg] = {
	func = fontinst,
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
  func = uniquify,
  desc = "Uniquifies encodings ONLY",
  pre = function(names)
    standalone = true
    if names and #names > 1 then
      print("Too many encoding tags specified; no more than one allowed")
      help()
      exit(1)
    else
      names = names or encodingtag or ""
    end
    return 0
  end
}
-- }}}
-- diwedd targets
-------------------------------------------------
-------------------------------------------------
-- fnt_afmtotfm -> fnttarg {{{
if afmtotfm then
  target_list[ntarg] = {
    func = fnt_afmtotfm,
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
  table.insert(sourcefiles,keepdir .. "/*.*")
end
-------------------------------------------------
-------------------------------------------------
-- vim: ts=2:sw=2:et:foldmethod=marker:
