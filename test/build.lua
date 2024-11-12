-- $Id: build.lua 10612 2024-11-12 17:21:11Z cfrees $
-- Build configuration for testadf
ctanpkg = "testadf"
module = "test"
vendor = "arkandis"
maindir = ".."
-- buildsuppfiles_sys = {"fontinst.sty"}
dofile("../fntbuild.lua")
-- flatten = false
installfiles = {"*.afm", "*.cls", "*.enc", "*.fd", "*.map", "*.otf", "*.pfb", "*.sty", "*.tfm", "*.ttf", "*.vf"}
-- typesetfiles = {"test-test.tex"}
typesetdeps = {maindir .. "/nfssext-cfr", maindir .. "/cfr-lm"}
typesetruns = 1
uploadconfig = {
  -- *required* --
  -- announcement (don't include here?)
  author     = "Clea F. Rees",
  -- email (don't include here!)
  ctanPath   = "fonts/testadf",
  license    = {"lppl1.3c","GPL 2 with font exception"},
  pkg        = ctanpkg,
  summary    = "Support for TestADF on 8-bit engines",
  uploader   = "Clea F. Rees",
  version    = "v0.0",
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

function filch()
  -- avoid having to think about licences for H's work
  -- normally they'd either be here or I'd copy the lot
  -- equiv to:
  -- /usr/bin/mkdir -p ${srcdir}/afm && /usr/bin/cp $(kpsewhich yesr8a.afm) ${srcdir}/afm/xxxr8a.afm
  -- /usr/bin/mkdir -p ${srcdir}/type1 && /usr/bin/cp $(kpsewhich yesr8a.pfb) ${srcdir}/type1/xxxr8a.pfb
  local afm = kpse.find_file("yesr8a","afm")
  local pfb = kpse.find_file("yesr8a","type1 fonts")
  if not afm or not pfb then return 1 end
  local srcdir = sourcefiledir or "."
  local dafm = dirname(afm)
  afm = basename(afm)
  local xafm = string.gsub(afm,"yes","xxx")
  local dpfb = dirname(pfb)
  pfb = basename(pfb)
  local xpfb = string.gsub(pfb,"yes","xxx")
  local afmdir = srcdir .. "/afm"
  local pfbdir = srcdir .. "/type1"
  local errorlevel = direxists(afmdir) 
  if errorlevel ~=0 then mkdir(afmdir) end
  errorlevel = direxists(pfbdir)
  if errorlevel ~=0 then mkdir(pfbdir) end
  xafm = afmdir .. "/" .. xafm
  xpfb = pfbdir .. "/" .. xpfb
  cp(afm,dafm,xafm)     
  cp(pfb,dpfb,xpfb)
  errorlevel = fileexists(afmdir .. xafm)
  if errorlevel ~= 0 then return 1 end
  errorlevel = fileexists(prbdir .. xpfb)
  if errorlevel ~= 0 then return 1 end
  return 0
end
filch()

-- vim: ts=2:sw=2:tw=80:nospell:et
