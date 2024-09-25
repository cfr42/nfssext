-- $Id: fontinst.lua 10381 2024-09-25 04:04:03Z cfrees $
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
utarg = "uniquifyencs"
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
function fntkeeper ()
  local dir = dir or unpackdir
  local keepdir = abspath(keepdir)
  local rtn = direxists(keepdir)
  if not rtn then
    local errorlevel = mkdir(keepdir)
    if errorlevel ~= 0 then
      print("DO NOT BUILD STANDARD TARGETS WITHOUT RESOLVING!!\n")
      gwall("Attempt to create directory ", keepdir, errorlevel)
    end
  else
    local errorlevel = cleandir(keepdir)
    if errorlevel ~= 0 then
      print("KEEP CONTAMINATED!\n")
      gwall("Attempt to clean directory ",keepdir,errorlevel)
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
    if not rtn then
      local errorlevel = mkdir(keeptempdir)
      if errorlevel ~= 0 then
        gwall("Attempt to create directory ", keeptempdir, errorlevel)
      end
    else
      local errorlevel = cleandir(keeptempdir)
      if errorlevel ~= 0 then
        print("keeptemp contaminated!\n")
        gwall("Attempt to clean directory ",keeptempdir,errorlevel)
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
-- oherwydd fy mod i bron ag anfon pob un ac mae'n amlwg fy mod i wedi anfon bacedi heb ei wneud hwn yn y gorffennol, well i mi wneud rhywbeth (scriptiau gwneud-cyhoeddus a make-public yn argraffu rhybudd os encs yn y cymysg
-- (cymraeg yn ofnadwy hefyd)
function uniquify (tag)
  local dir = ""
  tag = tag or encodingtag or ""
  local pkgbase = pkgbase or ""
  if standalone then
    dir = keepdir
    if pkgbase == "" then
      print("pkgbase unspecified. Trying to guess ... ")
      if ctanpkg ~= module and module ~= "" and module ~= nil then
        print("Guessing " .. module)
        pkgbase = module
      else
        pkgbase = string.gsub(ctanpkg, "adf$", "")
        if pkgbase ~= "" then
          print("Guessing " .. pkgbase)
        end
      end
    end
  else
    dir = unpackdir
    if pkgbase == "" then 
      local pkglist = filelist(dir,"*.sty")
      if #pkglist ~= 0 then
        pkgbase = pkglist[1]
      end
    end
  end
  local encs = encs or filelist(dir,"*.enc")
  local maps = maps or filelist(dir,"*.map")
  if #encs == 0 then
    return 0
  else
    if tag == "" then 
      if #maps ~= 0  then
        if #maps == 1 then
          tag = string.gsub(maps[1],"%.map$","")
        else
          local t = "" 
          local tt = ""
          for i,j in ipairs(maps) do
            if tt == t then 
              tt = string.gsub(j,"%w%.map$","")
            else
              if t == "" then
                t = string.gsub(j,"%w%.map$","")
              end
            end
          end
          if t == tt then
            tag = tt
          else
            gwall("Attempt to find tag ","",1)
          end
        end
      end
    end
    if tag ~= "" then  
      for i, j in ipairs(encs) do
        if string.match(j,"-" .. tag .. "%.enc$") or  string.match(j, module) or string.match(j,ctanpkg) or string.match(j,pkgbase) then
          print(j .. " ... OK\n")
        else
          local targenc = (string.gsub(j,"%.enc$","-" .. tag .. ".enc"))
          print("Target encoding is " .. targenc .. "\n")
          if fileexists(dir .. "/" .. targenc) then
            gwall("Target encoding exists !! ", targenc, 1)
            return 1
          else
            local f = assert(io.open(dir .. "/" .. j,"rb"))
            local content = f:read("*all")
            f:close()
            local new_content = (string.gsub(content,"(\n%%%%BeginResource: encoding fontinst%-autoenc[^\n ]*)( *\n/fontinst%-autoenc[^ %[]*)( %[)","%1-" .. tag .. "%2-" .. tag .. "%3"))
            if new_content ~= content then
              print("Writing unique encoding to " .. targenc)
              f = assert(io.open(dir .. "/" .. targenc,"w"))
              -- this somehow removes the second value returned by string.gsub??
              f:write((string.gsub(new_content,"\n",os_newline_cp)))
              f:close()
              if fileexists(dir .. "/" .. targenc) then
                local errorlevel = rm(dir,j)
                if errorlevel ~= 0 then
                  gwall("Attempt to rm old encoding ",j,errorlevel)
                end
                if #maps ~= 0 then
                  local jpatt = string.gsub(j,"%-","%%-")
                  jpatt = string.gsub(jpatt,"%.","%%.")
                  for k,m in ipairs(maps) do
                    f = assert(io.open(dir .. "/" .. m,"rb"))
                    local mcontent = f:read("*all")
                    f:close()
                    local new_mcontent = (string.gsub(mcontent,"(%<%[?)" .. jpatt .. "( %<%w+%.pfb \" fontinst%-autoenc[%w%-_]*)( ReEncodeFont)", "%1" .. targenc .. "%2-" .. tag .. "%3"))
                    if new_mcontent ~= mcontent then 
                      print("Writing adjusted map lines to " .. m)
                      f = assert(io.open(dir .. "/" .. m,"w"))
                      -- this somehow removes the second value returned by string.gsub??
                      f:write((string.gsub(new_mcontent,"\n",os_newline_cp)))
                      f:close()
                    else
                      gwall("Amending map ",m,1)
                    end
                  end
                else
                  print("FOUND NO MAPS??\n")
                end
              else
                gwall("Attempt to write ",targenc,1)
              end
            else
              gwall("Attempt to uniquify " .. j .. " as ",targenc,1)
            end
          end
        end
      end
    end
    return nifergwall
  end
  print("Something weird happened.\n")
  return 1
