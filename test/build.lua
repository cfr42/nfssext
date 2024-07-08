-- $Id: build.lua 10142 2024-07-08 05:33:30Z cfrees $
-- Build configuration for testadf
ctanpkg = "testadf"
module = "test"
vendor = "arkandis"
maindir = ".."
dofile("../fontinst.lua")


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
