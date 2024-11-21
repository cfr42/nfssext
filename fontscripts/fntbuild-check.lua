-- $Id: fntbuild-check.lua 10659 2024-11-21 06:49:20Z cfrees $
-------------------------------------------------
-- fntbuild-check
-------------------------------------------------
-- writes lvt files
-- ensures build products are available
-- enforces sandbox if checksearch is false
-------------------------------------------------
-------------------------------------------------
-- local copio_aux {{{
---Copy files or directory contents recursively.
---@return 0 on success, error level otherwise 
---@see 
---@param locs table
---@param dest string
---@param kpsevar string
---@param indent string
---@usage private
local function copio_aux (locs,dest,kpsevar,indent)
  indent = indent .. "  "
  for _,i in ipairs(locs) do
    local path = kpse.var_value(kpsevar) .. i
    local attr = lfs.attributes (path)
    if type(attr) == "table" then
      if attr.mode == "directory" then
        print(indent .. i .. "/")
        local tmpls = filelist(path)
        for _,j in ipairs(tmpls) do
          if j ~= "." and j ~= ".." then
            local att = lfs.attributes (path .. "/" .. j)
            assert (type(att) == "table")
            if att.mode == "directory" then
              copio_aux({path .. "/" .. j},dest,kpsevar,indent)
            else
              local errorlevel = cp(j,path,dest)
              gwall("Copying ",path .. "/" .. j,errorlevel)
            end
          end
        end
      else
        if fileexists(path) then
          print("  " .. i)
          local errorlevel = cp(basename(path),dirname(path),dest)
          gwall("Copying ",path,errorlevel)
        else
          gwall("Lookup ",path,1)
        end
      end
    else
      gwall("Getting information about ",i,1)
    end
  end
end
-- }}}
-------------------------------------------------
-- local copio {{{
---Copy files or directory contents recursively.
---@return 0 on success, error level otherwise 
---@see 
---@param locs table
---@param dest string
---@param kpsevar string
---@usage private
local function copio (locs,dest,kpsevar)
  if locs == nil then return 0 end
  if #locs == 0 then return 0 end
  kpsevar = kpsevar or "TEXMFDIST"
  copio_aux(locs,dest,kpsevar,"")
end
-- }}}
-------------------------------------------------
-------------------------------------------------
-- fnt_test {{{
---Generates lvt files for l3build check from fds and template.
---@param fntpkgname string
---@param fds table 
---@param content string
---@param maps table
---@param fdsdir string
---@return 0 on success, error level otherwise
---@see 
---@usage public
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
  for i, j in ipairs(fds) do print("  fd: " .. j) end
  print("\n")
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
-------------------------------------------------
-- redefine l3build function
-------------------------------------------------
-- checkinit_hook {{{
---Additional setup for testing tailored to font packages.
---@return 0 on success, error level otherwise 
---@see l3build
---@usage N/A
function checkinit_hook ()
  local filename = "fnt-test.lvt"
  local file = unpackdir .. "/" .. filename
  local fnttestdir = maindir .. "/fnt-tests"
  local maps = ""
  local mapfiles=filelist(keepdir, "*.map")
  local mapsdir = ""
  local fdsdir = ""
  -- local adds = checksuppfiles_addlst or maindir .. "/checksuppfiles-add.lst"
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
  if not checksearch then
    print("\nAssuming some basic files should be available during testing.\n\nAdding files to " .. testdir .. " from")
    if #checksuppfiles_sys == 0 then
      checksuppfiles_sys = { 
        "/tex/latex/base/article.cls",
        "/tex/latex/base/fontenc.sty",
        "/tex/latex/base/omlcmm.fd",
        "/tex/latex/base/omlcmr.fd",
        "/tex/latex/base/omscmr.fd",
        "/tex/latex/base/omscmsy.fd",
        "/tex/latex/base/omxcmex.fd",
        "/tex/latex/base/ot1cmr.fd",
        "/tex/latex/base/ot1cmss.fd",
        "/tex/latex/base/ot1cmtt.fd",
        "/tex/latex/base/size10.clo",
        "/tex/latex/base/size11.clo",
        "/tex/latex/base/size12.clo",
        "/tex/latex/base/t1cmr.fd",
        "/tex/latex/base/t1cmss.fd",
        "/tex/latex/base/t1cmtt.fd",
        "/tex/latex/base/tracefnt.sty",
        "/tex/latex/base/ts1cmr.fd",
        "/tex/latex/base/ts1cmss.fd",
        "/tex/latex/base/ts1cmtt.fd",
        "/tex/latex/base/ucmr.fd",
        "/tex/latex/base/ucmss.fd",
        "/tex/latex/base/ucmtt.fd",
        "/tex/latex/l3build", 
        "/tex/latex/l3backend",
        "/tex/latex/fonttable/fonttable.sty",
        "/fonts/enc/dvips/base",
        "/fonts/enc/dvips/cm-super",
        "/fonts/type1/public/amsfonts/cm",
        "/fonts/type1/public/cm-super",
        "/fonts/tfm/public/cm",
        "/fonts/tfm/jknappen/ec",
      }
    end
    copio(checksuppfiles_sys,testdir,"TEXMFDIST")
    if #checksuppfiles_add ~= 0 then
      local str = kpse.var_value("TEXMFDIST")
      if string.match(str,"%-") then str = string.gsub(str,"%-","%%-") end
      for _,j in ipairs(checksuppfiles_add) do
        if string.match(j,"^/") then
          copio({j},testdir,"TEXMFDIST")
        else
          local jpath = kpse.lookup(j)
          if jpath ~= nil then 
            local jdir = dirname(jpath)
            if string.match(jdir,"^" .. str) then
              print("  " .. jpath)
              local errorlevel = cp(j,jdir,testdir) 
              gwall("Copying ",j,errorlevel)
            else
              gwall("Restricted search for ",j,1)
            end
          else
            gwall("Finding ",j,errorlevel)
          end
        end
      end
    end
  end
  -- setup & test creation
  if #mapfiles == 0 then
    mapfiles=filelist(unpackdir, "*.map")
    if #mapfiles == 0 then
      gwall("Attempt to find map files ", ".map", 1)
      return 1
    else
      print("\nUsing maps from " .. unpackdir)
      mapsdir = unpackdir
    end
  else
    mapsdir = keepdir
    print("\nUsing maps from " .. keepdir)
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
      print("Using fds from " .. unpackdir)
    end
  else
    fdsdir = keepdir
    print("Using fds from " .. keepdir)
  end
  if #autotestfdstmp == 0 then
    print("Something is amiss - this code should never be executed!")
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
        print("\nAuto-assigning autotestfds to fnttestfds[" .. j .. "].\n")
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
-------------------------------------------------
-- vim: ts=2:sw=2:et:foldmethod=marker:
