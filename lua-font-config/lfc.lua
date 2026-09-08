-- $Id: lfc.lua 12026 2026-09-08 06:00:28Z cfrees $
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
local gsub, gmatch, lower = string.gsub, string.gmatch, string.lower

local concat, count, insert = table.concat, table.count, table.insert

lfc = {}
local lfc_requests = {}
local lfc_cache

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Max Chernoff: https://chat.stackexchange.com/transcript/message/69175678#69175678
-- Use ConTeXt's font name database code.
-------------------------------------------------------------------------------

---@mcsubstitute {{{

-- Define a new private environment into which to load "font-syn.lua".
local lfc_env = table.copy(luaotfload.fontloader)
lfc_env.table = table.copy(lfc_env.table)

-- Define some functions required by "font-syn.lua".
local match = string.match
local split = "^(.-)([^/]-)([^/]-)$"

---@mcsubstitute {{{
function lfc_env.resolvers.dowithfilesintree(pattern, handle, before, after)
  local files = luaotfload.aux.font_index().files.full
  for i = 1, #files do
    local filename = files[i]
    if match(filename, pattern) then
      local root, path, name = match(filename, split)
      -- Path is always empty.
      handle("file", root, path, name)
    end
  end
end
-- }}}

---@mcsubstitute {{{
function lfc_env.table.setmetatableindex(t, k)
  if k == "self" then
    return table.setmetatableindex(t, function(tt, kk)
      tt[kk] = kk
      return kk
    end)
  else
    return table.setmetatableindex(t, k)
  end
end
-- }}}

-- Define some dummy functions.
function lfc_env.logs.flush         ()     return nil end
function lfc_env.resolvers.cleanpath(path) return nil end
function lfc_env.resolvers.datastate()     return {}  end
function lfc_env.resolvers.showpath (name) return nil end
function lfc_env.resolvers.splitpath(path) return nil end

-- Load "font-syn.lua" into our private environment.
loadfile(kpse.find_file("font-syn.lua"), "t", lfc_env)()

-- Print a message while generating our font name database so that users
-- don't get confused by the long pause.
do
  local saved = lfc_env.fonts.names.identify
  function lfc_env.fonts.names.identify(force)
    texio.write_nl("Generating font name database...")
    saved(force)
    texio.write(" done.\n")
  end
end

-- Unconditionally load the font name database, regenerating it if
-- necessary.
lfc_env.fonts.names.load(false, false)

-- Get the table of filenames
local cleanfilename = lfc_env.fonts.names.cleanfilename

-- }}}
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local lfc_fonts = lfc_env.fonts
local names = lfc_fonts.names
local resolve = names.resolve
local lookup_font_file = names.lookup_font_file
local font_data = names.data
-------------------------------------------------------------------------------
-- Utilities for caching data
-------------------------------------------------------------------------------
---@function get_cache_path -- {{{
---@description Returns fullname of module cache.
---@statue internal
local function get_cache_path()
  texio.write_nl("[lfc] Accessing cache ...")
  local path = (gsub(lfc_fonts.names.cache.writable, "^(.*/)[^/]+$", "%1" ))
  assert(path ~= nil, "Cannot find place for cache!")
  if not lfs.isdir(path .. "/lfc") then
    assert(file.is_writable(path), "Not writable!")
    assert(lfs.mkdir(path .. "/lfc"), "Cannot create cache " .. path .. 
      "/lfc" .. " directory!")
  end
  path = path .. "/lfc"
  return path .. "/" .. "lfc_cache.lua"
end
-- }}}

---@function read_cache  -- {{{
---@param loc <string> Optional alternate full path for cache.
---@status internal
local function read_cache(loc)
  texio.write_nl("[lfc] Reading cache ...")
  loc = loc or get_cache_path()
  local cache = lfs.isfile(loc) and table.load(loc) or {}
  return cache
end
-- }}}

-- This is almost completely nonsensical -- {{{
---@function write_cache
---@param stuff <table> Table to save. Default: lua_cache.
---@param loc <string>  Full path of cache. Default: from get_cache_path().
local function write_cache(stuff, loc)
  texio.write_nl("[lfc] Writing cache ...")
  stuff = stuff or lfc_cache
  if stuff == nil then return 1 end
  loc = loc or get_cache_path()
  -- Duplicates data referenced by pointers/links/whatever they are.
  table.save (loc, stuff)
end
-- }}}
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