end
function fontinst (dir,mode)
  dir = dir or unpackdir
  mode = mode or "errorstopmode --halt-on-error"
  standalone = false
  encodingtag = encodingtag or ""
  -- if not direxists(dir) then
  -- print("Missing directory. Unpacking first.\n")
  print("Unpacking ...\n")
  local errorlevel = unpack() 
  -- end
  local tfmfiles = filelist(dir,"*.tfm")
  for i,j in ipairs(tfmfiles) do
    local plname = string.gsub(j, "%.tfm$", ".pl")
    if fileexists(unpackdir .. "/" .. plname) then
      print(plname .. " already exists!")
      return 1
    else
      local cmd = "tftopl " .. j .. " " .. plname
      local errorlevel = runcmd(cmd,dir)
      gwall("Conversion to pl from tfm ",j,errorlevel)
      -- remove tfm to reduce pollution of package later
      rm(unpackdir,j)
      gwall("Deletion of tfm ", j, errorlevel)
    end
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
    local new_content = content
    local csscaleaux = string.match(content, "%<%-%> *\\([%a%d][%a%d]*@@scale)") 
    if csscaleaux ~= nil then
      local csscale = string.gsub(csscaleaux, "@(@)", "%1")
      if csscale ~= nil then
        new_content = string.gsub(content, "(\\DeclareFontFamily{)", "%% addaswyd o t1phv.fd (dyddiad y ffeil fd: 2020-03-25)\n\\expandafter\\ifx\\csname " .. csscale .. "\\endcsname\\relax\n  \\let\\" .. csscaleaux .. "\\@empty\n\\else\n  \\edef\\" .. csscaleaux .. "{s*[\\csname " .. csscale .. "\\endcsname]}%%\n\\fi\n\n%1")
      end
    end
    csscaleaux = string.match(content, "\\DeclareFontFamily{[^}]*}{[^}]*}{[^}]*\\hyphenchar *\\font *=[^}\n]*}") 
    if csscaleaux ~= nil then
      content = new_content
      new_content = string.gsub(content, "(\\DeclareFontFamily{[^}]*}{[^}]*}{\\hyphenchar) *(\\font) *(=[^ }\n]*) *([^ }\n]* *})", "%1%2%3%4")
    end
    if new_content ~= content then
      local f = assert(io.open(unpackdir .. "/" .. j,"w"))
      -- this somehow removes the second value returned by string.gsub??
      f:write((string.gsub(new_content,"\n",os_newline_cp)))
      f:close()
    end
  end
  local errorlevel = uniquify(encodingtag)
  if errorlevel ~= 0 then
    gwall("Encodings not uniquified! Do not submit to CTAN! uniquify(" .. encodingtag .. ")","",errorlevel)
  end
  errorlevel = fntkeeper()
  if errorlevel ~= 0 then
    gwall("FONT KEEPER FAILED! DO NOT MAKE STANDARD TARGETS WITHOUT RESOLVING!! fntkeeper() ", unpackdir, errorlevel)
  end
  return nifergwall
end
dofile(maindir .. "/tag.lua")
-- fnt_test
function fnt_test (fntpkgname,fds,content,maps,fdsdir)
  local coll = ""
  -- suffix ly -> ly1 ; no suffix -> t1
  local collly = ""
  local targname = fntpkgname .. "-auto-test.lvt"
  local targnamely = fntpkgname .. "-auto-test-ly1.lvt"
  local targfile = unpackdir .. "/" .. targname
  local targfilely = unpackdir .. "/" .. targnamely
  -- ly1 boolean
  local yy = 0
  -- texnansi/ly1 fds
  local lys = {}
  -- ec/t1 fds
  local ecs = {}
  -- local mapsly = "" 
  print("Creating test file for " .. fntpkgname .. " with fds: ")
  for i, j in ipairs(fds) do print("fd: " .. j) end
  -- l3build-tagging.lua
  for i, j in ipairs(fds) do
    -- local errorlevel = cp(j, keepdir, unpackdir)
    if string.match(j,"^ly1") then
      yy = 1
      table.insert(lys,j)
    else
      table.insert(ecs,j)
    end
    if fdsdir ~= unpackdir then
      local errorlevel = cp(j, fdsdir, unpackdir)
      if errorlevel ~= 0 then
        gwall("Copy ", j, errorlevel)
        return errorlevel
      end
    end
  end
  -- restart so we get the filtered list (hopefully)
  for i, j in ipairs(ecs) do
    j = unpackdir .. "/" .. j
    for line in io.lines(j) do
      -- it would be much better to filter the file list ...
      if string.match(line,"^\\DeclareFontShape%{[^%}]*%}%{[^%}]*%}%{[^%}]*%}%{[^%}]*%}%{$") then
        coll = (coll .. string.gsub(string.gsub(line,"%{$","%%%%"),"^\\DeclareFontShape%{([^%}]*)%}%{([^%}]*)%}%{([^%}]*)%}%{([^%}]*)%}","\n\\TEST{test-%1-%2-%3-%4}{%%%%\n  \\sampler{%1}{%2}{%3}{%4}%%%%\n}"))
      end
    end
  end
  if yy == 1 then
    for i, j in ipairs(lys) do
      j = unpackdir .. "/" .. j
      for line in io.lines(j) do
        -- it would be much better to filter the file list ...
        if string.match(line,"^\\DeclareFontShape%{[^%}]*%}%{[^%}]*%}%{[^%}]*%}%{[^%}]*%}%{$") then
          collly = (collly .. string.gsub(string.gsub(line,"%{$","%%%%"),"^\\DeclareFontShape%{([^%}]*)%}%{([^%}]*)%}%{([^%}]*)%}%{([^%}]*)%}","\n\\TEST{test-%1-%2-%3-%4}{%%%%\n  \\sampler{%1}{%2}{%3}{%4}%%%%\n}"))
        end
      end
    end
    coll = maps .. "\n\\usepackage[enc=t1]{" .. fntpkgname .. "}\n\\begin{document}\n\\START\n" .. coll .. "\n\\END\n\\end{document}\n"
    collly = maps .. "\n\\usepackage[enc=ly1]{" .. fntpkgname .. "}\n\\begin{document}\n\\START\n" .. collly .. "\n\\END\n\\end{document}\n"
  else
    -- assume package doesn't have an encoding option and is t1/ts1 only
    coll = maps .. "\n\\usepackage{" .. fntpkgname .. "}\n\\begin{document}\n\\START\n" .. coll .. "\n\\END\n\\end{document}\n"
  end
  -- coll = maps .. "\n\\begin{document}\n\\START\n" .. coll .. "\n\\END\n\\end{document}\n"
  local new_content =  "%% Do not edit this file. It is generated by l3build and changes will be overwritten.\n" .. string.gsub(content, "\nSAMP *\n", coll)
  local f = assert(io.open(targfile,"w"))
  -- this somehow removes the second value returned by string.gsub??
  f:write((string.gsub(new_content,"\n",os_newline_cp)))
  f:close()
  if yy == 1 then 
    new_content =  "%% Do not edit this file. It is generated by l3build and changes will be overwritten.\n" .. string.gsub(content, "\nSAMP *\n", collly)
    local f = assert(io.open(targfilely,"w"))
    -- this somehow removes the second value returned by string.gsub??
    f:write((string.gsub(new_content,"\n",os_newline_cp)))
    f:close()
  end
  -- PAID Â CHEISIO YR ISOD!!
  -- cp(targname,unpackdir,testfiledir)
  local errorlevel = cp(targname,unpackdir,testdir)
  if errorlevel ~= 0 then
    gwall("Attempt to copy ", targname, errorlevel)
  end
  errorlevel = cp(targnamely,unpackdir,testdir)
  if errorlevel ~= 0 then
    gwall("Attempt to copy ", targnamely, errorlevel)
  end
  return nifergwall
end
-- checkinit_hook
function checkinit_hook ()
  local filename = "fnt-test.lvt"
  local file = unpackdir .. "/" .. filename
  local fnttestdir = maindir .. "/fnt-tests"
  local maps = ""
  local mapfiles=filelist(keepdir, "*.map")
  local mapsdir = ""
  local fdsdir = ""
  if #mapfiles == 0 then
    mapfiles=filelist(unpackdir, "*.map")
    if #mapfiles == 0 then
      gwall("Attempt to find map files ", ".map", 1)
      return 1
    else
      print("Using maps from " .. unpackdir .. "\n")
      mapsdir = unpackdir
    end
  else
    mapsdir = keepdir
    print("Using maps from " .. keepdir .. "\n")
  end
  local fntpkgnames = fntpkgnames or filelist(unpackdir,"*.sty")
  for i, j in ipairs(fntpkgnames) do
    fntpkgnames[i] = string.gsub(j,"%.sty","")
  end
  -------
  local autotestfdstmp = filelist(keepdir, "*.fd")
  -- if they're not kept, they may be source (e.g. berenisadf)
  if #autotestfdstmp == 0 then
    autotestfdstmp = filelist(unpackdir, "*.fd")
    if #autotestfdstemp == 0 then
      gwall("Attempt to find fd files ", ".fd", 1)
      return 1
    else
      fdsdir = unpackdir
      print("Using fds from " .. unpackdir .. "\n")
    end
  else
    fdsdir = keepdir
    print("Using fds from " .. keepdir .. "\n")
  end
  if #autotestfdstmp == 0 then
    print("Something is amiss - this code should never be executed!\n")
    gwall("Attempt to locate fd files ", ".fd", 1)
  else
    if #autotestfds == 0 then
      for i, j in ipairs(autotestfdstmp) do
        if not string.match(j,"^ts1") then
          table.insert (autotestfds, j)
        end
      end
    end
  end
  -------
  -- if fntestfds.<package name> has been specified, use that (should be a table)
  -- o/w assign the autotestfds table to fntestfds.<package name>
  for i, j in ipairs(fntpkgnames) do
    -- I really don't understand tables (and I know this is very, very basic)
    if fnttestfds[j] == nil then
      if #fnttestfds == 0 then
        -- fnttestfds.j = {}
        -- use only if fnttestfds isn't specified either as table of tables or table of files/globs
        -- this doesn't seem very robust
        fnttestfds.j = autotestfds
        -- for k, l in ipairs(autotestfds) do
        -- table.insert (fnttestfds.j, l)
      end
    else
      fnttestfds.j = fnttestfds
    end
  end
  -------
  for i, j in ipairs(mapfiles) do
    maps = maps .. "\n\\pdfmapfile{-" .. j .. "}\n\\pdfmapfile{+" .. j .. "}"
  end
  -- maps = maps .. "\n\\pdfmapfile{+pdftex.map}"
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
      content = string.gsub(content, "\\RequirePackage%{svn%-prov%}\n\\ProvidesFileSVN%{[^%}]*%}%[[^%]]*%]%[[^%]]*%]\n", "")
      for i, j in ipairs(fntpkgnames) do
        -- create the test file for each package
        -- errorlevel = fnt_test(j,fnttestfds[j],content,maps)
        errorlevel = fnt_test(j,fnttestfds.j,content,maps,fdsdir)
        if errorlevel ~= 0 then
          gwall("Font test creation ", j, errorlevel)
          return errorlevel
        end
      end
      rm(unpackdir,filename)
    end
  end
  return 0
end
-- doc_init
function docinit_hook ()
  -- local fdfiles = filelist(keepdir, "*.fd")
  local fdfiles = filelist(unpackdir, "*.fd")
  local filename = "fnt-tables.tex"
  local targname = ctanpkg .. "-tables.tex"
  local file = unpackdir .. "/" .. filename
  local targfile = unpackdir .. "/" .. targname
  local coll = ""
  local fnttestdir = maindir .. "/fnt-tests"
  local maps = ""
  local mapfiles=filelist(unpackdir, "*.map")
  local yy = 0
  for i, j in ipairs(mapfiles) do
    maps = maps .. "\n\\pdfmapfile{-" .. j .. "}\n\\pdfmapfile{+" .. j .. "}"
  end
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
      content = string.gsub(content, "\\RequirePackage%{svn%-prov%}\n\\ProvidesFileSVN%{[^%}]*%}%[[^%]]*%]%[[^%]]*%]\n", "")
      -- l3build-tagging.lua
      for i, j in ipairs(fdfiles) do
        if string.match(j,"^ly1") then
          yy = 1
        end
        j = unpackdir .. "/" .. j
        for line in io.lines(j) do
          if string.match(line,"^\\DeclareFontShape%{[^%}]*%}%{[^%}]*%}%{[^%}]*%}%{[^%}]*%}%{$") then
            coll = (coll .. string.gsub(string.gsub(line,"%{$","%%%%"),"^\\DeclareFontShape","\n\\sampletable"))
          end
        end
      end
      if yy == 1 then
        maps = "\n\\input{ly1enc.def}\n" .. maps
      end
      coll = maps .. "\n\\begin{document}\n" .. coll .. "\n\\end{document}\n"
      local new_content =  "%% Do not edit this file. It is generated by l3build and changes will be overwritten.\n" .. string.gsub(content, "\n\\endinput *\n", coll)
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
target_list[utarg] = {
  func = uniquify,
  desc = "Uniquifies encodings ONLY",
  pre = function(names)
    standalone = true
    if names and #names > 1 then
      print("Too many encoding tags specified; no more than one allowed")
      help()
      exit(1)
    else
      names = names or encodingtag or ""
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
ctanreadme = "README.md"
demofiles = {"*-example.tex"}
familymakers = {"*-drv.tex"}
flatten = true
flattentds = false
fnttestfds = fnttestfds or {}
-- fntautotestfds = fntautotestfds or {}
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
sourcefiles = {"*.afm", "afm/*.afm", "*.pfb", "*.dtx", "*.ins", "opentype/*.otf", "*.otf", "tfm/*.tfm", "truetype/*.ttf", "*.ttf", "type1/*.pfb"}
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
	"fonts/type1/" .. vendor .. "/" .. module .. "/" .. "*.pfm",
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
