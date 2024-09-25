-- $Id: build.lua 10383 2024-09-25 15:45:11Z cfrees $
-- Build configuration for fontscripts
-- l3build.pdf listing 1 tudalen 9
os.setenv ("PATH", "/usr/local/texlive/bin:/usr/bin:")
os.setenv ("TEXMFHOME", ".")
os.setenv ("TEXMFLOCAL", ".")
os.setenv ("TEXMFARCH", ".")
--
module = "fontscripts"
ctanpkg = "fontscripts"
-- maindir **must** be shared with dependencies
-- but don't make fontscripts a dependency or dependant
maindir = "."
sourcedir = "."
sourcefiles = {"*.dtx","*.ins"}
manifestfile = "manifest.txt"
typesetruns = 5
--
-- there must be a variable I can set for this!
function docinit_hook()
  local errorlevel = cp("fontinst.lua",sourcefiledir,typesetdir)
  if not errorlevel == 0 then
    print("Could not copy fontinst.lua!\n")
    return 1
  end
  return 0
end
docfiles = {"fontinst.lua"}
dofile(sourcedir .. "/../../adnoddau/l3build/tag.lua")
date = "2024"
dofile(sourcedir .. "/../../adnoddau/l3build/manifest.lua")
function manifest_setup ()
  local groups = {
    {
      subheading = "Source files",
    },
    {
      name = "Package files",
      dir = sourcefiledir,
      files = {"*.dtx","*.ins","*.md"},
      exclude = {derivedfiles},
    },
    {
      subheading = "Derived files",
    },
    {
      name = "Package files",
      dir = unpackdir,
      files = {"*.cls","*.etx","*.lua","*.mtx","*.sty","*.tex","*.txt"},
      exclude = sourcefiles,
      description = "* manifest.txt",
    },
    {
      name = "Typeset documentation",
      files = {typesetfiles,typesetdemofiles},
      excludefiles = {".",".."},
      dir = sourcefiledir,
      rename = {"%.%w+$",".pdf"},
    },
  }
  return groups
end
unpackexe = "pdflatex"
--
uploadconfig = {
  -- *required* --
  -- announcement (don't include here?)
  announcement  = "Font encodings, metrics and Lua script fragments for generating font support packages for 8-bit engines with l3build. Optional template-based system enables the automatic generation of font tables and l3build tests. Easy addition of variable scaling to fd files (unsupported by some tools). Primarily designed for fontinst, but can be adapted for use with other programmes. Default configuration is intended to be cross-platform and require only tools included in TeX Live, but the documentation includes a simple adaption for integration with FontForge and GNU make.",
	author     = "Clea F. Rees",
  -- email (don't include here!)
	ctanPath   = "pkg/fontscripts",
	license    = {"lppl1.3c"},
	pkg        = ctanpkg,
	summary    = "Font encodings, metrics and Lua script fragments for generating font support packages for 8-bit engines with l3build.",
  uploader   = "Clea F. Rees",
	version    = "v0.1",
  -- optional --
	bugtracker = {"https://codeberg.org/cfr/nfssext/issues"},
  -- description
  -- development {}
  -- home {}
	-- note       = "The catalogue currently shows the package as included only in MikTeX, but it is also included in TeX Live. Any chance this could be corrected?",
	repository = {"https://codeberg.org/cfr/nfssext", "https://github.com/cfr42/nfssext"},
  -- support {}
	topic      = {"font-cvt", "package-devel"},
	update     = false,
  -- files --
  -- announcement_file
  -- note_file
  -- curlopt_file
}
--
-- vim: ts=2:sw=2:tw=80:nospell
