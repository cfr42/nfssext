-- $Id: build.lua 10974 2025-03-28 20:14:48Z cfrees $
-------------------------------------------------
-- Build configuration for berenisadf
-------------------------------------------------
-- l3build.pdf listing 1 tudalen 9
-- ref. https://tex.stackexchange.com/questions/720446/how-can-i-export-variables-to-the-environment-when-running-l3build?noredirect=1#comment1791863_720446
-------------------------------------------------
ctanpkg = "berenisadf"
maindir = "../.."
module = "berenis"
fnt = {}
fnt.vendor = "arkandis"
fnt.autotestfds = {  "ly1ybd.fd", "ly1ybd2.fd", "ly1ybd2j.fd", "ly1ybd2jw.fd", "ly1ybd2w.fd", "ly1ybdj.fd", "ly1ybdjw.fd", "ly1ybdw.fd", "t1ybd.fd", "t1ybd2.fd", "t1ybd2j.fd", "t1ybdj.fd" }
fnt.keepfiles = { "ybd.map", "*.afm", "*.pfb", "*.tfm" , "ts1ybd2w.fd", "ts1ybd2jw.fd", "ts1ybdjw.fd", "ts1ybdw.fd" }
fnt.keeptempfiles = { "*.pl" }
dofile(maindir .. "/fontscripts/fntbuild.lua")
-------------------------------------------------
-- START doc eg
-- require(kpse.lookup("fntbuild.lua"))
local function fntmake (dir,mode)
  dir = dir or fnt.fntdir
  mode = mode or "errorstopmode --halt-on-error"
  local autotcfds ={ "ts1ybd2j.fd", "ts1ybd2.fd", "ts1ybdj.fd", "ts1ybd.fd" }
  -- set up the build environment
  assert(fnt.buildinit(), "Setting up build environment failed!")
  print("Running make. Please be patient ...\n")
  assert(run(dir, "chmod +x ff-ybd.pe"),"Attempt to make fontforge script executable in " .. dir .. " failed.")
  assert(run(dir, "make -f Makefile.make all"), '"make -f Makefile.make all" failed in ' .. dir .. '.')
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
    -- normalise line endings to be platform-agnostic
    -- copied from l3build
    content = string.gsub(content .. (string.match(content,"\n$") and "" or "\n"),
    "\r\n", "\n") 
    local new_content = string.gsub(content, 
    "{" .. jfam .. "}", "{" .. jnewfam .. "}")
    new_content = string.gsub(new_content, "(ts1[^%.]*)(%.fd)", "%1w%2")
    new_content = string.gsub(new_content, "(TS1/ybd[a-z0-9]*)", "%1w")
    f = assert(io.open(dir .. "/" .. jnew,"w"))
    f:write((string.gsub(new_content,"\n",fnt.os_newline_cp)))
    f:close()
  end
  -- call fnt.fntkeeper() to save the build results into fnt.keepdir else
  -- l3build deletes them before testing or compilation!
  assert(fnt.fntkeeper(),"FONT KEEPER FAILED IN " .. dir .. "! DO NOT MAKE STANDARD TARGETS WITHOUT RESOLVING!! ")
  return 0
end
-- make local function available in table bt
bt = {}
bt.fntmake = fntmake
-- redefine fnt.ntarg so that fnttarg calls bt.fntmake rather than fontinst
-- fntmake must be specified first
-- it just ain't TeX
target_list[fnt.ntarg] = {
  func = bt.fntmake,
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
-------------------------------------------------
unpackdeps = {maindir .. "/fontscripts"}
textfiles = {"*.md", "*.txt", "COPYING"}
typesetdeps = {maindir .. "/nfssext-cfr"}
typesetopts = "-interaction=nonstopmode -cnf-line='TEXMFHOME=.' -cnf-line='TEXMFLOCAL=.' -cnf-line='TEXMFARCH=.'"
typesetruns = 5
-------------------------------------------------
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
-------------------------------------------------
arkandisfiles = {"*.otf","NOTICE*","COPYING"}
arkandisders = {"*.afm","*.pfb","*.pfm"}
date = "2010-2025"
dofile(maindir .. "/arkandis/arkandis-manifest.lua")
-------------------------------------------------
-- vim: ts=2:sw=2:tw=80:nospell
