-- $Id: 
-------------------------------------------------
-- fntbuild-build
-------------------------------------------------
-------------------------------------------------
-- map_cat (frags,dir,mapfile) {{{
---@param frags table
---@param dir string 
---@param mapfile string
---@return 0 on success, number of errors otherwise
---@see 
---@usage private
local function map_cat (frags,dir,mapfile)
  mapfile = mapfile or "pdftex.map"
  local n = 0
  if #frags == 0 then 
    frags = { "cm.map", "cm-super-t1.map", "cm-super-ts1.map", "lm.map" }
  end
  if #fnt.mapfiles_add ~= 0 then
    for _,i in ipairs(fnt.mapfiles_add) do
      table.insert(frags,i)
    end
  end
  if fileexists(dir .. "/" .. mapfile) then 
    local errorlevel = rm(dir,mapfile) 
    fnt.gwall("Removal of ",dir .. "/" .. mapfile,errorlevel)
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
        fnt.gwall("Search for map fragment ",i,1)
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
---@return 0
---@usage public
local function buildinit_hook () return 0 end
-------------------------------------------------
-- buildinit {{{
-- hack copy of checkinit()
---@return 0 on success, error level otherwise
---@see 
---@usage public
local function buildinit ()
  cleandir(fnt.fntdir)
  -- l3build never cleans this by default?
  cleandir(localdir)
  fnt.dep_install (fnt.builddeps)
  -- is this a appropriate? better not?
  for i,j in ipairs(filelist(localdir)) do
    cp(j,localdir,fnt.fntdir)
  end
  print("Unpacking ...\n")
  -- direct usage is legitimate ...
  -- https://chat.stackexchange.com/transcript/message/66617079#66617079
  local errorlevel = unpack() 
  if errorlevel ~= 0 then 
    fnt.gwall("Unpacking ",module,errorlevel)
    return fnt.nifergwall
  else
    for i,j in ipairs(fnt.buildfiles) do
      cp(j,unpackdir,fnt.fntdir)
    end
    if #fnt.buildsuppfiles_sys ~= 0 then
      for _,j in ipairs(fnt.buildsuppfiles_sys) do
        if fileexists(j) then
          cp(basename(j),dirname(j),fnt.fntdir)
        else
          local jpath = kpse.find_file(j)
          if jpath == nil then
            jpath = kpse.lookup(j)
          end
          if jpath == nil then
            fnt.gwall("Locating ",j,1)
          end
          local jdir = dirname(jpath)
          cp(j,jdir,fnt.fntdir)
        end
      end
    end
  end
  if not fnt.buildsearch then
    -- we aren't typesetting, so we really don't need a map file
    -- not sure this is really needed - do any tools use this anyway?
    -- https://rosettacode.org/wiki/Create_a_file
    io.open(fnt.fntdir .. "/pdftex.map", "w"):close()
  end
  return buildinit_hook()
end
-- }}}
-------------------------------------------------
-------------------------------------------------
-- build_fnt {{{
---@param file string
---@param cmd string
---@param file string
---@return 0 on success, error level otherwise
---@see 
---@usage public
local function build_fnt (dir,cmd,file)
  file = file or ""
  cmd = cmd or ""
  dir = dir or fnt.fntdir
  local build_fnt_env = fnt.build_fnt_env or {} 
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
    os_setenv .. " TEXINPUTS=." .. fnt.localtexmf()
    .. (fnt.buildsearch and os_pathsep or "")
    .. os_concat ..
    -- no need for LUAINPUTS here
    -- but we need to set more variables ...?!
    (fnt.buildsearch and "" or 
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
  fnt.gwall(cmd,file,errorlevel)
  return errorlevel
end
-- }}}
-------------------------------------------------
-------------------------------------------------
-- fntkeeper {{{
---@param dir string 
---@return 0 on success, error level otherwise
---@see 
---@usage public
local function fntkeeper (dir)
  dir = dir or fnt.fntdir
  local rtn = direxists(fnt.keepdir)
  if not rtn then
    local errorlevel = mkdir(fnt.keepdir)
    if errorlevel ~= 0 then
      print("DO NOT BUILD STANDARD TARGETS WITHOUT RESOLVING!!\n")
      fnt.gwall("Attempt to create directory ", fnt.keepdir, errorlevel)
    end
  else
    local errorlevel = cleandir(fnt.keepdir)
    if errorlevel ~= 0 then
      print("KEEP CONTAMINATED!\n")
      fnt.gwall("Attempt to clean directory ",fnt.keepdir,errorlevel)
    end
  end
  local keepdir = abspath(fnt.keepdir) -- abspath requires existence
  if fnt.keepfiles ~= {} then
    for i,j in ipairs(fnt.keepfiles) do
      local rtn = cp(j, dir, keepdir)
      if rtn ~= 0 then
        fnt.gwall("Copy ", j, errorlevel)
        print("DO NOT BUILD STANDARD TARGETS WITHOUT RESOLVING!\n")
      end
    end
  else
    print("ARE YOU SURE YOU DON'T WANT TO KEEP THE FONTS??!!\n")
  end
  if fnt.keeptempfiles ~= {} then
    rtn = direxists(fnt.keeptempdir)
    if not rtn then
      local errorlevel = mkdir(fnt.keeptempdir)
      if errorlevel ~= 0 then
        fnt.gwall("Attempt to create directory ", fnt.keeptempdir, errorlevel)
      end
    else
      local errorlevel = cleandir(fnt.keeptempdir)
      if errorlevel ~= 0 then
        print("keeptemp contaminated!\n")
        fnt.gwall("Attempt to clean directory ",fnt.keeptempdir,errorlevel)
      end
    end
    for i,j in ipairs(fnt.keeptempfiles) do 
      local errorlevel = cp(j,dir,fnt.keeptempdir)
      if errorlevel ~= 0 then
        fnt.gwall("Copy ", j, errorlevel)
      end
    end
  end	
  return fnt.nifergwall
end
-- }}}
-------------------------------------------------
-------------------------------------------------
-- fnt_subset {{{
---@params fd, family, fnt.subset
---@usage private
local function fnt_subset (fd,fam,subset)
  local defn = string.gsub(fnt.subsettemplate,"%$FONTFAMILY",fam)
  defn = string.gsub(defn,"%$SUBSET",subset)
  local f = assert(io.open(fnt.fntdir .. "/" .. fd, "rb"))
  local content = f:read("*all")
  f:close()
  local patt
  if string.match(content, "\\endinput") then
    patt = "(\\endinput)"
  else
    patt = "()$"
  end
  f = assert(io.open(fnt.fntdir .. "/" .. fd, "w"))
  f:write("%% Encoding subset declaration added by fontscripts\n",
    (string.gsub(content,patt,"\n\n" .. defn .. "\n\n%1"))
  )
  f:close()
  return 0    -- how to make this return an error level?
end
-- }}}
-------------------------------------------------
-- fntsubsetter {{{
---@param  
---@description add encoding fnt.subset definitions for TS1 if applicable and requested
---@return 0 on success, error level or 1 otherwise
---@see 
---@usage public
local function fntsubsetter ()
  local tcsubset = tcsubset or "9"
  if fnt.subset == nil or fnt.subset == false then return 0 end
  local subsetfiles = fnt.subsetfiles or {}
  if type(subsetfiles) == "string"  and subsetfiles ~= "auto" then
    local s = subsetfiles
    subsetfiles = { s }
  end
  if #subsetfiles == 0 then
    for i in lfs.dir(fnt.fntdir) do
      -- we avoid using filelist() here because it doesn't support char sets
      if string.match(i, "^[Tt][Ss]1.*%.fd$") then
        table.insert(subsetfiles,i)
      end
    end
  end
  if #subsetfiles == 0 then return 0 end
  for _, i in ipairs(subsetfiles) do
    local fam = string.gsub(i, "^[Tt][Ss]1(.+)%.fd$", "%1")
    local s = fnt.subsetdefns[fam] or tcsubset
    local errorlevel = fnt_subset(i,fam,s)
    fnt.gwall("Inserting TS1 subset definition ",i,errorlevel)
  end
  return fnt.nifergwall
end
-- }}}
-------------------------------------------------
-------------------------------------------------
-- uniquify {{{
-- oherwydd fy mod i bron ag anfon pob un ac mae'n amlwg fy mod i wedi anfon 
-- bacedi heb ei wneud hwn yn y gorffennol, well i mi wneud rhywbeth (scriptiau 
-- gwneud-cyhoeddus a make-public yn argraffu rhybudd os encs yn y cymysg
-- (cymraeg yn ofnadwy hefyd)
---@param tag string 
---@return 0 on success, error level or 1 otherwise
---@see 
---@usage public
local function uniquify (tag)
  local dir = ""
  tag = tag or fnt.encodingtag or ""
  local pkgbase = fnt.pkgbase or ""
  local pkglist = {}
  if standalone then
    dir = fnt.keepdir
  else
    dir = fnt.fntdir
  end
  if fileexists(dir .. "/pdftex.map") then
    print("\nRemoving temporary pdftex.map from ", dir, "...\n")
    local errorlevel = rm(dir,"pdftex.map")
    fnt.gwall("Removing ","pdftex.map",errorlevel)
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
        print("Guessing ", pkgbase)
      end
    end
  end
  if pkgbase == "" then
    if ctanpkg ~= module and module ~= "" and module ~= nil then
      print("Guessing ", module)
      pkgbase = module
    else
      pkgbase = string.gsub(ctanpkg, "adf$", "")
      if pkgbase ~= "" then
        print("Guessing ", pkgbase)
      end
    end
  end
  if pkgbase == "" then 
    pkgbase = "NotAMatchAtAll" 
    fnt.gwall("Guessing pkgbase ","",1)
  end
  local encs = encs or filelist(dir,"*.enc")
  local maps = maps or filelist(dir,"*.map")
  print("Uniquifying encodings ... ")
  for _,i in ipairs(encs) do print(" ", i) end
  print("\nUniquifying maps ... ")
  for _,i in ipairs(maps) do print(" ", i) end
  print(" ...\n")
  if #encs == 0 then
    return 0
  elseif tag == "" then 
    if #maps ~= 0  then
      if #maps == 1 then
        tag = string.gsub(maps[1],"%.map$","")
      else
        local t = "" 
        local tt = ""
        for i,j in ipairs(maps) do
          if tt == t then 
            tt = string.gsub(j,"%w%.map$","")
          elseif t == "" then
            t = string.gsub(j,"%w%.map$","")
          end
        end
        if t == tt then
          tag = tt
        else
          fnt.gwall("Attempt to find tag ","",1)
        end
      end
    end
    if tag ~= "" then  
      for i, j in ipairs(encs) do
        if string.match(j,"-" .. tag .. "%.enc$") 
          or  string.match(j, module) 
          or string.match(j,ctanpkg) 
          or string.match(j,pkgbase) 
          or string.match(j, string.gsub(module, "adf", "")) then
          print(j, "... OK\n")
        else
          local targenc = (string.gsub(j,"%.enc$","-" .. tag .. ".enc"))
          print("Target encoding is", targenc, "\n")
          if fileexists(dir .. "/" .. targenc) then
            fnt.gwall("Target encoding exists !! ", targenc, 1)
            return 1
          else
            local f = assert(io.open(dir .. "/" .. j,"rb"))
            local content = f:read("*all")
            f:close()
            local new_content = (string.gsub(content,
            "(\n%%%%BeginResource: encoding fontinst%-autoenc[^\n ]*)( *\n/fontinst%-autoenc[^ %[]*)( %[)",
              "\n%% Encoding renamed by fontscripts\n\n%1-" 
              .. tag .. "%2-" .. tag .. "%3"
            ))
            if new_content ~= content then
              print("Writing unique encoding to ", targenc)
              f = assert(io.open(dir .. "/" .. targenc,"w"))
              -- remove the second value returned by string.gsub
              f:write((string.gsub(new_content,"\n",fnt.os_newline_cp)))
              f:close()
              if fileexists(dir .. "/" .. targenc) then
                local errorlevel = rm(dir,j)
                if errorlevel ~= 0 then
                  fnt.gwall("Attempt to rm old encoding ",j,errorlevel)
                end
                if #maps ~= 0 then
                  local jpatt = string.gsub(j,"%-","%%-")
                  jpatt = string.gsub(jpatt,"%.","%%.")
                  for k,m in ipairs(maps) do
                    f = assert(io.open(dir .. "/" .. m,"rb"))
                    local mcontent = f:read("*all")
                    f:close()
                    local new_mcontent = (string.gsub(mcontent,
                      "(%<%[?)" .. jpatt .. 
                      "( %<%w+%.pfb \" fontinst%-autoenc[%w%-_]*)( ReEncodeFont)", 
                      "%1" .. targenc .. "%2-" .. tag .. "%3"
                    ))
                    if new_mcontent ~= mcontent then 
                      print("Writing adjusted map lines to ", m)
                      f = assert(io.open(dir .. "/" .. m,"w"))
                      -- remove the second value returned by string.gsub
                      f:write("%% Encodings renamed by fontscripts\n",
                      (string.gsub(new_mcontent,"\n",fnt.os_newline_cp)))
                      f:close()
                    else
                      print("Nothing to do for ", m, ".\n")
                    end
                  end
                else
                  print("FOUND NO MAPS??\n")
                end
              else
                fnt.gwall("Attempt to write ",targenc,1)
              end
            else
              fnt.gwall("Attempt to uniquify " .. j .. " as ",targenc,1)
            end
          end
        end
      end
    end
    return fnt.nifergwall
  end
  print("Something weird happened.\n")
  return 1
end
-- }}}
-------------------------------------------------
-------------------------------------------------
-- fontinst
-------------------------------------------------
-- finst {{{
---@param patt string
---@param dir string
---@param mode string
---@return 
---@see 
---@usage public
local function finst (patt,dir,mode)
  dir = dir or "."
  mode = mode or "nonstopmode"
  local cmd = "pdftex --interaction=" .. mode
  -- https://lunarmodules.github.io/luafilesystem/examples.html (expl)
  -- l3build-file-functions.lua (filelist fn)
  local targs = filelist(dir,patt)
  for i,j in ipairs(targs) do
    -- local errorlevel = tex(j,dir,cmd)
    local errorlevel = build_fnt(dir,cmd,j)
    fnt.gwall("Compilation of ", j, errorlevel)
  end
end
-- }}}
-------------------------------------------------
-- fontinst {{{
---@param dir string
---@param mode string
---@return 0 on success, error level otherwise
---@see 
---@usage public 
local function fontinst (dir,mode)
  -- dir = dir or unpackdir
  dir = dir or fnt.fntdir
  mode = mode or "errorstopmode --halt-on-error"
  standalone = false
  fnt.encodingtag = fnt.encodingtag or ""
  if #fnt.buildsuppfiles_sys == 0 then
    print("Assuming all fontinst files should be available during build.\n")
    local path = kpse.var_value("TEXMFDIST") .. "/tex/fontinst"
    fnt.buildsuppfiles_sys = fnt.lsrdir(path)
  end
  buildinit ()
  local tfmfiles = filelist(dir,"*.tfm")
  for i,j in ipairs(tfmfiles) do
    local plname = string.gsub(j, "%.tfm$", ".pl")
    if fileexists(dir .. "/" .. plname) then
      print(plname,  "already exists!")
      return 1
    else
      local cmd = "tftopl " .. j .. " " .. plname
      -- safe or not?
      local errorlevel = runcmd(cmd,dir)
      -- necessary or not?
      -- local errorlevel = build_fnt(cmd,dir)
      fnt.gwall("Conversion to pl from tfm ",j,errorlevel)
      -- remove tfm to reduce pollution of package later
      rm(dir,j)
      fnt.gwall("Deletion of tfm ", j, errorlevel)
    end
  end
  for i,j in ipairs(fnt.familymakers) do
    local errorlevel = finst(j,dir,mode)
    fnt.gwall("Compilation of driver ", j, errorlevel)
  end
  if fnt.nifergwall ~= 0 then return fnt.nifergwall end
  for i,j in ipairs(fnt.mapmakers) do
    local errorlevel = finst (j,dir,mode)
    fnt.gwall("Compilation of map ", j, errorlevel)
  end
  if fnt.nifergwall ~= 0 then return fnt.nifergwall end
  print("Tidying up build directory ...\n")
  for _,i in ipairs(fnt.buildsuppfiles_sys) do
    local errorlevel = rm(dir,i) 
    fnt.gwall("Removal of ",dir .. "/" .. i,errorlevel)
  end
  for i,j in ipairs(fnt.binmakers) do
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
          fnt.gwall("Creation of TFM using " .. line .. " from ", j, errorlevel)
        else
          print("Ignoring unexpected line \"" .. line .. "\" in", j .. ".\n")
          fnt.nifergwall = fnt.nifergwall + 1
        end
      end
    end
  end
  if fnt.nifergwall ~= 0 then return fnt.nifergwall end
  local targs = filelist(dir,"*.vpl")
  for i,j in ipairs(targs) do
    -- local cmd = "vptovf " .. j
    -- local errorlevel = runcmd(cmd,dir)
    local cmd = "vptovf"
    local errorlevel = build_fnt(dir,cmd,j)
    fnt.gwall("Creation of virtual font from ", j, errorlevel)
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
        new_content = string.gsub(content, "(\\DeclareFontFamily{)", 
        "%% addaswyd o t1phv.fd (dyddiad y ffeil fd: 2020-03-25)\n\\expandafter\\ifx\\csname " 
        .. csscale .. "\\endcsname\\relax\n  \\let\\" .. csscaleaux 
        .. "\\@empty\n\\else\n  \\edef\\" .. csscaleaux 
        .. "{s*[\\csname " .. csscale .. "\\endcsname]}%%\n\\fi\n\n%1")
      end
    end
    csscaleaux = string.match(content, 
    "\\DeclareFontFamily{[^}]*}{[^}]*}{[^}]*\\hyphenchar *\\font *=[^}\n]*}") 
    if csscaleaux ~= nil then
      content = new_content
      new_content = string.gsub(content, 
      "(\\DeclareFontFamily{[^}]*}{[^}]*}{\\hyphenchar) *(\\font) *(=[^ }\n]*) *([^ }\n]* *})", 
      "%1%2%3%4")
    end
    if new_content ~= content then
      local f = assert(io.open(dir .. "/" .. j,"w"))
      -- this somehow removes the second value returned by string.gsub??
      f:write("%% Scaling added by fontscripts\n",(string.gsub(new_content,
        "\n",fnt.os_newline_cp)))
      f:close()
    end
  end
  local errorlevel = uniquify(fnt.encodingtag)
  if errorlevel ~= 0 then
    fnt.gwall("Encodings not uniquified! Do not submit to CTAN! uniquify(" 
      .. fnt.encodingtag .. ")","",errorlevel)
  end
  errorlevel = fntsubsetter()
  if errorlevel ~= 0 then
    fnt.gwall("Encoding fnt.subset definitions not inserted! fntsubsetter() ","",errorlevel)
  end
  errorlevel = fntkeeper()
  if errorlevel ~= 0 then
    fnt.gwall(
      "FONT KEEPER FAILED! DO NOT MAKE STANDARD TARGETS WITHOUT RESOLVING!! fntkeeper() ", 
      dir, errorlevel)
  end
  return fnt.nifergwall
end
-- }}}
-------------------------------------------------
-------------------------------------------------
-- afm2tfm (simple symbol fonts only)
-------------------------------------------------
-- afm2tfm (dir) {{{
---@param dir string
---@return 0 on success, number of errors otherwise 
---@see 
---@usage public
local function afm2tfm (dir)
  dir = dir or fnt.fntdir
  local fntbasename = fntbasename or module
  local map = mapfile or fntbasename .. ".map"
  local fntencs = fnt.encs or {}
  standalone = false
  fnt.encodingtag = fnt.encodingtag or ""
  buildinit ()
  print("Running afm2tfm. Please be patient ...\n")
  local afms = filelist(dir,"*.afm")
  local content = ""
  for i,k in ipairs(afms) do
    j = string.gsub(k,"%.afm","")
    if fntencs[j] == nil then 
      local rtn = fileexists(dir .. "/" .. j .. ".enc")
      if not rtn then
        errorlevel = build_fnt(dir,"afm2tfm " .. k " >> " .. dir 
          .. "/" .. map .. ".tmp")
      else
        errorlevel = build_fnt(dir, "afm2tfm " .. k .. " -p " .. j 
          .. ".enc" .. " >> " .. dir .. "/" .. map .. ".tmp")
      end
    elseif not fileexists(dir .. "/" .. fntencs[j]) then
      fnt.gwall("Search for encoding specified for " .. j .. " ",dir,1)
    else
      errorlevel = build_fnt(dir, "afm2tfm " .. k .. " -p " .. fntencs[j] 
        .. " >> " .. dir .. "/" .. map .. ".tmp")
    end
    if errorlevel ~= 0 then 
      fnt.gwall("afm2tfm (" .. j ..") ",dir,errorlevel) 
    else
      local g = assert(io.open(dir .. "/" .. map .. ".tmp","rb"))
      local c = g:read("all")
      g:close()
      content = content .. string.gsub(c, "\n", " <" 
        .. string.gsub(k,"%.afm",".pfb") .. "\n")
      rm(dir, map .. ".tmp")
    end
  end
  -- need to do this as uniquify() isn't used
  -- otherwise the file ends up in localdir (and probably the package)
  -- catching this is the only benefit I can see in my inability to clean localdir
  if fileexists(dir .. "/pdftex.map") then
    local errorlevel = rm(dir,"pdftex.map") 
    fnt.gwall("Removing ","pdftex.map",errorlevel)
  end
  local f
  f = assert(io.open(dir .. "/" .. map, "w"))
  f:write((string.gsub(content,"\n",fnt.os_newline_cp)))
  f:close()
  errorlevel = fntkeeper()
  if errorlevel ~= 0 then
    fnt.gwall("FONT KEEPER FAILED! DO NOT MAKE STANDARD TARGETS WITHOUT RESOLVING!! ", 
      dir, errorlevel)
  end
  return fnt.nifergwall
end
-- }}}
-------------------------------------------------
-------------------------------------------------
-- exports {{{
fnt.build_fnt = build_fnt
fnt.buildinit = buildinit
fnt.buildinit_hook = buildinit_hook
fnt.finst = finst
fnt.fntkeeper = fntkeeper
fnt.fntsubsetter = fntsubsetter
fnt.afm2tfm = afm2tfm
fnt.fontinst = fontinst
fnt.map_cat = map_cat
fnt.uniquify = uniquify
-- }}}
-------------------------------------------------
-------------------------------------------------
-- vim: ts=2:sw=2:et:foldmethod=marker:
