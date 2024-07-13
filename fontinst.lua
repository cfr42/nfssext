-- $Id: fontinst.lua 10146 2024-07-13 15:26:13Z cfrees $
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
-------------------------------------------------
nifergwall = 0
ntarg = "fnttarg"
function gwall (msg,file,rtn)
	file = file or "current file"
	msg = msg or "Error: "
	rtn = rtn or 0
	if rtn ~= 0 
		then 
			nifergwall = nifergwall + rtn
			print (msg .. file .. " failed (" .. rtn .. ")\n")
		end
end
function finst (patt,dir,mode)
  dir = dir or "."
  mode = mode or "nonstopmode"
	local cmd = "pdftex --interaction=" .. mode
	local targs = {}
	-- https://lunarmodules.github.io/luafilesystem/examples.html (expl)
	-- l3build-file-functions.lua (filelist fn)
	targs = filelist(dir,patt)
	for i,j in ipairs(targs)
		do
			local errorlevel = tex(j,dir,cmd)
			gwall("Compilation of ", j, errorlevel)
		end
end
function fontinst (dir,mode)
  dir = dir or unpackdir
	mode = mode or "errorstopmode --halt-on-error"
	if not direxists(dir) then
		print("Missing directory. Unpacking first.\n")
		local errorlevel = unpack() 
	end
  for i,j in ipairs(familymakers)
		do
			local errorlevel = finst(j,dir,mode)
			gwall("Compilation of driver ", j, errorlevel)
		end
	if nifergwall ~= 0 then return nifergwall end
	for i,j in ipairs(mapmakers)
		do
			local errorlevel = finst (j,dir,mode)
			gwall("Compilation of map ", j, errorlevel)
		end
		if nifergwall ~= 0 then return nifergwall end
	for i,j in ipairs(binmakers) 
	do
		local targs = filelist(dir,j)
		-- https://www.lua.org/pil/21.1.html
		for k,m in ipairs(targs)
			do
				targ = dir .. "/" .. m
				-- is this really the right way to do this?
				-- surely it is not at all safe?
				-- though presumably no worse than executing the script directly
				for line in io.lines(targ)
					do
						if string.match(line,"^pltotf [a-zA-Z0-9%-]+%.pl [a-zA-Z0-9%-]+%.tfm$") then
							local errorlevel = runcmd(line,dir)
							gwall("Creation of TFM using " .. line .. " from ", j, errorlevel)
						else
							print("Ignoring unexpected line \"" .. line .. "\" in " .. j .. ".\n")
							nifergwall = nifergwall + 1
						end
					end
				end
	end
	if nifergwall ~= 0 then return nifergwall end
	local targs = filelist(dir,"*.vpl")
	for i,j in ipairs(targs)
		do
	    local cmd = "vptovf " .. j
			local errorlevel = runcmd(cmd,dir)
			gwall("Creation of virtual font from ", j, errorlevel)
		end
	local rtn = direxists(keepdir)
	if rtn ~= 0
		then
			local errorlevel = mkdir(keepdir)
			if errorlevel ~= 0 then
				print("DO NOT BUILD STANDARD TARGETS WITHOUT RESOLVING!!\n")
				gwall("Attempt to create directory ", keepdir, errorlevel)
			else
				for i,j in ipairs(keepfiles)
					do
						local rtn = cp(j, unpackdir, keepdir)
						if rtn ~= 0 then
							gwall("Copy ", j, errorlevel)
							print("DO NOT BUILD STANDARD TARGETS WITHOUT RESOLVING!\n")
						end
					end
				if keeptempfiles ~= {} then
					local rtn = direxists(keeptempdir)
					if rtn ~= 0 then
						local errorlevel = mkdir(keeptempdir)
						if errorlevel ~= 0 then
							gwall("Attempt to create directory ", keeptempdir, errorlevel)
						else
							for i,j in ipairs(keeptempfiles)
								do 
									local errorlevel = cp(j,unpackdir,keeptempdir)
									if errorlevel ~= 0 then
										gwall("Copy ", j, errorlevel)
									end
								end
							end
						end
					end
				end
		end	
	return nifergwall
