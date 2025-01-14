-- $Id: fntbuild-utils.lua 10718 2025-01-14 01:55:38Z cfrees $
-------------------------------------------------
-- fntbuild-utils
-------------------------------------------------
-------------------------------------------------
-- l3build duplicates
-------------------------------------------------
-- copy non-public things from l3build
-- these are just copied because they aren't documented
-- so we duplicate them as we're not entitled to use them o/w
-- I've tried to eliminate local shorthands for clarity
-- should these all be local?  or renamed? or both?
-------------------------------------------------
-- os_newline_cp {{{
os_newline_cp = "\n"
if os.type == "windows" then
  if tonumber(status.luatex_version) < 100 or
     (tonumber(status.luatex_version) == 100
       and tonumber(status.luatex_revision) < 4) then
    os_newline_cp = "\r\n"
  end
end
-- }}}
-------------------------------------------------
-- localtexmf {{{
-- from l3build-aux.lua
-- Construct a localtexmf including any tdsdirs
-- Needed for checking and typesetting, hence global
function localtexmf()
  local paths = ""
  for src,_ in pairs(tdsdirs) do
    paths = paths .. os_pathsep .. abspath(src) .. "//"
  end
  if texmfdir and texmfdir ~= "" and direxists(texmfdir) then
    paths = paths .. os_pathsep .. abspath(texmfdir) .. "//"
  end
  return paths
end
-- }}}
-------------------------------------------------
-- get_script_name {{{
local function get_script_name()
  if string.match(arg[0], "l3build$") or string.match(arg[0], "l3build%.lua$") then
    return kpse.lookup("l3build.lua")
  else
    return arg[0] -- Why no lookup here?
  end
end
-- }}}
-------------------------------------------------
-- dep_install {{{
---@param 
---@return 
---@see 
---@usage 
function dep_install(deps)
  local error_level
  for _, dep in ipairs(deps) do
    print("Installing dependency:", dep)
    error_level = run(dep, "texlua " .. get_script_name() .. " unpack -q")
    if error_level ~= 0 then
      return error_level
    end
  end
  return 0
end
-- }}}
-------------------------------------------------
-------------------------------------------------
-- additions
-------------------------------------------------
-- lsrdir_aux {{{
---@param path string
---@param filenames table
---@return table 
---@see 
---@usage private
function lsrdir_aux (path,filenames)
  for file in lfs.dir(path) do
    if file ~= "." and file ~= ".." then
      local f = path .. "/" .. file
      local attr = lfs.attributes (f)
      -- why is this necessary?
      -- lfs.attributes does or doesn't return a table?
      -- David Carlisle: poss. nil rather than table
      -- -> assert then gives error
      assert (type(attr) == "table")
      if attr.mode == "directory" then
        lsrdir_aux (f,filenames)
      else
        table.insert(filenames,file)
      end
    end
  end
  return filenames
end
-- }}}
-- lsrdir {{{
-- https://lunarmodules.github.io/luafilesystem/examples.html
---@param path string
---@param filenames table
---@return table 
---@see 
---@usage public
function lsrdir (path,filenames)
  local filenames = filenames or {}
  filenames = lsrdir_aux (path,filenames)
  return filenames
end
-- }}}
-------------------------------------------------
-- build_config() {{{
---use fntbuild-config.lua if found
---@usage private
function build_config()
  local configs = {}
  -- not sure what the correct test is here?
  -- if options["target"] .. "search" then
  if buildsearch then
    local f = kpse.find_file("fntbuild-config.lua")
    if f ~= nil then
      dofile(f)
      print("\nWARNING: Using local configuration from", f 
      .. ".\nYour package may not build elsewhere.\n")
      table.insert(configs,f)
    end
  end
  if fileexists(maindir .. "/fntbuild-config.lua") then
    dofile(maindir .. "/fntbuild-config.lua")
    print("\nUsing local configuration from", maindir 
    .. "/fntbuild-config.lua.\nEnsure this is included when publishing sources.\n")
    table.insert(configs,maindir .. "/fntbuild-config.lua")
  end
  if fileexists(sourcefiledir .. "/fntbuild-config.lua") then
    dofile(sourcefiledir .. "/fntbuild-config.lua")
    print("\nUsing local configuration from", sourcefiledir 
    .. "/fntbuild-config.lua.\nEnsure this is included when publishing sources.\n")
    table.insert(configs,sourcefiledir .. "/fntbuild-config.lua")
  end
  if #configs == 0 then
    print("\nNo fntbuild-config.lua found.\nUsing defaults.\n")
  end
  return 0
end
-- }}}
-------------------------------------------------
-------------------------------------------------
-- vim: ts=2:sw=2:et:foldmethod=marker:
