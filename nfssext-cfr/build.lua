-- $Id: build.lua 11042 2025-06-22 22:34:34Z cfrees $
-- Build configuration for nfssext-cfr
-------------------------------------------------------------------------------
-- l3build.pdf listing 1 tudalen 9
-------------------------------------------------------------------------------
module = "nfssext-cfr"
ctanpkg = module
-- maindir **must** be shared with dependencies
maindir = ".."
sourcefiledir = "."
sourcefiles = {"*.dtx","*.ins"}
checkengines = {"pdftex"}
checkformat = "latex"
checksuppfiles = {"*.fd"}
manifestfile = "manifest.txt"
typesetdeps = {maindir .. "/cfr-lm"}
typesetopts = "-interaction=nonstopmode -cnf-line='TEXMFHOME=.' -cnf-line='TEXMFLOCAL=.' -cnf-line='TEXMFARCH=.'"
typesetsourcefiles = {"cfr-lm.sty", maindir .. "/cfr-lm/keep/*"}
typesetruns = 5
-------------------------------------------------------------------------------
dofile(maindir .. "/tag.lua")
date = "2008-2025"
if direxists(sourcefiledir .. "/../../adnoddau/l3build") then
  dofile(sourcefiledir .. "/../../adnoddau/l3build/manifest.lua")
end
-------------------------------------------------------------------------------
uploadconfig = {
  -- *required* --
  -- announcement (don't include here?)
  announcement  = "Allow \textin{} again for hyperref 2025-05-20 or later.",
	author     = "Clea F. Rees",
  -- email (don't include here!)
	ctanPath   = "/macros/contrib/latex/nfssext-cfr",
	license    = {"lppl1.3c"},
	pkg        = ctanpkg,
	summary    = "Extended font selection commands for LaTeX's (New) New Font Selection Scheme",
  uploader   = "Clea F. Rees",
	version    = "v1.3",
  -- optional --
	bugtracker = {"https://codeberg.org/cfr/nfssext/issues"},
  description= "An extension and modification of Philipp Lehman's nfssext which provides extended font selection commands modelled on those provided by LaTeX 2e.",
  -- development {}
  -- home {}
	-- note       = "My apologies. I ought to have caught this.",
	repository = {"https://codeberg.org/cfr/nfssext", "https://github.com/cfr42/nfssext"},
  -- support {}
	topic      = {"font-sel", "font-use", "font-supp"},
	update     = true,
  -- files --
  -- announcement_file
  -- note_file
  -- curlopt_file
}
-------------------------------------------------------------------------------
function docinit_hook ()
  if not kpse.find_file("clm.map","map") then
    if direxists(maindir .. "/cfr-lm/keep") then
      local errorlevel = cp("*.*",maindir .. "/cfr-lm/keep",typesetdir) 
      if errorlevel ~= 0 then 
        print("Warning: could not copy cfr-lm keepfiles to typesetdir.") 
      end
    else
      print("Warning: could not find directory cfr-lm in " .. maindir .. ".")
    end
  else
    print("Warning: using installed copy of cfr-lm.")
  end
  return 0
end
-- vim: ts=2:sw=2:tw=80:nospell