end
function update_tag (file,content,tagname,tagdate)
  -- stolen from l2e build-config.lua
	local year = os.date("%Y")
	if string.match(content,"%%+ +[ a-zA-Z0-9]* [Cc]opyright %([Cc]%) %d%d%d%d-%d%d%d%d Clea F%. Rees") then
    content = string.gsub(content,
      "[cC]opyright %([cC]%) (%d%d%d%d)%-%d%d%d%d Clea F%. Rees",
      "Copyright (C) %1-" .. year .. " Clea F. Rees")
  elseif string.match(content,"%%+ +[ a-zA-Z0-9]* [cC]opyright %([cC]%) %d%d%d%d Clea F%. Rees") then
    local oldyear = string.match(content,"%%+ +[a-zA-Z0-9 ]* [cC]opyright %([cC]%) (%d%d%d%d) Clea F%. Rees")
    if not year ~= oldyear then
      content = string.gsub(content,
        "[cC]opyright %([cC]%) %d%d%d%d Clea F%. Rees",
        "Copyright (C) " .. oldyear .. "-" .. year .. " Clea F. Rees")
    end
  end
	if string.match (file,"%.ins$") or string.match (file,"%.txt$") or string.match (file,"%.md$")  then
		if string.match(content,"^[Cc]opyright %([cC]%) %d%d%d%d-%d%d%d%d Clea F%. Rees\n") then
    content = string.gsub(content,
      "[cC]opyright %([cC]%) (%d%d%d%d)%-%d%d%d%d Clea F%. Rees\n",
      "Copyright (C) %1-" .. year .. " Clea F. Rees\n")
  elseif string.match(content,"[cC]opyright %([cC]%) %d%d%d%d Clea F%. Rees\n") then
    local oldyear = string.match(content,"[cC]opyright %([cC]%) (%d%d%d%d) Clea F%. Rees\n")
    if not year ~= oldyear then
      content = string.gsub(content,
        "[cC]opyright %([cC]%) %d%d%d%d Clea F%. Rees\n",
        "Copyright (C) " .. oldyear .. "-" .. year .. " Clea F. Rees\n")
			end
		end
	end
	local vtagname = string.gsub(tagname, "^v*(%d)", "v%1")
	tagname = string.gsub(tagname, "^v*(%d)", "%1")
	if string.match (file,"%.dtx$") or string.match (file,"%.ins") then
		return string.gsub (content,
		"(\\ProvidesFileSVN%{%$[^%}]*%$%} *%[)v%d[%d%.]*( *\\revinfo%])",
		"%1" .. vtagname .. "%2")
	elseif string.match (file,"%.md$") then
		return string.gsub (content,
		"(\nVersion )%d[%d%.]*( *\n)",
		"%1" .. tagname .. "%2")
	end
	return content
end
-- doc_init
function docinit_hook ()
  local fdfiles = filelist(keepdir, "*.fd")
  local filename = "fnt-tables.tex"
  local targname = ctanpkg .. "-tables.tex"
  local file = unpackdir .. "/" .. filename
  local targfile = unpackdir .. "/" .. targname
  local coll = ""
  local tbdir = maindir .. "/fnt-tests"
  local maps = ""
  local mapfiles=filelist(unpackdir, "*.map")
  for i, j in ipairs(mapfiles) do
    maps = maps .. "\n\\pdfmapfile{+" .. j .. "}"
  end
  if not fileexists(tbdir .. "/" .. filename) then
    print("Skipping font tables.\n")
  else
    local errorlevel = cp(filename,tbdir,unpackdir)
    -- local errorlevel = ren(unpackdir, filename, targname)
    if errorlevel ~= 0 then
      gwall("Copy ", filename, errorlevel)
      return errorlevel
    else
      -- need to get content here
      -- copy this from l3build-tagging.lua
      local f = assert(io.open(file,"rb"))
      local content = f:read("*all")
      f:close()
      -- ought to normalise line endings here but I don't understand the code in
      -- l3build-tagging.lua
      for i, j in ipairs(fdfiles) do
        j = unpackdir .. "/" .. j
        for line in io.lines(j) do
          if string.match(line,"^\\DeclareFontShape%{[^%}]*%}%{[^%}]*%}%{[^%}]*%}%{[^%}]*%}%{$") then
            coll = (coll .. string.gsub(string.gsub(line,"%{$","%%%%"),"^\\DeclareFontShape","\\sampletable"))
          end
        end
      end
      coll = maps .. "\n\\begin{document}\n" .. coll .. "\n\\end{document}\n"
      local new_content = string.gsub(content, "\n\\endinput *\n", coll)
      local f = assert(io.open(targfile,"w"))
      -- normalisation probably pointless since I didn't do it above, but maybe
      -- it'll be useful at some point
      -- but os_newline isn't public ...
      -- f:write(string.gsub(new_content,"\n",os_newline))
      f:write(new_content)
      f:close()
      rm(unpackdir,filename)
      cp(targname,unpackdir,sourcefiledir)
    end
  end
  return 0