---@function get_font_data -- {{{
---@param fnt   <string>  Font name/family/etc. to resolve.
---@param force <boolean> Whether to force re-generation if .fd found.
-- @description Resolves a font specification and turns the family name into
-- @description    an .fd file name
-- @description If the file exists, records this and returns the metadata
-- @description If not, returns a table of font data, too
local function get_font_data(fnt, force)
  if fnt == nil then return nil end

  -- For return
  local f = {}

  -- Gets file name
  local ff = resolve(fnt)
  if ff == nil then return nil end

  ff = cleanfilename(ff)

  local ext = (string.gsub(ff, "^(.*)%.([^.]+)", "%2"))
  local basename = (string.gsub(ff, "([^/]*)%.([^.]+)", "%1"))
  if ext == nil or basename == nil then return nil end

  local fam_meta = font_data.mappings[ext][basename].familyname
  if fam_meta == nil then return nil end

  -- Return extension, family name and either fd file or font data
  f.metadata = {
    ext = ext,
    fam_meta = fam_meta,
  }

  local fd = "tu" .. fam_meta .. ".fd", "tex"
  f.metadata.fd = fd
  -- If an .fd for family exists, we're done unless force was used
  local fd_file = kpse.find_file(fd) 
  if fd_file ~= nil then
    if force == nil then
      f.metadata.fd_file = fd_file
      -- return f 
    else
      f.metadata.fd_file_old = fd_file
    end
  end

  -- If not, get font data for family

  -- Returns indexed list, limited coverage
  -- local data = font_data.families[fam_meta]

  -- Returns key-val list, wider coverate
  local data = names.list(fam_meta .. ".*",false,true)
  if data == nil then return nil end

  -- names.list returns duplicate names for some font files.
  -- This de-duplicates the list, though I wonder if there's a better method?
  local data_by_filename = {}

  -- One would prefer to use index IDs here, but I'm not sure how to get that
  --  in a nice way.
  for name, fdata in pairs(data) do
    -- choice of name is arbitrary
    data_by_filename[fdata.filename] = data_by_filename[fdata.filename] or name
  end

  -- ‘In place’ doesn't mean what you think :(
  data_by_filename = table.mirrored(data_by_filename)

  -- Discard dupes
  for name, fdata in pairs(data) do
    if data_by_filename[name] == nil then
      data[name] = nil
    end
  end

  -- Data doesn't include full paths, so add these now.
  for name,info in pairs(data) do
    if info.fullpath == nil then
      -- Gets full path from file name.
      info.fullpath = lookup_font_file(info.filename)
    end
  end

  f.data = data

  return f
end 
-- }}}

-------------------------------------------------------------------------------
-- Tables to translate db descriptors for context into 
-- LaTeX NFSS identifiers from fntguide
-------------------------------------------------------------------------------
local weights = { -- {{{
--[[
  ul Ultra Light
  el Extra Light
  l Light
  sl Semi Light
  m Medium (normal)
  sb Semi Bold
  b Bold
  eb Extra Bold
  ub Ultra Bold
--]]
  ultralight = "ul",
  extralight = "el",
  semilight = "sl",
  semi = "sl",  
  light = "l",
  regular = "m",
  normal = "m",
  medium = "m",
  book = "m",
  mediumbold = "sb",
  demi = "db",
  semibold = "sb",
  demibold = "db",
  bold = "b",
  bol = "b",
  black = "eb",
  heavy = "eb",
  extrabold = "eb",
  ultra = "ub",
  ultrabold = "ub",
} -- }}}
local widths  = { -- {{{
--[[
uc Ultra Condensed 50%
ec Extra Condensed 62.5%
c Condensed 75%
sc Semi Condensed 87.5%
m Medium 100%
sx Semi Expanded 112.5%
x Expanded 125%
ex Extra Expanded 150%
ux Ultra Expanded 200%
--]]
  ultracondensed  = "uc",
  extracondensed  = "ec",
  thin = "c",
  cond = "c",
  condensed = "c",
  semicondensed = "sc",
  normal = "m",
  book = "m",
  medium = "m",
  semiexpanded = "sx",
  expa = "x",
  expanded = "x",
  extraexpanded = "ex",
  ultraexpanded = "ux",
} -- }}}

local styles = { -- {{{
--[[
  n     Normal (that is ‘upright’ or ‘roman’)
  it    Italic
  sl    Slanted (or ‘oblique’)
scit  Caps and small caps italic
scsl  Caps and small caps slanted
sw    Swash
ssc Spaced caps and small caps
--]]
  normal = "n",
  regular = "n",
  roman = "n",
  italic = "it",
  oblique = "sl",
  slanted = "sl",
  reverseitalic = "ri",
  reverseoblique = "ro",
  uprightitalic = "ui",
  outline = "o"
  -- italicsmallcaps = "scit",
  -- obliquesmallcaps = "scsl",
  -- swash = "sw",
} -- }}}

local variants = { -- {{{
--[[
  sc    Caps and small caps
--]]
  normal = "n",
  oldstyle = "oldstyle",
  smallcaps = "sc",
} -- }}}

