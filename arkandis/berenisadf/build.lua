-- $Id: build.lua 10306 2024-09-01 19:01:55Z cfrees $
-- Build configuration for berenisadf
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
ctanpkg = "berenisadf"
maindir = "../.."
module = "berenis"
vendor = "arkandis"
autotestfds = {  "ly1ybd.fd", "ly1ybd0.fd", "ly1ybd1.fd", "ly1ybd2.fd", "ly1ybd2j.fd", "ly1ybd2jw.fd", "ly1ybd2w.fd", "ly1ybdj.fd", "ly1ybdjw.fd", "ly1ybdw.fd", "t1ybd.fd", "t1ybd0.fd", "t1ybd1.fd", "t1ybd2.fd", "t1ybd2j.fd", "t1ybdj.fd" }
keepfiles = { "ybd.map", "*.pfb", "*.tfm" }
keeptempfiles = { "*.pl" }
dofile(maindir .. "/fontinst.lua")
function fntkeeper ()
  local dir = dir or unpackdir
  local rtn = direxists(keepdir)
  if rtn ~= 0 then
    local errorlevel = mkdir(keepdir)
    if errorlevel ~= 0 then
      print("DO NOT BUILD STANDARD TARGETS WITHOUT RESOLVING!!\n")
      gwall("Attempt to create directory ", keepdir, errorlevel)
    end
  end
  if keepfiles ~= {} then
    for i,j in ipairs(keepfiles) do
      local rtn = cp(j, unpackdir, keepdir)
      if rtn ~= 0 then
        gwall("Copy ", j, errorlevel)
        print("DO NOT BUILD STANDARD TARGETS WITHOUT RESOLVING!\n")
      end
    end
  else
    print("ARE YOU SURE YOU DON'T WANT TO KEEP THE FONTS??!!\n")
  end
  if keeptempfiles ~= {} then
    rtn = direxists(keeptempdir)
    if rtn ~= 0 then
      local errorlevel = mkdir(keeptempdir)
      if errorlevel ~= 0 then
        gwall("Attempt to create directory ", keeptempdir, errorlevel)
      end
    end
    for i,j in ipairs(keeptempfiles) do 
      local errorlevel = cp(j,unpackdir,keeptempdir)
      if errorlevel ~= 0 then
        gwall("Copy ", j, errorlevel)
      end
    end
  end	
  return nifergwall
end
function fntmake (dir,mode)
  dir = dir or unpackdir
  mode = mode or "errorstopmode --halt-on-error"
  print("Unpacking ...\n")
  local errorlevel = unpack()
  print("Running make. Please be patient ...\n")
  errorlevel = run(dir, "chmod +x ff-ybd.pe")
  if errorlevel ~=0 then
    gwall("Attempt to make fontforge script executable ", unpackdir, errorlevel)
  else
    errorlevel = run(dir, "make -f Makefile.make all")
    if errorlevel ~= 0 then
      gwall("make ", unpackdir, errorlevel)
    end
    errorlevel = fntkeeper()
    if errorlevel ~= 0 then
      gwall("FONT KEEPER FAILED! DO NOT MAKE STANDARD TARGETS WITHOUT RESOLVING!! ", unpackdir, errorlevel)
    end
  end
  return nifergwall
end
-- fntmake must be specified first
-- it just ain't TeX
target_list[ntarg] = {
  func = fntmake,
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
-- docfiles = { "dotoldstyle.etx", "dottaboldstyle.etx", "t1-cfr.etx", "t1-dotinferior.etx", "t1-dotsuperior.etx", "ybd-encs.tex" }
local srcfiles = { "dotoldstyle.etx", "dottaboldstyle.etx", "t1-cfr.etx", "t1-dotinferior.etx", "t1-dotsuperior.etx", "ybd-encs.tex" }
for i,j in ipairs(srcfiles) do table.insert(sourcefiles,j) end
typesetruns = 5
--
uploadconfig = {
  -- *required* --
  -- announcement (don't include here?)
	author     = "Hirwen Harendal; Clea F. Rees",
  -- email (don't include here!)
	ctanPath   = "fonts/berenisadf",
	license    = {"lppl1.3c","GPL 2 with font exception"},
	pkg        = ctanpkg,
	summary    = "Support for BerenisADF on 8-bit engines",
  uploader   = "Clea F. Rees",
	version    = "v2.1",
  -- optional --
	bugtracker = {"https://codeberg.org/cfr/nfssext/issues"},
  -- description
  -- development {}
  -- home {}
	-- repository = {"https://codeberg.org/cfr/nfssext", "https://github.com/cfr42/nfssext"},
	note = "Repository mirrored at https://github.com/cfr42/nfssext",
	repository = "https://codeberg.org/cfr/nfssext",
  -- support {}
	topic      = {"font", "font-type1", "font-otf", "font-serif"},
	update     = true,
  -- files --
  -- announcement_file
  -- note_file
  -- curlopt_file
}
--
dofile(maindir .. "/arkandis/arkandis-manifest.lua")
-- os.execute ("printenv")
-- vim: ts=2:sw=2:tw=80:nospell