end
-- fontinst must be specified first
-- it just ain't TeX
target_list[ntarg] = {
	func = fontinst,
	desc = "Creates TeX font file",
	pre = function(names)
		if names then
			print("fontinst does not need names\n")
			help()
			exit(1)
		end
		return 0
	end
}
-------------------------------------------------
-- auxfiles = {"*.aux"}
bakext = ".bkup"
binaryfiles = {"*.pdf", "*.zip", "*.vf", "*.tfm", "*.pfb", "*.ttf", "*.otf", "*.tar.gz"}
binmakers = {"*-pltotf.sh"}
-- maindir before checkdeps
-- maindir = "../.."
checkdeps = {maindir .. "/nfssext-cfr", maindir .. "/fnt-tests"}
checkengines = {"pdftex"}
checkformat = "latex"
-- checksuppfiles = {""}
cleanfiles = {keeptempfiles}
familymakers = {"*-drv.tex"}
installfiles = {"*.afm", "*.cls", "*.enc", "*.fd", "*.map", "*.otf", "*.pfb", "*.sty", "*.tfm", "*.ttf", "*.vf"}
-- match default as not yet existent
sourcefiledir = sourcefiledir or "."
keepdir = keepdir or sourcefiledir .. "/keep"
keeptempdir = keeptempdir or sourcefiledir .. "/keeptemp"
keepfiles = keepfiles or {"*.enc", "*.fd", "*.map", "*.tfm", "*.vf"}
keeptempfiles = keeptempfiles or {"*.mtx", "*.pl", "*-pltotf.sh", "*-rec.tex", "*.vpl", "*.zz"}
manifestfile = {"manifest.txt"}
mapmakers = {"*-map.tex"}
-- need module test or default?
sourcefiles = {"*.afm", "afm/*.afm", "*.pfb", "*.dtx", "*.ins", "opentype/*.otf", "*.otf", "truetype/*.ttf", "*.ttf", "type1/*.pfb"}
tagfiles = {"*.dtx", "*.ins", "manifest.txt", "MANIFEST.txt", "README", "README.md"}
-- vendor and module must be specified before tdslocations
vendor = vendor or "public"
tdslocations = {
	"fonts/afm/" .. vendor .. "/" .. module .. "/" .. "*.afm",
	"fonts/enc/dvips/" .. module .. "/" .. "*.enc",
	"fonts/map/dvips/" .. module .. "/" .. "*.map",
	"fonts/opentype/" .. vendor .. "/" .. module .. "/" .. "*.otf",
	"fonts/tfm/" .. vendor .. "/" .. module .. "/" .. "*.tfm",
	"fonts/truetype/" .. vendor .. "/" .. module .. "/" .. "*.ttf",
	"fonts/type1/" .. vendor .. "/" .. module .. "/" .. "*.pfb",
	"fonts/vf/" .. vendor .. "/" .. module .. "/" .. "*.vf",
	"source/fonts/" .. module .. "/" .. "*.etx",
	"source/fonts/" .. module .. "/" .. "*.mtx",
	"source/fonts/" .. module .. "/" .. "*-drv.tex",
	"source/fonts/" .. module .. "/" .. "*-map.tex",
	"tex/latex/" .. module .. "/" .. "*.fd",
	"tex/latex/" .. module .. "/" .. "*.sty"
}
-- after maindir
typesetdeps = {maindir .. "/nfssext-cfr"}
-- enable l3build doc/check to find font files
-- cannot concatenate variables here as they don't (yet?) exist
typesetexe = "TEXMFDOTDIR=.:../local: pdflatex"
typesetfiles = typesetfiles or  {"*.dtx", "*-tables.tex"}
typesetsourcefiles = {keepdir .. "/*", "nfssext-cfr*.sty"}
unpackexe = "pdflatex"
unpackfiles = {"*.ins"}
-- vim: ts=2:sw=2:tw=80:et:nospell