-------------------------------------------------------------------------------
-- Parsers
-------------------------------------------------------------------------------
---@function parse_spec -- {{{
---@param type:       'weights' | 'variants' | 'widths' | 'styles'
---@param descriptor: weight | width | variant | style as given in db
-- @description Turns a descriptor into a LaTeX NFSS identifier; warns if unknown
local function parse_spec(type, descriptor)
  local spec = type[descriptor]
  if spec ~= nil then return spec 
  else
    texio.write_nl("Warning: " .. descriptor .. " not a known " .. type .. "!")
    return descriptor
  end
end
-- }}}

---@function parse_config(fam, config) {{{
---@description Returns a table of configs keyed by NFSS family name.
---@param   fam: base family name
---@config  config: table or string of configurations
local function parse_config(fam, config) 
  local configs = {}
  if not config then 
    configs[fam] = "mode=node;script=dflt;lang=dflt;+tlig;"
  elseif type(config) == "table" then
    if #config > 0 then
      -- indexed table --> multiple configs
      for _,instance in ipairs(config) do
        local cfgs = parse_config(fam, instance)
        for name,cfg in pairs(cfg) do
          configs[name] = cfg
        end
      end
    else
      -- keyed table --> single config
      local cfg = {}
      insert(cfg, "mode=" .. (config.mode or "node"))
      insert(cfg, "lang=" .. (config.lang or "dflt"))
      insert(cfg, "script=" .. (config.script or "dflt"))
      local fam = fam .. (config.suffix or "")
      if config.fea == nil then
        insert(cfg, "+tlig")
        if configs[fam] == nil then
          configs[fam] = concat(cfg, ";")
        else
          local n = 1
          while configs[fam .. n] do n = n + 1 end
          configs[fam .. n] = concat(cfg, ";")
        end
      else
        insert(cfg, config.fea)
        local pre, post, mid = "", "", ""
        for sign,subs in gmatch(config.fea, "([+-])(%a%a%a%a);") do
          if sign == "+" then
            if subs == "tnum" then pre = ""
            elseif subs == "pnum" then pre = "2"
            elseif subs == "lnum" then post = ""
            elseif subs == "onum" then post = "j"
            elseif subs == "smcp" then mid = "c"
            elseif subs == "sups" then pre = "1"
            end
          elseif subs == "pnum" and pre == "2" then pre = ""
          elseif subs == "onum" and post == "j" then post = ""
          elseif subs == "smcp" then mid = ""
          elseif subs == "sups" and pre == "1" then pre = ""
          end
        end
        local suff = pre .. mid .. post
        if suff ~= "" then suff = "-" .. suff end
        if configs[fam .. suff] ~= nil then
          local n = 1
          while configs[fam .. suff .. string.format("%c", n)] ~= nil do 
            n = n + 1 
          end
          suff = suff .. string.format("%c", n)
        end
        configs[fam .. suff] = concat(cfg, ";")
      end
    end
  else
    assert(type(config) == "string", 
      "Expected configuration to be table or string, but received " .. 
      type(config) .. " for " .. fam)
    local pre, post, suff = "", "", ""
    for sign,subs in gmatch(config, "([+-])(%a%a%a%a);") do
      if sign == "+" then
        if subs == "tnum" then pre = ""
        elseif subs == "pnum" then pre = "2"
        elseif subs == "lnum" then post = ""
        elseif subs == "onum" then post = "j"
        end
      elseif subs == "pnum" then pre = ""
      elseif subs == "onum" then post = ""
      end
      suff = pre .. post
      if suff ~= "" then suff = "-" .. suff end
    end
    if configs[fam .. suff] ~= nil then
      local n = 1
      while configs[fam .. suff .. string.format("%c", n)] ~= nil do 
        n = n + 1 
      end
      suff = suff .. string.format("%c", n)
    end
    configs[fam .. suff] = config
  end
  return configs
end
-- }}}

---@function prepare_fd(fam, fam_data, fea) {{{
---@description Returns a table of tables
---@description Each table uses fam[-suffix] containing lines 
---@description   suitable for writing to an .fd file
---@param fam       <string>  NFSS family
---@param fam_data  <table>   Sorted data for fonts
---@param config    <string> | <indexed table> | <keyed table> configs
---@param scale     <boolean>
---@status internal
-- Should be split??
local function prepare_fd(fam, fam_data, config, scale) 

  -- Useless?
  lfc_cache = lfc_cache or read_cache()
  lfc_cache.request = lfc_cache.request or {}
  lfc_cache.request[fam] = lfc_cache.request[fam] or {}
  local request = lfc_cache.request[fam]

  if scale == nil then scale = true end

  local configs = parse_config(fam, config)

  local fds = {}

  for fam_var,cfg in pairs(configs) do

    -- Pointless?
    lfc_cache[fam_var] = lfc_cache[fam_var] or {}
    request[cfg] = fam_var

    if lfc_cache[fam_var].config ~= nil and lfc_cache[fam_var].config == cfg and
      lfc_cache[fam_var].complete and lfc_cache[fam_var].fd then

      fds[fam_var] = lfc_cache[fam_var].fd
      goto fds_cont
    end

    local fd = {}
    lfc_cache[fam_var].complete = true

    local sscale = (scale and fam_var .. "@scale") or ""
    local ssscale = (scale and "\\" .. fam_var .. "@@scale") or ""
    

    local curr_line = 0
    local function fd_insert(s)
      curr_line = curr_line + 1
      insert(fd, s)
    end

    fd_insert("%% DO NOT EDIT THIS FILE IN PLACE\n%% Instead, rename or make a copy.\n%% Changes in-place will be overwritten without warning.\n\\ProvidesFile{tu" .. fam_var .. ".fd}[Font definitions for TU/" .. 
    fam_var .. "generated by lfc v0.0]")
    if scale then
      fd_insert("  \\expandafter\\ifx\\csname " .. sscale .. 
      "\\endcsname\\relax\n    \\let" .. ssscale .. "\\@empty\n  \\else\n    \\edef" ..
      ssscale .. "{*[\\csname " .. sscale .. "\\endcsname]}%\n  \\fi")
    end
    -- Not needed again & errors will be clearer
    sscale = nil

    fd_insert("\\DeclareFontFamily{TU}{" .. fam_var .. "}{}")

    local shape_begin = "\\DeclareFontShape{TU}{" .. fam_var .. "}{"
    local shape_mid   = "}{<-> " .. ssscale .. " \\UnicodeFontFile{\""

    for series,series_data in pairs(fam_data) do
      local std_line = 0
      for shape,fnts in pairs(series_data) do
        texio.write_nl("Processing font(s) for " .. series .. 
        " and " .. shape)

        assert(#fnts ~= 0, "The number of fonts should never be zero!")

        if #fnts == 1 then

          fd_insert(shape_begin .. series .. "}{" .. shape .. 
          shape_mid .. fnts[1].fullpath .. "\"}{" .. 
          cfg .. "}}{}")

        else

          table.sort(fnts, 
            function(a, b)
              if a.nfss_hash ~= b.nfss_hash then
                local amin = tonumber(a.minsize) or tonumber(a.designsize) 
                local bmin = tonumber(b.minsize) or tonumber(b.designsize) 
                if amin < bmin then return true 
                elseif bmin < amin then return false
                else
                  local amax = tonumber(a.maxsize) or tonumber(a.designsize)
                  local bmax = tonumber(b.maxsize) or tonumber(b.designsize)
                  if amax < bmax then return true end
                end
              end
              return false
            end)

          local hash_last = 0
          local ssubs = {}
          local max_last

          for shape_data,fnt in ipairs(fnts) do
            local min, max
            local opt_size = false
            local pre = ""
            if fnt.nfss_hash == hash_last then
              pre = "%% "
              texio.write_nl("Warning: duplicate fonts found: hash " .. 
                hash_last .. " for family " .. fam_var)
            end

            if shape_data == 1 then min = ""
            else
              min = fnt.minsize and fnt.minsize/10 or fnt.designsize 
                and fnt.designsize/10 or ""
            end
            if shape_data == #fnts then 
              max = ""
            else
              max = fnt.maxsize and fnt.maxsize/10 or fnt.designsize and 
                fnt.designsize/10 or ""
            end

            -- Needed to reinsert scaling if duplicate fonts
            if min ~= "" or max ~= "" then opt_size = true end

            insert(ssubs, pre .. "  <" .. min .. "-" .. max 
              .. "> \\UnicodeFontFile{\"" .. fnt.fullpath .. "\"}{" 
              .. cfg .. "}")

            max_last = max
            hash_last = fnt.nfss_hash
          end
          if scale then
            if opt_size then
              texio.write_nl("Warning: ignoring scaling for fonts with optical sizing.")
            else
              for idx,frag in ipairs(ssubs) do
                ssubs[idx] = (string.gsub(frag, "(\\UnicodeFontFile)", 
                  ssscale .. " %1"))
              end
            end
          end
          fd_insert(shape_begin .. series .. "}{" .. shape .. "}{\n" .. 
            concat(ssubs, "\n")
            .. "\n}{}")

        end
        if shape == "n" then std_line = curr_line end
      end

      -- Check for missing basic shapes
      if series_data.it == nil then
        if series_data.sl ~= nil then
          fd_insert(shape_begin .. series .. 
          "}{it}{<->ssub * " .. fam_var .. "/" .. series .. "/sl}{}")
        end
      elseif series_data.sl == nil then
        fd_insert(shape_begin .. series .. 
        "}{sl}{<->ssub * " .. fam_var .. "/" .. series .. "/it}{}")
      end

      if series_data.sc == nil and std_line > 0 then
        local line_no = curr_line + 1

        -- Temporary defn
        -- This will get replaced when the font is used:
        --    - if +smcp, replaced by appropriate spec
        --    - if not, replaced by blank line
        fd_insert(shape_begin .. series .. "}{sc}{<->sub * " .. fam_var .. 
          "/" .. series .. "/n}{}")

        lfc_cache[fam_var].complete = false
        lfc_cache[fam_var][line_no] = {
          line = (gsub(gsub(fd[std_line], "(\\UnicodeFontFile{[^}]*}{[^}]*)(})", 
            "%1;+smcp%2"), "{n}", "{sc}")),
        }
        lfc_cache.incomplete = lfc_cache.incomplete or {}
        lfc_cache.incomplete[fam_var] = lfc_cache.incomplete[fam_var] or {}
        lfc_cache.incomplete[fam_var][line_no] = true

        lfc_cache.callbacks = lfc_cache.callbacks or {}
        lfc_cache.callbacks[series_data.n[1].fullpath] = {
          fam = fam_var,
          [line_no] = lfc_cache[fam_var][line_no],
        }
        if #series_data.n > 1 then 
          local tmp = lfc_cache.callbacks[series_data.n[1].fullpath]
          tmp.related = { series_data.n[1].fullpath }
          for curr = 2, #series_data.n do
            lfc_cache.callbacks[series_data.n[curr].fullpath] = tmp
            insert(tmp.related, series_data.n[curr].fullpath)
          end
        end
      end

      if series_data.scit == nil then
        if series_data.scsl ~= nil then
          fd_insert(shape_begin .. series .. 
          "}{scit}{<->ssub * " .. fam_var .. "/" .. series .. "/scsl}{}")
          fd_insert(shape_begin .. series .. 
          "}{si}{<->ssub * " .. fam_var .. "/" .. series .. "/scit}{}")
        end
      elseif series_data.scsl == nil then
        fd_insert(shape_begin .. series .. 
        "}{scsl}{<->ssub * " .. fam_var .. "/" .. series .. "/scit}{}")
        fd_insert(shape_begin .. series .. 
        "}{si}{<->ssub * " .. fam_var .. "/" .. series .. "/scsl}{}")
      end

      -- No check for italic sc via +smcp, though could be added.
      -- Doubt this is worth the overhead, though.

      -- Other possibilities:
      --    - Auto-generate fds for different figure styles?
      --    - Swash/alternates?
      --    - How does this do with .ttc or variable fonts?

      -- It is (relatively) cheap to create additional families once the base
      --  case is done, if features can be inferred on loading.
      -- But I'm not sure how that would work for families, as opposed to 
      --  shapes?
    end

    -- Check for missing basic series
    if fam_data.b == nil then
      if fam_data.bx ~= nil then
        for shape,_ in pairs(fam_data.bx) do
          fd_insert(shape_begin .. "b}{" .. shape .. 
            "}{<->ssub * " .. fam_var .. "/bx/" .. shape .. "}{}")
        end
      end
    elseif fam_data.bx == nil then
      for shape,_ in pairs(fam_data.b) do
        fd_insert(shape_begin .. "bx}{" .. shape .. 
          "}{<->ssub * " .. fam_var .. "/b/" .. shape .. "}{}")
      end
    end

    lfc_cache[fam_var].fd = fd
    fds[fam_var] = fd

    :: fds_cont ::
  end

  return fds
end
-- }}}

-------------------------------------------------------------------------------
-- Manage font definition files, cache etc.
-------------------------------------------------------------------------------
---@function write_fd {{{
---@param fam:      NFSS family
---@param fd_lines: content
---@param fd_file:  filename or generated default
local function write_fd(fam, fd_lines, fd_file)
  assert(#fd_lines > 2, "I expected more than 2 lines!")
  fd_file = fd_file or io.open("tu" .. fam .. ".fd", "w")
  assert(fd_file ~= nil)
  -- concat doesn't guarantee order even for indexed tables
  for _,line in ipairs(fd_lines) do
    fd_file:write(line, "\n")
  end
  io.close(fd_file)
end
-- }}}

---@function add_callback -- {{{
---@description Adds code into the luaotfload.patch_font callback.
---@description This adjusts font definition files as fonts are loaded and data
---@description   becomes available to avoid pre-loading unnecessarily.
local function add_callback()
  texio.write_nl("[lfc] Adding callback.")
  luatexbase.add_to_callback(
    "luaotfload.patch_font",
    function(data, spec, id)
      local path = data.filename
      lfc_cache = lfc_cache or read_cache()

      if lfc_cache.callbacks and lfc_cache.callbacks[path] then

        texio.write_nl("[lfc] Processing callback ...")
        local fam = lfc_cache.callbacks[path].fam
        local incomplete = lfc_cache.incomplete 
        local fd 
        if lfc_cache[fam] and lfc_cache[fam].fd then fd = lfc_cache[fam].fd end

        for line_no,_ in pairs(lfc_cache.callbacks[path]) do
          if line_no == "fam" or line_no == "related" then goto not_line_ref end

          if incomplete and incomplete[fam] and incomplete[fam][line_no] then

            texio.write_nl("[lfc] Completing " .. fam .. "...")

            assert(fd and lfc_cache[fam][line_no] and lfc_cache[fam][line_no].line)
            local line = lfc_cache[fam][line_no].line

            if data.resources.features.gsub and data.resources.features.gsub.smcp then
              fd[line_no] = line
            else
              fd[line_no] = ""
            end
            lfc_cache[fam][line_no] = nil

            incomplete[fam][line_no] = nil
            if count(incomplete[fam]) == 0 then 
              incomplete[fam] = nil 
              lfc_cache[fam].complete = true
            end
          end

          lfc_cache.callbacks[path][line_no] = nil

          :: not_line_ref ::
        end
        
        local cnt = count(lfc_cache.callbacks[path])
        if cnt == 1 and lfc_cache.callbacks[path].fam then 
          lfc_cache.callbacks[path] = nil 
        -- Cannot rely on symlink-type effect here because refs get resoved 
        --    when saving to disk.
        -- How does the loader manage this?
        -- What I'd like is to save and restore a pointer to the array (or
        --    whatever a table is, which I still have no idea what it is).
        elseif cnt == 2 and lfc_cache.callbacks[path].fam and 
          lfc_cache.callbacks[path].related then
          for _,rel_path in ipairs(lfc_cache.callbacks[path].related) do
            lfc_cache.callbacks[rel_path] = nil
          end
          lfc_cache.callbacks[path] = nil
        end

        -- Honestly, the only reason to write the fds out at all is that
        --    I'm clueless about defining LaTeX fonts from Lua ...

        texio.write_nl("[lfc] Rewriting fd for " .. fam .. " ...")

        local fd_file = assert(io.open("tu" .. fam .. ".fd", "w"))
        fd_file:write(concat(fd, "\n"))
        fd_file:close()

        texio.write_nl("[lfc] Updating cache ...")
        write_cache(lfc_cache)

      end

    end,
    "lfc check for +smcp"
  )

end
--}}}

-------------------------------------------------------------------------------
-- Main configuration function
-------------------------------------------------------------------------------
---@function font_config -- {{{
---@param target required font specification to resolve
---@param config optional configuration details
---@description Main function: configures NFSS families on-the-fly, similar to
---@description   fontspec.
---@description Takes a font request and configuration, possibly writes one or 
---@description   more font definition files and returns table of data.
-- Should be broken up?!
local function font_config(targ, config)

  local callback_done = lfc_cache and lfc_cache.callbacks and true or false

  if targ == nil then return nil end

  targ = lower(targ)
  config = config or {}

  -- Not sure if this is useful or not
  -- Everything I construct ends up hopelessly muddled :(
  -- lfc_requests[targ] = lfc_requests[targ] or {}
  -- local request = lfc_requests[targ]
  -- insert(request, {config = config})

  local scale = config.scale
  
  local f = get_font_data(targ)

  if f == nil or f.metadata == nil then return nil end
  local metadata = f.metadata

  local fam_meta = metadata.fam_meta
  assert(fam_meta ~= nil)

  if metadata.fd_file then return f end

  local data = f.data
  if data == nil then return nil end

  local parsed_fam
  local parsed_fam_oldstyle

  local insert = table.insert
  local match = string.match
  local gsub = string.gsub

  local nfss_hashes = {}
  local regular = false
  local book = false
  local medium = false
  local maybe_not_scale = false

  -- Adjust returned data for compatibility with NFSS
  --    - Reduce width + weight -> series
  --    - Reduce style + variant -> shape
  for name,font in pairs(data) do
    local fullname = font.fullname
    
    -- We don't want to parse maths fonts.
    -- Best would be to check for the MATH table, but we don't want to
    --    load every font for that, so do this for now.
    if (match(fullname, "math")) then
      goto discard
    end

    local width = font.width
    local weight = font.weight
    local style = font.style
    local variant = font.variant
    -- family is more specific than familyname
    local family = font.familyname

    local series, shape

    -- not wise?
    -- if style == "italic" and ((match(name, "oblique")) or
    --   (match(name, "slanted"))) then
    --   style = "oblique"
    -- end

    if font.minsize ~= nil or font.maxsize ~= nil then
      maybe_not_scale = true
    end

    if fam_meta ~= family then

      family = (gsub(family, variant, ""))
      if not (match(fam_meta, "%d")) then
        family = (gsub(family, "%d", ""))
      end
      family = (gsub(family, style, ""))
      family = (gsub(family, weight, ""))
      family = (gsub(family, width, ""))

      if style == "oblique" or style == "slanted" then
        family = (gsub((gsub(family, "oblique", "")), "slanted", ""))
      end

      if variant == "smallcaps" then
        family = (gsub(family, "caps", ""))
      end

      -- For latin modern roman unslanted, which claims to be perfectly ‘normal’
      if (match(name, "unslanted")) then
        family = (gsub(family, "unslanted", ""))
        if (style == "normal" or style == "regular") and variant == "normal" then
          style = "uprightitalic"
        end
      end

      if weight == "normal" or weight == "regular" then
        if (match(fullname, "book")) then weight = "book"
          book = true
        elseif (match(fullname, "medium")) then weight = "medium"
          medium = true
        else regular = true end
      end

    end


    local t

    -- what is this for exactly?
    if variant ~= "oldstyle" then
      if parsed_fam == nil then parsed_fam = {} end
      t = parsed_fam
    else
      if parsed_fam_oldstyle == nil then parsed_fam_oldstyle = {} end
      t = parsed_fam_oldstyle
    end
    t[family] = t[family] or {}
    t = t[family]


    -- translate to NFSS identifiers (texdoc fntguide)
    local nfss_weight   = parse_spec(weights, weight)
    local nfss_width    = parse_spec(widths, width)
    local nfss_style    = parse_spec(styles, style)
    local nfss_variant  = parse_spec(variants, variant)

    if nfss_variant == "oldstyle" then nfss_variant = "n" end

    -- ‘m’ must not be combined, as of the 2020 changes, so ‘mb’ is
    --    not allowed
    if nfss_weight == "m" then
      series = nfss_width
    elseif nfss_width == "m" then
      series = nfss_weight
    else 
      series = nfss_weight .. nfss_width
    end

    -- Likewise ‘n’, but I never saw anybody combine this, so nothing broken
    if nfss_style == "n" then
      shape = nfss_variant
    elseif nfss_variant == "n" then
      shape = nfss_style
    else
      shape = nfss_variant .. nfss_style
    end

    -- Hash is <family>:<series>:<shape>[<minsize>:<maxsize>]
    local nfss_hash = family .. ":" .. series .. ":" .. shape 
      .. (font.minsize ~= nil and ":" .. font.minsize or "") 
      .. (font.maxsize ~= nil and ":" .. font.maxsize or "")

    font.series = series
    font.shape = shape
    font.nfss_hash = nfss_hash
    font.nfss_family = family
    
    nfss_hashes[family] = nfss_hashes[family] or {}
    nfss_hashes[family][nfss_hash] = nfss_hashes[family][nfss_hash] or 0
    nfss_hashes[family][nfss_hash] = nfss_hashes[family][nfss_hash] + 1

    t[series] = t[series] or {}
    t[series][shape] = t[series][shape] or {}

    insert(t[series][shape], font)

    :: discard ::

  end

  if parsed_fam == nil and parsed_fam_oldstyle == nil then 
    return nil 
  end

  -- ConTeXt's database treats distinct ‘oldstyle’ fonts as variants
  -- but this doesn't fit NFSS, so it needs to be a family
  -- I'm not sure what this is aimed at, so not sure if it should just
  --    be +j ??

  if parsed_fam_oldstyle ~= nil then
    if parsed_fam == nil then
      parsed_fam = parsed_fam_oldstyle
    else 
      for fam,i in pairs(parsed_fam_oldstyle) do
        if parsed_fam[fam] ~= nil then
          local hash_fam = fam .. "oldstyle"
          if parsed_fam[fam .. "oldstyle"] ~= nil then
            local n = 2
            while parsed_fam[fam .. "oldstyle" .. n] ~= nil do n = n + 1 end
            parsed_fam[fam .. "oldstyle" .. n] = i
            hash_fam = hash_fam .. n
          else
            parsed_fam[fam .. "oldstyle"] = i
          end
          for series,j in pairs(i) do
            for shape,fnts in pairs(j) do
              for _,fnt in ipairs(fnts) do
                fnt.nfss_hash = (string.gsub(fnt.nfss_hash, fam, hash_fam))
                fnt.nfss_family = (string.gsub(fnt.nfss_family, fam, hash_fam))
              end
            end
          end
        else
          parsed_fam[fam] = i
        end
      end
    end
    parsed_fam_oldstyle = nil
  end

  -- What to do about the common weights NFSS doesn't cover?
  -- e.g. ‘medium’ and ‘book’ often differ from both ‘regular’ and each other
  -- But treating them as distinct families still seems wrong.
  -- They should be installed as weights, but this is tricky as it breaks
  --  font selections unless additional change rules are provided.
  -- Normally these are made into different families, but then you must 
  --  either assign other weights arbitrarily to those families or duplicate
  --  entries in multiple fds & neither is really good to do on-the-fly.

  -- So what to do here?
  --    1) Use ‘book’ or ‘k’ or ‘medium’ or ‘med’ or whatever?
  --    2) Use ‘m’ and hope the fonts discarded as dupes are of-a-weight (not
  --      likely)?
  --    3) As (2) but discard all fonts with these weights if ‘regular’ is 
  --      available, presumably later?
  --    4) Create separate families?
  --    5) Error if a foundary is so inconveniently prolific?

  -- I can see the ‘m’ would have been sufficient in the past, though I used
  --  ‘mb’ before it got prohibited (and so did some core ‘.fd’ files).
  -- But now so many fonts distinguish these ...

  -- It would be so much nicer (and more efficient) if NFSS let this be done
  --  properly! But the chances of getting NFSS changed to speed compilation
  --  with a degenerate font package make Alpha Centauri seem a choice spot 
  --  for your local newsagent's.
  
  if not regular then
    if book then
      for fam,data in pairs(parsed_fam) do
        if data.book then
          assert(data.m == nil)
          data.m = data.book
          data.book = nil
        end
      end
      book = false
    elseif medium then
      for fam,data in pairs(parsed_fam) do
        if data.medium then
          assert(data.m == nil)
          data.m = data.medium
          data.medium = nil
        end
      end
      medium = false
    end
  end

  if book then
    for fam,data in pairs(parsed_fam) do
      if data.book ~= nil then
        local book_fam = fam .. "book"
        assert(parsed_fam[book_fam] == nil, 
          "I didn't expect so many books outside a library.")
        parsed_fam[book_fam] = {}
        parsed_fam[book_fam].m = data.book
        data.book = nil
        for series,i in pairs(data) do
          if series ~= "m" then 
            parsed_fam[book_fam][series] = i
          end
        end
      end
    end
  end

  if medium then
    for fam,data in pairs(parsed_fam) do
      if data.medium ~= nil then
        local medium_fam = fam .. "medium"
        assert(parsed_fam[medium_fam] == nil, 
          "I didn't expect so many mediums outside an art studio.")
        parsed_fam[medium_fam] = {}
        parsed_fam[medium_fam].m = data.medium
        data.medium = nil
        for series,i in pairs(data) do
          if series ~= "m" then 
            parsed_fam[medium_fam][series] = i
          end
        end
      end
    end
  end
        

  local scale = true

  -- Don't scale if optical sizes are present, but just checking for
  --  minsize/maxsize when parsing fails because font data's so poor.
  -- One would think that checking the range was greater than some min
  --  would be a good heuristic, but some fonts set minsize = maxsize
  --  even though there is only one font (e.g. TeX Gyre Pagella).

  if maybe_not_scale then
    for fam,fam_data in pairs(parsed_fam) do
      for series,i in pairs(fam_data) do
        for shape,fnts in pairs(i) do
          if #fnts > 1 then
            scale = false
            goto set_scale
          end
        end
      end
    end
  end

  :: set_scale ::

  for fam,fam_data in pairs(parsed_fam) do
    local fds = prepare_fd(fam, fam_data, config, scale)
    for fam_name,fd in pairs(fds) do
      write_fd(fam_name, fd) 
    end
  end

  if callback_done == false and lua_cache ~= nil and 
    lua_cache.callbacks ~= nil then add_callback() end

  for i,j in pairs(lfc_cache) do print("lfc_cache:",i,type(i),j,type(j)) end
  write_cache(lfc_cache)

  return f
end
-- }}}

-------------------------------------------------------------------------------
-- Forced for now
local cache_path = get_cache_path()
if lfs.isfile(cache_path) then
  lfc_cache = read_cache()
  if lfc_cache and lfc_cache.callbacks then add_callback() end
end
add_callback()
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- lfc.search_family = search_family
-- lfc.get_font_data = get_font_data
lfc.font_config = font_config
-- lfc.fonts = fonts
-- lfc.lfc_requests = lfc_requests
-- lfc.write_cache = write_cache
-- lfc.read_cache = read_cache
-- lfc.get_cache_path = get_cache_path
lfc.cache = lfc_cache
lfc.add_callback = add_callback

return lfc
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-- vim: et:foldmethod=marker:
