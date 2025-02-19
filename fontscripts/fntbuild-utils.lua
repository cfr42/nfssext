-- $Id: fntbuild-utils.lua 10818 2025-02-19 05:44:13Z cfrees $
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
local os_newline_cp = "\n"
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
local function localtexmf()
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
local function dep_install(deps)
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
local function lsrdir_aux (path,filenames)
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
local function lsrdir (path,filenames)
  local filenames = filenames or {}
  filenames = lsrdir_aux (path,filenames)
  return filenames
end
-- }}}
-------------------------------------------------
-- local copio_aux {{{
---Copy files or directory contents recursively.
---@return 0, table of names on success, error level otherwise 
---@see copio
---@param path string
---@param dest string
---@param filenames table
---@param indent string
---@param patt string
---@usage private
local function copio_aux (path,dest,filenames,indent,patt)
  indent = indent .. "  "
  patt = patt or ".*"
  local attr = lfs.attributes (path)
  if attr.mode == "directory" then
    for file in lfs.dir(path) do
      if file ~="." and file ~=".." then
        local attri = lfs.attributes (path .. "/" .. file)
        assert (type(attri) == "table")
        if attri.mode == "directory" then
          copio_aux (path .. "/" .. file,dest,filenames,"",patt)
        elseif string.match(file,patt) then
          table.insert(filenames,file)
          cp(file,path,dest)
        end
      end
    end
  end
  return filenames
end
-- }}}
-------------------------------------------------
-- local copio {{{
---@description Copy files or directory contents recursively.
---@description Optionally use kpse lookup if not found.
---@return 0 on success 
---@see copio_aux, fntbuild-check, fntbuild-build (buildinit_fontinst) 
---@param locs table
---@param dest string
---@param kpsevar string
---@param patt string
---@param ls boolean
---@param filenames table
---@usage private
local function copio (locs,dest,kpsevar,patt)
  assert(locs ~= nil)
  if type(locs) == "string" then locs = { locs } end
  assert(#locs > 0)
  assert(direxists(dest))
  kpsevar = kpsevar or "TEXMFDIST"
  patt = patt or ".*"
  local filenames = {}
  local root = ""
  if kpsevar ~= "" then
    root = kpse.var_value(kpsevar) .. "/"
  end
  for _,path in ipairs(locs) do
    local file = basename(path)
    local attr = lfs.attributes (path)
    if type(attr) ~= "table" then
      path = root .. (string.gsub(path,"^/",""))
      attr = lfs.attributes (path)
    end
    assert(type(attr) == "table")
    if attr.mode == "directory" then
      copio_aux(path,dest,filenames,"",patt)
    elseif file ~= "." and file ~= ".." and string.match(file,patt) then
      table.insert(filenames,file)
      cp(file,dirname(path),dest)
    end
  end
  if ls then 
    return filenames, 0
  else
    return 0
  end
end
-- }}}
-------------------------------------------------
-------------------------------------------------
-- build_config() {{{
---use fntbuild-config.lua if found
---@usage private
local function build_config()
  local configs = {}
  -- not sure what the correct test is here?
  -- if options["target"] .. "search" then
  if fnt.buildsearch then
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
-- map_cat_aux (frags,dir,mapfile,append) {{{
---@param frags table
---@param dir string 
---@param mapfile string
---@param append boolean
---@return 0 on success, number of errors otherwise
---@see 
---@usage private
local function map_cat_aux (frags,dir,mapfile,append)
  mapfile = mapfile or "pdftex.map"
  append = append or false
  if #frags == 0 then return 0 end
  if fileexists(dir .. "/" .. mapfile) and not append then 
    local errorlevel = rm(dir,mapfile) 
    fnt.gwall("Removal of ",dir .. "/" .. mapfile,errorlevel)
  end
  local m = assert(io.open(dir .. "/" .. mapfile,"a"))
  for _,i in ipairs(frags) do
    local f = assert(io.open(i,"rb"))
    local l = f:read("*all")
    f:close()
    m:write(l)
  end
  m:close()
  return 0
end
-- }}}
-------------------------------------------------
-- map_cat_sys (frags,dir,mapfile,append) {{{
---@param frags table
---@param dir string 
---@param mapfile string
---@param append boolean
---@return 0 on success, number of errors otherwise
---@see 
---@usage private
local function map_cat_sys (frags,dir,mapfile,append)
  mapfile = mapfile or "pdftex.map"
  append = append or false
  local n = 0
  if #frags == 0 then 
    frags = { "cm.map", "cm-super-t1.map", "cm-super-ts1.map", "lm.map" }
  end
  if #fnt.mapfiles_add ~= 0 then
    for _,i in ipairs(fnt.mapfiles_add) do
      table.insert(frags,i)
    end
  end
  local ffrags = {}
  if #frags ~= 0 then
    for _,i in ipairs(frags) do
      -- kpse.find_file assumes filetype tex i.e. ignores file ext.
      local ff = kpse.find_file(i,"map")
      if ff ~= "" then
        table.insert(ffrags,ff)
      else
        fnt.gwall("Search for map fragment ",i,1)
        n = n + 1
      end
    end
    frags = ffrags
  end
  n = n + map_cat_aux(frags,dir,mapfile,append)
  return n
end
-- }}}
-------------------------------------------------
-- map_cat_pkg (frags,dir,mapfile,append) {{{
---@param frags table
---@param fragdir string 
---@param dir string 
---@param mapfile string
---@param append boolean
---@return 0 on success, number of errors otherwise
---@see 
---@usage private
local function map_cat_pkg (frags,fragdir,dir,mapfile,append)
  mapfile = mapfile or "pdftex.map"
  append = append or true
  local n = 0
  if #frags == 0 then return 0 end
  -- abspath() only works for directories
  for i,j in ipairs(frags) do 
    if fileexists(j) then 
      frags[i] = abspath(dirname(j) .. "/" .. basename(j))
    elseif fileexists(fragdir .. "/" .. j) then
      frags[i] = abspath(fragdir) .. "/" .. j
    elseif fileexists(dir .. "/" .. j) then
      frags[i] = abspath(dir) .. "/" .. j 
    else
      fnt.gwall("Finding mapfile fragment ",j,1)
      frags[i] = nil
      n = n + 1
    end
  end
  if #frags == 0 then return n end
  return map_cat_aux(frags,dir,mapfile,append)
end
-- }}}
-------------------------------------------------
-------------------------------------------------
-- exports {{{
fnt.build_config = build_config
fnt.copio = copio
fnt.dep_install = dep_install
fnt.localtexmf = localtexmf
fnt.lsrdir = lsrdir
fnt.os_newline_cp = os_newline_cp
fnt.map_cat_pkg = map_cat_pkg
fnt.map_cat_sys = map_cat_sys
-------------------------------------------------
-------------------------------------------------
-- vim: ts=2:sw=2:et:foldmethod=marker:
