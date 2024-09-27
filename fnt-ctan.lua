-- $Id: fnt-ctan.lua 10399 2024-09-27 02:16:30Z cfrees $
-------------------------------------------------
local exts = {}

-------------------------------------------------
-- origcopyctan()
-- copy David Carlisle
origcopyctan = copyctan

-------------------------------------------------
-- extname(filename)
function extname(filename)
  local b = basename(filename)
  ext = string.gsub(b, "^[^%.]*%.", "")
  if ext == nil then
    gwall("Failed to get extension ",ext,1)
  end 
  return ext
end
-------------------------------------------------
-- copysubctan(files,srcdir,targdir)
function copysubctan(files,srcdir,targdir)
  local errorlevel
  local extdir
  if not direxists(targdir) then
    errorlevel = mkdir(targdir)
    if errorlevel ~= 0 then return errorlevel end
  end
  for i,j in ipairs(files) do
    local ext = extname(j)
    if exts[ext] == nil then
      extdir = ext
      exts[ext] = ext
    else
      extdir = exts[ext]
    end
    if not direxists(targdir .. "/" .. extdir) then
      errorlevel = mkdir(targdir .. "/" .. extdir)
      if errorlevel ~= 0 then return errorlevel end
    end
    errorlevel = cp(j,srcdir,targdir .. "/" .. extdir)
    if errorlevel ~= 0 then return errorlevel end
  end
  return 0
end
-------------------------------------------------
-- copyctan()
function copyctan()
  local keepdir = keepdir or sourcefiledir .. "/keep" 
  local errorlevel
  local targdir = ctandir .. "/" .. ctanpkg
  keptfiles = {}
  if #exts == 0 then exts = {"afm","dtx","enc","fd","ins","map","md","otf","pdf","pfb","pfm","tex","tfm","txt","vf"} end
  if not exts["pfb"] then exts["pfb"] = "type1" end
  if not exts["pfm"] then exts["pfm"] = "type1" end
  if not exts["ttf"] then exts["ttf"] = "truetype" end
  if not exts["otf"] then exts["otf"] = "opentype" end
  if not exts["fd"] then exts["fd"] = "latex" end
  if not exts["dtx"] then exts["dtx"] = "source" end
  if not exts["ins"] then exts["ins"] = "source" end
  if not exts["md"] then exts["md"] = "doc" end
  if not exts["txt"] then exts["txt"] = "doc" end
  if not exts["tex"] then exts["tex"] = "doc" end
  if not exts["pdf"] then exts["pdf"] = "doc" end
  for i,j in ipairs(filelist(keepdir,"*.*")) do
    if j ~= "." and j ~= ".." then
      table.insert(keptfiles,j)
    end
  end
  copysubctan(keptfiles,keepdir,targdir)
  origcopyctan()
  local g = {}
  for i,j in ipairs(exts) do
    local f = filelist(targdir,"*." .. j)
    if #f ~= 0 then
      for m,n in ipairs(f) do
        if n ~= "README.md" and n ~= "README" then
          table.insert(g,n)
        end
      end
    end
  end
  if #g ~= 0 then
    errorlevel = copysubctan(g,targdir,targdir)
    if errorlevel ~= 0 then return errorlevel end
  end
  for i,j in ipairs(exts) do
    errorlevel = rm(targdir, "*." .. j)
    if errorlevel ~= 0 then return errorlevel end
  end
  if fileexists(targdir .. "/COPYING") then
    if not direxists(targdir .. "/doc") then mkdir(targdir .. "/doc") end
    errorlevel = cp("COPYING",targdir,targdir .. "/doc")
    if errorlevel ~= 0 then return errorlevel end
    errorlevel = rm(targdir, "COPYING")
    if errorlevel ~= 0 then return errorlevel end
  end
  -- this is horrible: ctan() copies all the files, we deal with them, and then it copies all the textfiles a second time!
  textfiles = {"README","README.md"}
  return 0
end
-- end copyctan()
-------------------------------------------------

-- vim: ts=2:sw=2:et:
