-- $Id: build.lua 10545 2024-10-30 02:24:39Z cfrees $
-- Build configuration for electrumadf
-- l3build.pdf listing 1 tudalen 9
--[[
	os.setenv requires shell-escape (which l3build always enables) but will 
	*appear** to set the variable anyway i.e will report the value even though
	it isn't set
	os.execute("env") can be used to show the environment
	os.setenv is luatex and not in the standard builtin os lua library
	ref. https://tex.stackexchange.com/questions/720446/how-can-i-export-variables-to-the-environment-when-running-l3build?noredirect=1#comment1791863_720446
--]]
os.setenv ("PATH", "/usr/local/texlive/bin:/usr/bin:")
os.setenv ("TEXMFHOME", ".")
os.setenv ("TEXMFLOCAL", ".")
os.setenv ("TEXMFARCH", ".")
--
ctanpkg = "electrumadf"
maindir = "../.."
module = "electrum"
vendor = "arkandis"
autotestfds = {  "t1yes.fd", "t1yesj.fd", "t1yesjw.fd", "t1yesw.fd" }
textfiles = {"*.md","*.txt","COPYING"}
dofile(maindir .. "/fontinst.lua")
-- local srcfiles = {"dotsc2.etx", "dotscbuild.mtx", "dotscmisc.mtx", "newlatin-dotsc.mtx", "t1-dotinf.etx", "t1-dotsup.etx", "ts1-dotinf.etx", "ts1-dotsup.etx"}
-- for i,j in ipairs(srcfiles) do table.insert(sourcefiles,j) end
typesetdeps = {maindir .. "/nfssext-cfr"}
unpackdeps = {maindir .. "/fontscripts"}
--
uploadconfig = {
  -- *required* --
  -- announcement (don't include here?)
	author     = "Hirwen Harendal; Clea F. Rees",
  -- email (don't include here!)
	ctanPath   = "/fonts/electrumadf",
	license    = {"lppl1.3c","GPL 2 with font exception"},
	pkg        = ctanpkg,
	summary    = "Support for ElectrumADF on 8-bit engines",
  uploader   = "Clea F. Rees",
	version    = "v1.1",
  -- optional --
	bugtracker = {"https://codeberg.org/cfr/nfssext/issues"},
  -- description
  -- development {}
  -- home {}
	note       = "The catalogue currently shows the package as included only in MikTeX, but it is also included in TeX Live. Any chance this could be corrected?",
	repository = {"https://codeberg.org/cfr/nfssext", "https://github.com/cfr42/nfssext"},
  -- support {}
	topic      = {"font", "font-type1"},
	update     = true,
  -- files --
  -- announcement_file
  -- note_file
  -- curlopt_file
}
--
dofile(maindir .. "/arkandis/arkandis-manifest.lua")
-- beth sy'n digwydd pe taswn i'n newid ...?
-- l3build-unpack.lua
---------------------------------------------------------------------
---------------------------------------------------------------------
-- Unpack the package files using an 'isolated' system: this requires
-- a copy of the 'basic' DocStrip program, which is used then removed
function unpack(sources, sourcedirs)
  local errorlevel = dep_install(unpackdeps)
  if errorlevel ~= 0 then
    return errorlevel
  end
  errorlevel = bundleunpack(sourcedirs, sources)
  if errorlevel ~= 0 then
    return errorlevel
  end
  for _,i in ipairs(installfiles) do
    errorlevel = cp(i, unpackdir, localdir)
    if errorlevel ~= 0 then
      return errorlevel
    end
  end
  return 0
end

-- Split off from the main unpack so it can be used on a bundle and not
-- leave only one modules files
function bundleunpack(sourcedirs, sources)
  local errorlevel = mkdir(localdir)
  if errorlevel ~=0 then
    return errorlevel
  end
  errorlevel = cleandir(unpackdir)
  if errorlevel ~=0 then
    return errorlevel
  end
  local errorlevel = dep_install(unpackdeps)
  if errorlevel ~= 0 then
    return errorlevel
  end
  for _,i in ipairs(sourcedirs or {sourcefiledir}) do
    for _,j in ipairs(sources or {sourcefiles}) do
      for _,k in ipairs(j) do
        errorlevel = cp(k, i, unpackdir)
        if errorlevel ~=0 then
          return errorlevel
        end
      end
    end
  end
  for _,i in ipairs(unpacksuppfiles) do
    errorlevel = cp(i, supportdir, localdir)
    if errorlevel ~=0 then
      return errorlevel
    end
  end
  local popen = io.popen
  for _,i in ipairs(unpackfiles) do
    for _,p in ipairs(tree(unpackdir, i)) do
      local path, name = splitpath(p.src)
      local localdir = abspath(localdir)
      local success = assert(popen(
        "cd " .. unpackdir .. "/" .. path .. os_concat ..
        os_setenv .. " TEXINPUTS=." .. os_pathsep
          .. localdir .. (unpacksearch and os_pathsep or "") ..
        os_concat  ..
        os_setenv .. " LUAINPUTS=." .. os_pathsep
          .. localdir .. (unpacksearch and os_pathsep or "") ..
        os_concat ..
        unpackexe .. " " .. unpackopts .. " " .. name
          .. (options["quiet"] and (" > " .. os_null) or ""),
        "w"
      ):write(string.rep("y\n", 300))):close()
      if not success then
        return 1
      end
    end
  end
  return 0
end
---------------------------------------------------------------------
---------------------------------------------------------------------
-- os.execute ("printenv")
-- vim: ts=2:sw=2:tw=80:nospell
