-- $Id: fntbuild-config.lua 10611 2024-11-12 17:12:11Z cfrees $
-- configuration for nfssext
-------------------------------------------------
sourcedir = sourcedir or "."
maindir = maindir or ".." 
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
