-- $Id: fntbuild.lua 10613 2024-11-12 17:27:26Z cfrees $
-------------------------------------------------
-------------------------------------------------
-- copy non-public things from l3build
-- these are just copied because they aren't documented
-- so we duplicate them as we're not entitled to use them o/w
-- I've tried to eliminate local shorthands for clarity
-- should these all be local?
-- they should probably be renamed ...
-------------------------------------------------
-- os_newline_cp {{{
local os_newline_cp = "\n"
if os.type == "windows" then
  if tonumber(status.luatex_version) < 100 or
     (tonumber(status.luatex_version) == 100
       and tonumber(status.luatex_revision) < 4) then
    os_newline_cp = "\r\n"
  end
end
-- }}}
-------------------------------------------------
-- localtexmf {{{
-- from l3build-aux.lua
-- Construct a localtexmf including any tdsdirs
-- Needed for checking and typesetting, hence global
function localtexmf()
  local paths = ""
  for src,_ in pairs(tdsdirs) do
    paths = paths .. os_pathsep .. abspath(src) .. "//"
  end
  if texmfdir and texmfdir ~= "" and direxists(texmfdir) then
    paths = paths .. os_pathsep .. abspath(texmfdir) .. "//"
  end
  return paths
end
-- }}}
-------------------------------------------------
-- get_script_name {{{
local function get_script_name()
  if string.match(arg[0], "l3build$") or string.match(arg[0], "l3build%.lua$") then
    return kpse.lookup("l3build.lua")
  else
    return arg[0] -- Why no lookup here?
  end
end
-- }}}
-------------------------------------------------
-- dep_install {{{
function dep_install(deps)
  local error_level
  for _, dep in ipairs(deps) do
    print("Installing dependency: " .. dep)
    error_level = run(dep, "texlua " .. get_script_name() .. " unpack -q")
    if error_level ~= 0 then
      return error_level
    end
  end
  return 0
end
-- }}}
-------------------------------------------------
-------------------------------------------------
-- lsrdir_aux {{{
function lsrdir_aux (path,filenames)
  for file in lfs.dir(path) do
    if file ~= "." and file ~= ".." then
      local f = path .. "/" .. file
      local attr = lfs.attributes (f)
      -- why is this necessary?
      -- lfs.attributes does or doesn't return a table?
      assert (type(attr) == "table")
      if attr.mode == "directory" then
        lsrdir_aux (f,filenames)
      else
        table.insert(filenames,file)
      end
    end
  end
  return filenames
end
-- }}}
-- lsrdir {{{
-- https://lunarmodules.github.io/luafilesystem/examples.html
function lsrdir (path,filenames)
  local filenames = filenames or {}
  filenames = lsrdir_aux (path,filenames)
  return filenames
end
-- }}}
-------------------------------------------------
-------------------------------------------------
-- error-tracking
nifergwall = 0
-- target names
ntarg = "fnttarg"
utarg = "uniquifyencs"
-------------------------------------------------
-------------------------------------------------
sourcedir = sourcedir or "."
maindir = maindir or sourcedir
-------------------------------------------------
-------------------------------------------------
-- use fntbuild-config.lua if found {{{
local configs = {}
if buildsearch then
  local f = kpse.find_file("fntbuild-config.lua")
  if f ~= nil then
    dofile(f)
    print("WARNING: Using local configuration from " .. f .. ".\n Your package may not build elsewhere.\n")
    table.insert(configs,f)
  end
end
if fileexists(maindir .. "/fntbuild-config.lua") then
  dofile(maindir .. "/fntbuild-config.lua")
  print("Using local configuration from " .. maindir .. "/fntbuild-config.lua.\n Ensure this is included when publishing sources.\n")
  table.insert(configs,maindir .. "/fntbuild-config.lua")
end
if fileexists(sourcedir .. "/fntbuild-config.lua") then
  dofile(sourcedir .. "/fntbuild-config.lua")
  print("Using local configuration from " .. sourcedir .. "/fntbuild-config.lua.\n Ensure this is included when publishing sources.\n")
  table.insert(configs,sourcedir .. "/fntbuild-config.lua")
end
if #configs == 0 then
  print("No fntbuild-config.lua found.\n Using defaults.")
end
-- }}}
-------------------------------------------------
-------------------------------------------------
-- it is way too easy to pick up the same package's files in the dist tree
-- when that happens, some installation tools fail to generate duplicate files
-- once the update goes to ctan, the files disappear ...
buildsearch = false
-- also very easy for font files not to get installed properly and the old ones used
-- note this overrides the l3build default
checksearch = false
-------------------------------------------------
-- builddir
-- should be global? or local is better?
local builddir = builddir or maindir .. "/build"
-------------------------------------------------
builddeps = builddeps or {}
fntdir = fntdir or builddir .. "/fnt"
-- should use existing fnt variables, I think
-- buildfiles = buildfiles or { "*.afm", "*.etx", "*.mtx", "*.otf",  "*.tex" , "*.tfm" }
buildfiles = buildfiles or { "*.afm", "*.enc", "*.etx", "*.fd", "*.lig", "*.make", "*.map", "*.mtx", "*.nam", "*.otf", "*.pe", "*.tex" , "*.tfm" }
-- buildsuppfiles = buildsuppfiles or {}
buildsuppfiles_sys = buildsuppfiles_sys or {}
mapfiles_sys = mapfiles_sys or {}
mapfiles_add = mapfiles_add or {}
-------------------------------------------------
-- gwall {{{
function gwall (msg,file,rtn)
  file = file or "current file"
  msg = msg or "Error: "
  rtn = rtn or 0
  if rtn ~= 0 then 
    nifergwall = nifergwall + rtn
    print (msg .. file .. " failed (" .. rtn .. ")\n")
  end
end
-- }}}
-------------------------------------------------
-------------------------------------------------
-- map_cat (frags,dir,mapfile) {{{
function map_cat (frags,dir,mapfile)
  mapfile = mapfile or "pdftex.map"
  local n = 0
  if #frags == 0 then 
    frags = { "cm.map", "cm-super-t1.map", "cm-super-ts1.map", "lm.map" }
  end
  if #mapfiles_add ~= 0 then
    for _,i in ipairs(mapfiles_add) do
      table.insert(frags,i)
    end
  end
  if fileexists(dir .. "/" .. mapfile) then 
    local errorlevel = rm(dir,mapfile) 
    gwall("Removal of ",dir .. "/" .. mapfile,errorlevel)
  end
  if #frags ~= 0 then
    local m = assert(io.open(dir .. "/" .. mapfile,"a"))
    for _,i in ipairs(frags) do
      -- kpse.find_file assumes filetype tex i.e. ignores file ext.
      local ff = kpse.find_file(i,"map")
      if ff ~= "" then
        local f = assert(io.open(ff),"rb")
        local l = f:read("*all")
        f:close()
        m:write(l)
      else
        gwall("Search for map fragment ",i,1)
        n = n + 1
      end
    end
    m:close()
  end
  return n
end
-- }}}
-------------------------------------------------
-- buildinit_hook
function buildinit_hook () return 0 end
-------------------------------------------------
-- buildinit {{{
-- hack copy of checkinit()
function buildinit ()
  cleandir(fntdir)
  -- l3build never cleans this by default?
  cleandir(localdir)
  dep_install (builddeps)
  -- is this a appropriate? better not?
  for i,j in ipairs(filelist(localdir)) do
    cp(j,localdir,fntdir)
  end
  print("Unpacking ...\n")
  -- unpack() / bundleunpack() are not public?
  local errorlevel = call({sourcefiledir},"unpack") 
  if errorlevel ~= 0 then 
    gwall("Unpacking ",module,errorlevel)
    return nifergwall
  else
    for i,j in ipairs(buildfiles) do
      cp(j,unpackdir,fntdir)
    end
    if #buildsuppfiles_sys ~= 0 then
      for _,j in ipairs(buildsuppfiles_sys) do
        if fileexists(j) then
          cp(basename(j),dirname(j),fntdir)
        else
          local jpath = kpse.find_file(j)
          local jdir = dirname(jpath)
          cp(j,jdir,fntdir)
        end
      end
    end
  end
  if not buildsearch then
    -- we aren't typesetting, so we really don't need a map file
    -- not sure this is really needed - do any tools use this anyway?
    -- https://rosettacode.org/wiki/Create_a_file
    io.open(fntdir .. "/pdftex.map", "w"):close()
  end
  return buildinit_hook()
end
-- }}}
-------------------------------------------------
local build_fnt_env = {} 
-------------------------------------------------
-- build_fnt {{{
function build_fnt (dir,cmd,file)
  file = file or ""
  cmd = cmd or ""
  dir = dir or unpackdir
  local build_fnt_envset = ""
  if #build_fnt_env ~= 0 then
    for _,i in ipairs(build_fnt_env) do
      build_fnt_envset = build_fnt_envset .. os_concat .. os_setenv .. " " .. i
    end
  end
  -- steal from l3build-check.lua
  local preamble =
    -- would it be simpler to copy the typesetting sandbox here?
    -- paths in the logs don't matter and copying localdir complicates things a bit
    -- No use of localdir here as the files get copied to testdir:
    -- avoids any paths in the logs
    os_setenv .. " TEXINPUTS=." .. localtexmf()
    .. (buildsearch and os_pathsep or "")
    .. os_concat ..
    -- no need for LUAINPUTS here
    -- but we need to set more variables ...?
    (buildsearch and "" or 
      (os_setenv .. " TEXMFAUXTREES={}"
      .. os_concat .. os_setenv .. " TEXMFHOME={}"
      .. os_concat .. os_setenv .. " TEXMFLOCAL={}"
      .. os_concat .. os_setenv .. " TEXMFCONFIG=."
      .. os_concat .. os_setenv .. " TEXMFVAR=."
      .. os_concat .. os_setenv .. " VFFONTS=${TEXINPUTS}"
      .. os_concat .. os_setenv .. " TFMFONTS=${TEXINPUTS}"
      .. os_concat .. os_setenv .. " TEXFONTMAPS=${TEXINPUTS}"
      .. os_concat .. os_setenv .. " T1FONTS=${TEXINPUTS}"
      .. os_concat .. os_setenv .. " AFMFONTS=${TEXINPUTS}"
      .. os_concat .. os_setenv .. " TTFFONTS=${TEXINPUTS}"
      .. os_concat .. os_setenv .. " OPENTYPEFONTS=${TEXINPUTS}"
      .. os_concat .. os_setenv .. " LIGFONTS=${TEXINPUTS}"
      .. os_concat .. os_setenv .. " ENCFONTS=${TEXINPUTS}")
    )
    .. build_fnt_envset
    .. os_concat
  local errorlevel = runcmd(
    preamble .." " ..  cmd .. " " .. file, dir
  )
  gwall(cmd,file,errorlevel)
  return errorlevel
end
-- }}}
-------------------------------------------------
-- finst {{{
function finst (patt,dir,mode)
  dir = dir or "."
  mode = mode or "nonstopmode"
  local cmd = "pdftex --interaction=" .. mode
  local targs = {}
  -- https://lunarmodules.github.io/luafilesystem/examples.html (expl)
  -- l3build-file-functions.lua (filelist fn)
  targs = filelist(dir,patt)
  for i,j in ipairs(targs) do
    -- local errorlevel = tex(j,dir,cmd)
    local errorlevel = build_fnt(dir,cmd,j)
    gwall("Compilation of ", j, errorlevel)
  end
end
-- }}}
-------------------------------------------------
-- fntkeeper {{{
function fntkeeper (dir)
  dir = dir or fntdir
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
  local keepdir = abspath(keepdir) -- abspath requires existence
  if keepfiles ~= {} then
    for i,j in ipairs(keepfiles) do
      local rtn = cp(j, dir, keepdir)
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
      local errorlevel = cp(j,dir,keeptempdir)
      if errorlevel ~= 0 then
        gwall("Copy ", j, errorlevel)
      end
    end
  end	
  return nifergwall
end
-- }}}
-------------------------------------------------
-- uniquify {{{
-- oherwydd fy mod i bron ag anfon pob un ac mae'n amlwg fy mod i wedi anfon bacedi heb ei wneud hwn yn y gorffennol, well i mi wneud rhywbeth (scriptiau gwneud-cyhoeddus a make-public yn argraffu rhybudd os encs yn y cymysg
-- (cymraeg yn ofnadwy hefyd)
function uniquify (tag)
  local dir = ""
  tag = tag or encodingtag or ""
  local pkgbase = pkgbase or ""
  local pkglist = {}
  if standalone then
    dir = keepdir
  else
    dir = fntdir
  end
  if fileexists(dir .. "/pdftex.map") then
    print("Removing temporary pdftex.map from " .. dir .. "...\n")
    local errorlevel = rm(dir,"pdftex.map")
    gwall("Removing ","pdftex.map",errorlevel)
  end
  if pkgbase == "" then 
    print("pkgbase unspecified. Trying to guess ... ")
    if not standalone then 
      pkglist = filelist(dir,"*.sty")
      if #pkglist == 0 then
        pkglist = filelist(unpackdir,"*.sty")
      end
      if #pkglist ~= 0 then
        pkgbase = string.gsub(pkglist[1], "%.sty", "")
        print("Guessing " .. pkgbase)
      end
    end
  end
  if pkgbase == "" then
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
  if pkgbase == "" then 
    pkgbase = "NotAMatchAtAll" 
    gwall("Guessing pkgbase ","",1)
  end
  local encs = encs or filelist(dir,"*.enc")
  local maps = maps or filelist(dir,"*.map")
  print("Uniquifying encodings ... ")
  for _,i in ipairs(encs) do print(" " .. i) end
  print("\nUniquifying maps ... ")
  for _,i in ipairs(maps) do print(" " .. i) end
  print(" ...\n")
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
        if string.match(j,"-" .. tag .. "%.enc$") or  string.match(j, module) or string.match(j,ctanpkg) or string.match(j,pkgbase) or string.match(j, string.gsub(module, "adf", "")) then
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
                      print("Nothing to do for " .. m .. ".\n")
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
-- }}}
-------------------------------------------------
-- fontinst {{{
function fontinst (dir,mode)
  -- dir = dir or unpackdir
  dir = dir or fntdir
  mode = mode or "errorstopmode --halt-on-error"
  standalone = false
  encodingtag = encodingtag or ""
  -- if not buildsearch then
  --   -- unnecessary?
  --   build_fnt_env = { "TEXINPUTS.fontinst=${TEXINPUTS}" }
  -- end
  if #buildsuppfiles_sys == 0 then
    print("Assuming all fontinst files should be available during build.\n")
    local path = kpse.var_value("TEXMFDIST") .. "/tex/fontinst"
    buildsuppfiles_sys = lsrdir(path)
  end
  buildinit ()
  local tfmfiles = filelist(dir,"*.tfm")
  for i,j in ipairs(tfmfiles) do
    local plname = string.gsub(j, "%.tfm$", ".pl")
    if fileexists(dir .. "/" .. plname) then
      print(plname .. " already exists!")
      return 1
    else
      local cmd = "tftopl " .. j .. " " .. plname
      -- safe or not?
      local errorlevel = runcmd(cmd,dir)
      -- necessary or not?
      -- local errorlevel = build_fnt(cmd,dir)
      gwall("Conversion to pl from tfm ",j,errorlevel)
      -- remove tfm to reduce pollution of package later
      rm(dir,j)
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
  print("Tidying up build directory ...\n")
  for _,i in ipairs(buildsuppfiles_sys) do
    local errorlevel = rm(dir,i) 
    gwall("Removal of ",dir .. "/" .. i,errorlevel)
  end
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
          -- local errorlevel = runcmd(line,dir)
          local errorlevel = build_fnt(dir,line)
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
    -- local cmd = "vptovf " .. j
    -- local errorlevel = runcmd(cmd,dir)
    local cmd = "vptovf"
    local errorlevel = build_fnt(dir,cmd,j)
    gwall("Creation of virtual font from ", j, errorlevel)
  end
  -- edit the .fd files if a scale factor is declared because fontinst 
  -- doesn't allow us to do this and the last message to the mailing list
  -- is from 2022 with no response from the maintainer
  local fdfiles = filelist(dir, "*.fd")
  for i,j in ipairs(fdfiles) do
    local f = assert(io.open(dir .. "/" .. j,"rb"))
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
      local f = assert(io.open(dir .. "/" .. j,"w"))
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
    gwall("FONT KEEPER FAILED! DO NOT MAKE STANDARD TARGETS WITHOUT RESOLVING!! fntkeeper() ", dir, errorlevel)
  end
  return nifergwall
end
-- }}}
-------------------------------------------------
-------------------------------------------------
-- fnt_test {{{
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
-- }}}
-------------------------------------------------
checksuppfiles_sys = checksuppfiles_sys or {}
checksuppfiles_add = checksuppfiles_add or {}
-------------------------------------------------
-- checkinit_hook {{{
function checkinit_hook ()
  local filename = "fnt-test.lvt"
  local file = unpackdir .. "/" .. filename
  local fnttestdir = maindir .. "/fnt-tests"
  local maps = ""
  local mapfiles=filelist(keepdir, "*.map")
  local mapsdir = ""
  local fdsdir = ""
  local adds = checksuppfiles_addlst or maindir .. "/checksuppfiles-add.lst"
  if not checksearch then
    map_cat(mapfiles_sys,testdir)
  end
  -- how did this ever work?
  for _,i in ipairs(filelist(keepdir)) do
    if i ~= "." and i ~= ".." then
      local errorlevel = cp(i,keepdir,testdir) 
      gwall("Copying ",i,errorlevel)
    end
  end
  if #checksuppfiles_sys == 0 then
    print("Assuming some basic files should be available during testing.\n")
    if fileexists(adds) then
      print("Adding files from " .. adds .. " to file list.\n")
      for line in io.lines(adds) do
        table.insert(checksuppfiles_sys,line)
      end
    end
    local d = { 
      "/tex/latex/l3build", 
      "/tex/latex/l3backend",
      "/tex/latex/lm" ,
      "/fonts/enc/dvips/base",
      "/fonts/enc/dvips/lm",
      "/fonts/enc/dvips/cm-super",
      "/fonts/type1/public/lm",
      "/fonts/type1/public/cm-super",
      "/fonts/tfm/public/cm",
      "/fonts/tfm/jknappen/ec",
      "/fonts/tfm/public/cm-super",
      "/fonts/tfm/public/lm" }
    for _,i in ipairs(d) do
      local path = kpse.var_value("TEXMFDIST") .. i
      if direxists(path) then
        -- print("Adding files from " .. i .. " to file list.\n")
        print("Adding files from " .. i .. " to test directory.\n")
        local tmpls = filelist(path)
        for _,j in ipairs(tmpls) do
          if j ~= "." and j ~= ".." then
            local errorlevel = cp(j,path,testdir)
            gwall("Copying ",path .. "/" .. j,errorlevel)
          end
        end
        -- checksuppfiles_sys = lsrdir(path,checksuppfiles_sys)
      end
    end
    if #checksuppfiles_add ~= 0 then
      for _,i in ipairs(checksuppfiles_add) do
        print("Adding " .. i .. " to file list.\n")
        table.insert(checksuppfiles_sys,i)
      end
    end
  end
  print("Copying itemised system files to " .. testdir .. ".\n")
  if #checksuppfiles_sys ~= 0 then
    for _,j in ipairs(checksuppfiles_sys) do
      -- local jpath = kpse.find_file(j)
      local jpath = kpse.lookup(j)
      if jpath ~= nil then 
        local jdir = dirname(jpath)
        local errorlevel = cp(j,jdir,testdir) 
        gwall("Copying ",j,errorlevel)
      else
        gwall("Finding ",j,errorlevel)
      end
    end
  end
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
    if #autotestfdstmp == 0 then
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
  -- but remember fnttestfds may be pairs and/or ipairs ...
  -- there must be a better way to do this ...
  if #fnttestfds == 0 then
    for i,j in ipairs(fntpkgnames) do 
      if fnttestfds[j] == nil then
        print("Auto-assigning autotestfds to fnttestfds[" .. j .. "].\n")
        fnttestfds[j] = {}
        for a,b in ipairs(autotestfds) do
          table.insert(fnttestfds[j],b)
        end
      end
    end
  else
    local testmes = {}
    for i,j in ipairs(fnttestfds) do
      table.insert(testmes,j)
    end
    for i, j in ipairs(fntpkgnames) do
      -- I really don't understand tables (and I know this is very, very basic)
      if fnttestfds[j] == nil then
        fnttestfds[j] = {}
        -- use only if fnttestfds isn't specified either as table of tables or table of files/globs
        -- this doesn't seem very robust
        for k, l in ipairs(testmes) do
          table.insert (fnttestfds[j], l)
        end
      end
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
        -- dyw fnttestfds.j ddim yn gweithio yma!!
        errorlevel = fnt_test(j,fnttestfds[j],content,maps,fdsdir)
        if errorlevel ~= 0 then
          gwall("Font test creation ", j, errorlevel)
          return errorlevel
        end
      end
      rm(unpackdir,filename)
    end
  end
  if not checksearch then
    checkopts = checkopts 
      .. " --cnf-line=TEXMFAUXTREES={} --cnf-line=TEXMFHOME={} --cnf-line=TEXMFLOCAL={} --cnf-line=TEXMFCONFIG=. --cnf-line=TEXMFVAR=. --cnf-line=VFFONTS=."
      .. localtexmf() .. " --cnf-line=TFMFONTS=."
      .. localtexmf() .. " --cnf-line=TEXFONTMAPS=."
      .. localtexmf() .. " --cnf-line=T1FONTS=."
      .. localtexmf() .. " --cnf-line=AFMFONTS=."
      .. localtexmf() .. " --cnf-line=TTFFONTS=."
      .. localtexmf() .. " --cnf-line=OPENTYPEFONTS=."
      .. localtexmf() .. " --cnf-line=LIGFONTS=."
      .. localtexmf() .. " --cnf-line=ENCFONTS=."
      .. localtexmf() 
  end
  return 0
end
-- }}}
-------------------------------------------------
-- doc_init {{{
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
-- }}}
-------------------------------------------------
-- fontinst must be specified first
-- it just ain't TeX
-- ntarg {{{
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
-- }}}
-- utarg {{{
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
-- }}}
-- diwedd targets
-------------------------------------------------
autotestfds = autotestfds or {}
-- auxfiles = {"*.aux"}
bakext = ".bkup"
binaryfiles = {"*.pdf", "*.zip", "*.vf", "*.tfm", "*.pfb", "*.pfm", "*.ttf", "*.otf", "*.tar.gz"}
binmakers = {"*-pltotf.sh"}
-- maindir before checkdeps
-- maindir = "../.."
checkdeps = {maindir .. "/nfssext-cfr", maindir .. "/fnt-tests"}
checkengines = { "pdftex" } 
-- os_concat ..
--     (checksearch and
--       (os_setenv .. " TEXMFAUXTREES={}"
--       .. os_concat .. os_setenv .. " TEXMFHOME={}"
--       .. os_concat .. os_setenv .. " TEXMFLOCAL={}"
--       .. os_concat .. os_setenv .. " TEXMFCONFIG=."
--       .. os_concat .. os_setenv .. " TEXMFVAR=."
--       .. os_concat .. os_setenv .. " TEXVFFONTS=${TEXINPUTS}"
--       .. os_concat .. os_setenv .. " TEXTFMFONTS=${TEXINPUTS}"
--       .. os_concat .. os_setenv .. " TEXFONTMAPS=${TEXINPUTS}"
--       .. os_concat .. os_setenv .. " TEXT1FONTS=${TEXINPUTS}"
--       .. os_concat .. os_setenv .. " TEXAFMFONTS=${TEXINPUTS}"
--       .. os_concat .. os_setenv .. " TEXTTFFONTS=${TEXINPUTS}"
--       .. os_concat .. os_setenv .. " TEXOPENTYPEFONTS=${TEXINPUTS}"
--       .. os_concat .. os_setenv .. " TEXLIGFONTS=${TEXINPUTS}"
--       .. os_concat .. os_setenv .. " TEXENCFONTS=${TEXINPUTS}"
--     ) or "")
--     .. os_concat .. "pdftex"}
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
installfiles = {"*.afm", "*.cls", "*.enc", "*.fd", "*.map", "*.otf", "*.pfb", "*.pfm", "*.sty", "*.tfm", "*.ttf", "*.vf"}
-- match default as not yet existent
sourcefiledir = sourcefiledir or "."
keepdir = keepdir or sourcefiledir .. "/keep"
keeptempdir = keeptempdir or sourcefiledir .. "/keeptemp"
keepfiles = keepfiles or {"*.enc", "*.fd", "*.map", "*.tfm", "*.vf"}
keeptempfiles = keeptempfiles or {"*.mtx", "*.pl", "*-pltotf.sh", "*-rec.tex", "*.vpl", "*.zz"}
manifestfile = "manifest.txt"
mapmakers = {"*-map.tex"}
packtdszip = false
-- need module test or default?
sourcefiles = {"*.afm", "afm/*.afm", "*.pfb", "*.pfm", "*.dtx", "*.ins", "opentype/*.otf", "*.otf", "tfm/*.tfm", "truetype/*.ttf", "*.ttf", "type1/*.pfb", "type1/*.pfm"}
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
-------------------------------------------------
if fileexists(maindir .. "/fnt-ctan.lua") then
  dofile(maindir .. "/fnt-ctan.lua")
