-- $Id: fontinst.lua 10177 2024-07-26 04:44:10Z cfrees $
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
nifergwall = 0
ntarg = "fnttarg"
function gwall (msg,file,rtn)
  file = file or "current file"
  msg = msg or "Error: "
  rtn = rtn or 0
  if rtn ~= 0 then 
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
  for i,j in ipairs(targs) do
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
  for i,j in ipairs(familymakers) do
    local errorlevel = finst(j,dir,mode)
    gwall("Compilation of driver ", j, errorlevel)
  end
  if nifergwall ~= 0 then return nifergwall end
  for i,j in ipairs(mapmakers) do
    local errorlevel = finst (j,dir,mode)
    gwall("Compilation of map ", j, errorlevel)
  end
  if nifergwall ~= 0 then return nifergwall end
  for i,j in ipairs(binmakers) do
    local targs = filelist(dir,j)
    -- https://www.lua.org/pil/21.1.html
    for k,m in ipairs(targs) do
      targ = dir .. "/" .. m
      -- is this really the right way to do this?
      -- surely it is not at all safe?
      -- though presumably no worse than executing the script directly
      for line in io.lines(targ) do
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
  for i,j in ipairs(targs) do
    local cmd = "vptovf " .. j
    local errorlevel = runcmd(cmd,dir)
    gwall("Creation of virtual font from ", j, errorlevel)
  end
  -- edit the .fd files if a scale factor is declared because fontinst 
  -- doesn't allow us to do this and the last message to the mailing list
  -- is from 2022 with no response from the maintainer
  local fdfiles = filelist(unpackdir, "*.fd")
  for i,j in ipairs(fdfiles) do
    local f = assert(io.open(unpackdir .. "/" .. j,"rb"))
    local content = f:read("*all")
    f:close()
    local csscaleaux = string.match(content, "%<%-%> *\\([%a%d][%a%d]*@@scale)") 
    local csscale = string.gsub(csscaleaux, "@(@)", "%1")
    if csscale ~= nil then
      local new_content = string.gsub(content, "(\\DeclareFontFamily{)", "%% addaswyd o t1phv.fd (dyddiad y ffeil fd: 2020-03-25)\n\\expandafter\\ifx\\csname " .. csscale .. "\\endcsname\\relax\n  \\let\\" .. csscaleaux .. "\\@empty\n\\else\n  \\edef\\" .. csscaleaux .. "{s*[\\csname " .. csscale .. "\\endcsname]}%%\n\\fi\n\n%1")
      local f = assert(io.open(unpackdir .. "/" .. j,"w"))
      -- this somehow removes the second value returned by string.gsub??
      f:write((string.gsub(new_content,"\n",os_newline_cp)))
      f:close()
    end
  end
  local rtn = direxists(keepdir)
  if rtn ~= 0 then
    local errorlevel = mkdir(keepdir)
    if errorlevel ~= 0 then
      print("DO NOT BUILD STANDARD TARGETS WITHOUT RESOLVING!!\n")
      gwall("Attempt to create directory ", keepdir, errorlevel)
    else
      for i,j in ipairs(keepfiles) do
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
            for i,j in ipairs(keeptempfiles) do 
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
  local dyddiad = os.date("%Y-%m-%d")
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
	elseif string.match (file,"%.md$") or string.match (file, "README*") then
    if string.match (content,"\nVersion %d[%d%.]* *\n") then
      return string.gsub (content,
      "(\nClea F%. Rees *\nVersion )%d[%.%d]* *\n%d%d%d*[%/%-]%d%d%d*[%/%-]%d%d%d* *(\n)",
      "%1" .. tagname .. "\n" .. dyddiad .. "%2")
    else return string.gsub (content,
      "(\nClea F%. Rees *\n)%d%d%d*[%/%-]%d%d%d*[%/%-]%d%d%d* *(\n)",
      "%1Version " .. tagname .. "\n" .. dyddiad .. "%2")
    end
  end
	return content
end
-- checkinit_hook
function checkinit_hook ()
  if #autotestfds == 0 then
    local autotestfdstmp = filelist(keepdir, "*.fd")
    for i, j in ipairs(autotestfdstmp) do
      if not string.match(j,"^ts1") then
        table.insert (autotestfds, j)
      end
    end
  end
  local filename = "fnt-test.lvt"
  local targname = ctanpkg .. "-test.lvt"
  local file = unpackdir .. "/" .. filename
  local targfile = unpackdir .. "/" .. targname
  local coll = ""
  local fnttestdir = maindir .. "/fnt-tests"
  local maps = ""
  local mapfiles=filelist(keepdir, "*.map")
  for i, j in ipairs(mapfiles) do
    maps = maps .. "\n\\pdfmapfile{" .. j .. "}"
  end
  maps = maps .. "\n\\pdfmapfile{+pdftex.map}"
  if not fileexists(fnttestdir .. "/" .. filename) then
    print("Skipping test creation.\n")
  else
    local errorlevel = cp(filename,fnttestdir,unpackdir)
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
      -- ought to normalise line endings here
      -- copied from l3build
      -- but I don't understand why the first subs is needed
      -- is it a problem if the file doesn't end with a newline?
      content = string.gsub(content .. (string.match(content,"\n$") and "" or "\n"), "\r\n", "\n")
      -- l3build-tagging.lua
      for i, j in ipairs(autotestfds) do
        local errorlevel = cp(j, keepdir, unpackdir)
        if errorlevel ~= 0 then
          gwall("Copy ", j, errorlevel)
          return errorlevel
        else
          j = unpackdir .. "/" .. j
          for line in io.lines(j) do
            -- it would be much better to filter the file list ...
            if string.match(line,"^\\DeclareFontShape%{[^%}]*%}%{[^%}]*%}%{[^%}]*%}%{[^%}]*%}%{$") then
              coll = (coll .. string.gsub(string.gsub(line,"%{$","%%%%"),"^\\DeclareFontShape%{([^%}]*)%}%{([^%}]*)%}%{([^%}]*)%}%{([^%}]*)%}","\n\\TEST{test-%1-%2-%3-%4}{%%%%\n  \\sampler{%1}{%2}{%3}{%4}%%%%\n}"))
            end
          end
        end
      end
      coll = maps .. "\n\\usepackage{" .. module .. "}\n\\begin{document}\n\\START\n" .. coll .. "\n\\END\n\\end{document}\n"
      local new_content = string.gsub(content, "\nSAMP *\n", coll)
      local f = assert(io.open(targfile,"w"))
      -- this somehow removes the second value returned by string.gsub??
      f:write((string.gsub(new_content,"\n",os_newline_cp)))
      f:close()
      rm(unpackdir,filename)
      -- PAID Â CHEISIO YR ISOD!!
      -- cp(targname,unpackdir,testfiledir)
      cp(targname,unpackdir,testdir)
    end
  end
  return 0
end
-- doc_init
function docinit_hook ()
  local fdfiles = filelist(keepdir, "*.fd")
  local filename = "fnt-tables.tex"
  local targname = ctanpkg .. "-tables.tex"
  local file = unpackdir .. "/" .. filename
  local targfile = unpackdir .. "/" .. targname
  local coll = ""
  local fnttestdir = maindir .. "/fnt-tests"
  local maps = ""
  local mapfiles=filelist(unpackdir, "*.map")
  for i, j in ipairs(mapfiles) do
    maps = maps .. "\n\\pdfmapfile{" .. j .. "}"
  end
  maps = maps .. "\n\\pdfmapfile{+pdftex.map}"
  if not fileexists(fnttestdir .. "/" .. filename) then
    print("Skipping font tables.\n")
  else
    local errorlevel = cp(filename,fnttestdir,unpackdir)
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
      -- ought to normalise line endings here 
      -- copied from l3build
      -- but I don't understand why the first subs is needed
      -- is it a problem if the file doesn't end with a newline?
      content = string.gsub(content .. (string.match(content,"\n$") and "" or "\n"), "\r\n", "\n") 
      -- l3build-tagging.lua
      for i, j in ipairs(fdfiles) do
        j = unpackdir .. "/" .. j
        for line in io.lines(j) do
          if string.match(line,"^\\DeclareFontShape%{[^%}]*%}%{[^%}]*%}%{[^%}]*%}%{[^%}]*%}%{$") then
            coll = (coll .. string.gsub(string.gsub(line,"%{$","%%%%"),"^\\DeclareFontShape","\n\\sampletable"))
          end
        end
      end
      coll = maps .. "\n\\begin{document}\n" .. coll .. "\n\\end{document}\n"
      local new_content = string.gsub(content, "\n\\endinput *\n", coll)
      local f = assert(io.open(targfile,"w"))
      -- this somehow removes the second value returned by string.gsub??
      f:write((string.gsub(new_content,"\n",os_newline_cp)))
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
autotestfds = autotestfds or {}
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
ctanreadme = "README"
demofiles = {"*-example.tex"}
familymakers = {"*-drv.tex"}
flatten = true
flattentds = false
installfiles = {"*.afm", "*.cls", "*.enc", "*.fd", "*.map", "*.otf", "*.pfb", "*.sty", "*.tfm", "*.ttf", "*.vf"}
-- match default as not yet existent
sourcefiledir = sourcefiledir or "."
keepdir = keepdir or sourcefiledir .. "/keep"
keeptempdir = keeptempdir or sourcefiledir .. "/keeptemp"
keepfiles = keepfiles or {"*.enc", "*.fd", "*.map", "*.tfm", "*.vf"}
keeptempfiles = keeptempfiles or {"*.mtx", "*.pl", "*-pltotf.sh", "*-rec.tex", "*.vpl", "*.zz"}
manifestfile = "manifest.txt"
mapmakers = {"*-map.tex"}
packtdszip = true
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
typesetfiles = typesetfiles or  {"*.dtx", "*-tables.tex", "*-example.tex"}
typesetsourcefiles = {keepdir .. "/*", "nfssext-cfr*.sty"}
unpackexe = "pdflatex"
unpackfiles = {"*.ins"}
-- vim: ts=2:sw=2:et:
