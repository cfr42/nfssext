-- $Id: build.lua 10719 2025-01-14 01:57:23Z cfrees $
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
-------------------------------------------------
-- copy non-public things from l3build
local os_newline_cp = "\n"
if os.type == "windows" then
  if tonumber(status.luatex_version) < 100 or
     (tonumber(status.luatex_version) == 100
       and tonumber(status.luatex_revision) < 4) then
    os_newline_cp = "\r\n"
  end
end
-------------------------------------------------
ctanpkg = "berenisadf"
maindir = "../.."
module = "berenis"
vendor = "arkandis"
autotestfds = {  "ly1ybd.fd", "ly1ybd2.fd", "ly1ybd2j.fd", "ly1ybd2jw.fd", "ly1ybd2w.fd", "ly1ybdj.fd", "ly1ybdjw.fd", "ly1ybdw.fd", "t1ybd.fd", "t1ybd2.fd", "t1ybd2j.fd", "t1ybdj.fd" }
keepfiles = { "ybd.map", "*.afm", "*.pfb", "*.tfm" , "ts1ybd2w.fd", "ts1ybd2jw.fd", "ts1ybdjw.fd", "ts1ybdw.fd" }
keeptempfiles = { "*.pl" }
-- START doc eg
autotcfds ={ "ts1ybd2j.fd", "ts1ybd2.fd", "ts1ybdj.fd", "ts1ybd.fd" }
dofile(maindir .. "/fontscripts/fntbuild.lua")
function fntmake (dir,mode)
  dir = dir or fntdir
  mode = mode or "errorstopmode --halt-on-error"
  buildinit()
  print("Running make. Please be patient ...\n")
  errorlevel = run(dir, "chmod +x ff-ybd.pe")
  if errorlevel ~=0 then
    gwall("Attempt to make fontforge script executable ", dir, errorlevel)
  else
    errorlevel = run(dir, "make -f Makefile.make all")
    if errorlevel ~= 0 then
      gwall("make ", dir, errorlevel)
    end
    -- make ts1 swash families so tc commands pick up the characters in ly1
    -- we don't need t1 versions of these families as there's no room for swash
    -- there
    -- ideally, we could just tell latex to use the non-swash families for the
    -- tc encoding, but that doesn't seem possible without rewriting more
    -- internal stuff than seems altogether wise ...
    for i, j in ipairs(autotcfds) do
      local jfam = string.gsub(j, "^ts1(.*)%.fd$", "%1")
      local jnewfam = jfam .. "w"
      local jnew = string.gsub(j, "(%.fd)$", "w%1")
      local f = assert(io.open(dir .. "/" .. j,"rb"))
      local content = f:read("*all")
      f:close()
      -- ought to normalise line endings here 
      -- copied from l3build
      content = string.gsub(content .. (string.match(content,"\n$") and "" or "\n"),
        "\r\n", "\n"
      ) 
      local new_content = string.gsub(content, 
        "{" .. jfam .. "}", "{" .. jnewfam .. "}"
      )
      new_content = string.gsub(new_content, "(ts1[^%.]*)(%.fd)", "%1w%2")
      new_content = string.gsub(new_content, "(TS1/ybd[a-z0-9]*)", "%1w")
      f = assert(io.open(dir .. "/" .. jnew,"w"))
      -- this somehow removes the second value returned by string.gsub??
      f:write((string.gsub(new_content,"\n",os_newline_cp)))
      f:close()
    end
    errorlevel = fntkeeper()
    if errorlevel ~= 0 then
      gwall("FONT KEEPER FAILED! DO NOT MAKE STANDARD TARGETS WITHOUT RESOLVING!! ",
        dir, errorlevel
      )
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
-- STOP doc eg
-- docfiles = { "dotoldstyle.etx", "dottaboldstyle.etx", "t1-cfr.etx", "t1-dotinferior.etx", "t1-dotsuperior.etx", "ybd-encs.tex" }
-- local srcfiles = { "dotoldstyle.etx", "dottaboldstyle.etx", "t1-cfr.etx", "t1-dotinferior.etx", "t1-dotsuperior.etx" }
-- for i,j in ipairs(srcfiles) do table.insert(sourcefiles,j) end
unpackdeps = {maindir .. "/fontscripts"}
textfiles = {"*.md", "*.txt", "COPYING"}
typesetdeps = {maindir .. "/nfssext-cfr"}
typesetruns = 5
--
uploadconfig = {
  -- *required* --
  -- announcement (don't include here?)
	author     = "Hirwen Harendal; Clea F. Rees",
  -- email (don't include here!)
	ctanPath   = "/fonts/berenisadf",
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
	repository = {"https://codeberg.org/cfr/nfssext", "https://github.com/cfr42/nfssext"},
	note = "Repository mirrored at https://github.com/cfr42/nfssext",
	-- repository = "https://codeberg.org/cfr/nfssext",
  -- support {}
	topic      = {"font", "font-type1", "font-otf", "font-serif"},
	update     = true,
  -- files --
  -- announcement_file
  -- note_file
  -- curlopt_file
}
--
arkandisfiles = {"*.otf","NOTICE*","COPYING"}
arkandisders = {"*.afm","*.pfb","*.pfm"}
date = "2010-2025"
dofile(maindir .. "/arkandis/arkandis-manifest.lua")
-- os.execute ("printenv")
-- vim: ts=2:sw=2:tw=80:nospell