end
-------------------------------------------------
-- afmtotfm
-- only set this true for ultra simple symbol fonts!
afmtotfm = afmtotfm or false
-------------------------------------------------
-- fnt_afmtotfm (dir,mode) {{{
function fnt_afmtotfm (dir,mode)
  dir = dir or fntdir
  mode = mode or "errorstopmode --halt-on-error"
  local fntbasename = fntbasename or module
  local map = mapfile or fntbasename .. ".map"
  local fntencs = fntencs or {}
  standalone = false
  encodingtag = encodingtag or ""
  -- if #buildsuppfiles_sys == 0 then
  --   print("Assuming all fontinst files should be available during build.\n")
  --   local path = kpse.var_value("TEXMFDIST") .. "/tex/fontinst"
  --   buildsuppfiles_sys = lsrdir(path)
  -- end
  buildinit ()
  print("Running afm2tfm. Please be patient ...\n")
  local afms = filelist(dir,"*.afm")
  local content = ""
  for i,k in ipairs(afms) do
    j = string.gsub(k,"%.afm","")
    if fntencs[j] == nil then 
      local rtn = fileexists(dir .. "/" .. j .. ".enc")
      if not rtn then
        -- errorlevel = run(dir, "afm2tfm " .. k .. " >> " .. dir .. "/" .. map .. ".tmp")
        errorlevel = build_fnt(dir,"afm2tfm " .. k " >> " .. dir .. "/" .. map .. ".tmp")
      else
        -- errorlevel = run(dir, "afm2tfm " .. k .. " -p " .. j .. ".enc" .. " >> " .. dir .. "/" .. map .. ".tmp")
        errorlevel = build_fnt(dir, "afm2tfm " .. k .. " -p " .. j .. ".enc" .. " >> " .. dir .. "/" .. map .. ".tmp")
      end
    else
      if not fileexists(dir .. "/" .. fntencs[j]) then
        gwall("Search for encoding specified for " .. j .. " ",dir,1)
      else
        -- errorlevel = run(dir, "afm2tfm " .. k .. " -p " .. fntencs[j] .. " >> " .. dir .. "/" .. map .. ".tmp")
        errorlevel = build_fnt(dir, "afm2tfm " .. k .. " -p " .. fntencs[j] .. " >> " .. dir .. "/" .. map .. ".tmp")
      end
    end
    if errorlevel ~= 0 then 
      gwall("afm2tfm (" .. j ..") ",dir,errorlevel) 
    else
      local g = assert(io.open(dir .. "/" .. map .. ".tmp","rb"))
      local c = g:read("all")
      g:close()
      content = content .. string.gsub(c, "\n", " <" .. string.gsub(k,"%.afm",".pfb") .. "\n")
      rm(dir, map .. ".tmp")
    end
  end
  -- need to do this as uniquify() isn't used
  -- otherwise the file ends up in localdir (and probably the package)
  -- catching this is the only benefit I can see in my inability to clean localdir
  if fileexists(dir .. "/pdftex.map") then
    local errorlevel = rm(dir,"pdftex.map") 
    gwall("Removing ","pdftex.map",errorlevel)
  end
  local f
  f = assert(io.open(dir .. "/" .. map, "w"))
  f:write((string.gsub(content,"\n",os_newline_cp)))
  f:close()
  errorlevel = fntkeeper()
  if errorlevel ~= 0 then
    gwall("FONT KEEPER FAILED! DO NOT MAKE STANDARD TARGETS WITHOUT RESOLVING!! ", dir, errorlevel)
  end
  return nifergwall
end
-- }}}
-------------------------------------------------
-- fnt_afmtotfm -> fnttarg {{{
if afmtotfm then
  target_list[ntarg] = {
    func = fnt_afmtotfm,
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
end
-- }}}
-------------------------------------------------
-- vim: ts=2:sw=2:et:foldmethod=marker: