-- $Id: lfc.lua 12037 2026-09-14 07:00:19Z cfrees $
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- locals {{{
-- imports {{{
local is_writable = file.is_writable
local isdir, isfile, mkdir = lfs.isdir, lfs.isfile, lfs.mkdir
local md5sum = md5.sumhexa
-- string
local gsub, gmatch, match = string.gsub, string.gmatch, string.match
local format, lower = string.format, string.lower
-- table
local append, insert = table.append, table.insert
local copy, count, fastcopy = table.copy, table.count, table.fastcopy
local load, save, setmetatableindex = table.load, table.save, table.setmetatableindex
local concat, serialize = table.concat, table.serialize
local mirrored = table.mirrored
local sort = table.sort
-- tex | texio | token
local sprint = tex.sprint
local write_nl = texio.write_nl
local create = token.create
-- }}}

lfc = {} -- ours {{{
local lfc_cache
local lfc_debug = lfc_debug or true
local lfc_callback_smcp_active = false
local lfc_callback_data_active = false

local function enquote(str) return "\"" .. str .. "\"" end
local str_onesize = "<->"
local str_fea_default = "mode=node;language=dflt;script=dflt;+tlig"

local tok_declare_fam = create("DeclareFontFamily")
local tok_declare_shape = create("DeclareFontShape")
local tok_group_begin = create(123, 1)
local tok_group_end = create(125, 2)
local tok_uni_fontfile = create("UnicodeFontFile")

local seq_enc_tu = {tok_group_begin, "TU", tok_group_end}
local seq_empty_n = {tok_group_begin, tok_group_end}
local function seq_n(arg)
  return {tok_group_begin, arg, tok_group_end}
end

local function add_callback_data() end
-- }}}
-- }}}

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- logging fns {{{
local msg_level = {
  bug   = "Bug",
  debug = "Debug",
  err   = "Error",
  info  = "Info",
  log   = "Log",
  warn  = "Warning",
}
local function msg(text, level)
  level = level or "warn"
  if level == "debug" and not lfc_debug then return end
  if type(text) == "string" then
    write_nl("[lfc] " .. msg_level[level] .. ":\t" .. text .. "\n")
  else
    for _,txt in ipairs(text) do
      write_nl("[lfc] " .. msg_level[level] .. ":\t" .. txt .. "\n")
    end
  end
  if level == "bug" then
    write_nl("[lfc] Bug:\tPlease report to one of\n\
      [lfc] Bug:\t\thttps://www.codeberg.org/cfr/nfssext/issues\n\
      [lfc] Bug:\t\thttps://www.github.com/cfr42/nfssext/issues\n\
      [lfc] Bug:\tYou can get more information using\n\
      [lfc] Bug:\t\t\\usepackage[debug]{lua-font-config}\n")
    error(1)
  elseif level == "err" then
    write_nl("[lfc] Error:\t" .. text .. ".\n")
    error(2)
  end
end
local function msg_assert(cond, text, level) 
  if not cond then
    msg(text, level or "bug")
  end
end
if lfc_debug then
  function msg_assert(cond, text, level) assert(cond, text) end
end
-- }}}

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Max Chernoff: https://chat.stackexchange.com/transcript/message/69175678#69175678
-- Use ConTeXt's font name database code.
-------------------------------------------------------------------------------

---@mcsubstitute -- {{{

-- Define a new private environment into which to load "font-syn.lua".
local lfc_env = copy(luaotfload.fontloader)
lfc_env.table = copy(lfc_env.table)

-- Define some functions required by "font-syn.lua".
local split = "^(.-)([^/]-)([^/]-)$"

---@function lfc_env.resolvers.dowithfilesintree() -- {{{
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

---@function lfc_env.table.setmetatableindex() -- {{{
function lfc_env.table.setmetatableindex(t, k)
  if k == "self" then
    return setmetatableindex(t, function(tt, kk)
      tt[kk] = kk
      return kk
    end)
  else
    return setmetatableindex(t, k)
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
-- loadfile(kpse.find_file("font-syn.lua"), "t", lfc_env)()
loadfile("lfc-context-font-syn.lua", "t", lfc_env)()

-- Print a message while generating our font name database so that users
-- don't get confused by the long pause.
do
  local saved = lfc_env.fonts.names.identify
  function lfc_env.fonts.names.identify(force)
    write_nl("Generating font name database...")
    saved(force)
    write(" done.\n")
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
-- late locals {{{
local lfc_fonts = lfc_env.fonts
local names = lfc_fonts.names
local resolve = names.resolve
local lookup_font_file = names.lookup_font_file
local font_data = names.data
-- }}}
-------------------------------------------------------------------------------
-- Utilities for caching data
-------------------------------------------------------------------------------
---@function get_cache_path() -- {{{
---@description Returns fullname of module cache.
---@statue internal
local function get_cache_path()
  msg("Accessing cache ...", "debug")
  local path = (gsub(lfc_fonts.names.cache.writable, "^(.*/)[^/]+$", "%1" ))
  msg_assert(path ~= nil, "Cannot find place for cache!")
  if not isdir(path .. "/lfc") then
    msg_assert(is_writable(path), "Cache " .. path .. " not writable!")
    msg_assert(mkdir(path .. "/lfc"), "Cannot create cache " .. path .. 
      "/lfc" .. " directory!")
  end
  path = path .. "/lfc"
  return path .. "/" .. "lfc_cache.lua"
end
-- }}}

---@function read_cache()  -- {{{
---@param loc <string> Optional alternate full path for cache.
---@status internal
local function read_cache(loc)
  write_nl("[lfc] Reading cache ...")
  loc = loc or get_cache_path()
  local cache = isfile(loc) and load(loc) or {}
  if lfc_debug then 
    msg("Read cache state:\n", "debug")
    inspect(cache) 
  end
  return cache
end
-- }}}

---@function write_cache([stuff[, loc]] -- {{{
---@param stuff <table> Table to save. Default: lua_cache.
---@param loc <string>  Full path of cache. Default: from get_cache_path().
local function write_cache(stuff, loc)
  msg("Writing cache ...", "debug")
  stuff = stuff or lfc_cache
  if stuff == nil then return 1 end
  loc = loc or get_cache_path()
  -- Duplicates data referenced by pointers/links/whatever they are.
  save (loc, stuff)
  if lfc_debug then 
    msg("Saved cache state:\n", "debug")
    inspect(lfc_cache) 
  end
end
-- }}}
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
---@function hash_check(name, config) -- {{{
---@param name      <string>  Key e.g. name of (meta-)family or whatever
---@param config    <table>   Table of configuration data
---@description Returns hash and any matching cached data.
local function hash_check(name, config)

  if not name then return nil end
  config = config or {}

  local hash_key = md5sum(name .. serialize(config))

  if lfc_cache.meta_families and lfc_cache.meta_families.by_hash and
    lfc_cache.meta_families.by_hash[hash_key] then

    local cached = lfc_cache.meta_families.by_hash[hash_key]
  end

  return hash_key, cached or nil
end
-- }}}

---@function get_font_data -- {{{
---@param fnt     <string>  Font name/family/etc. to resolve.
---@param config  <table>   Only here used for hash 
---@param force   <boolean> Whether to force re-generation if .fd found.
-- @description Resolves a font specification and turns the family name into
-- @description    an .fd file name
-- @description If the file exists, records this and returns the metadata
-- @description If not, returns a table of font data, too
local function get_font_data(fnt, config, force)
  if fnt == nil then return nil end

  -- For return
  local f = {}

  -- Gets file name
  local ff = resolve(fnt)
  if ff == nil then return nil end

  ff = cleanfilename(ff)

  local ext = (gsub(ff, "^(.*)%.([^.]+)", "%2"))
  local basename = (gsub(ff, "([^/]*)%.([^.]+)", "%1"))
  if ext == nil or basename == nil then return nil end

  local fam_meta = font_data.mappings[ext][basename].familyname
  if fam_meta == nil then return nil end


  -- Return extension, family name and either fd file or font data.
  f.metadata  = {
    ext       = ext,
    fam_meta  = fam_meta,
  }
  local metadata = f.metadata

  local fd = "tu" .. fam_meta .. ".fd", "tex"
  metadata.fd = fd
  local fd_file = kpse.find_file(fd) 
  -- If an .fd for family exists, use unless force was used.
  if fd_file and not force then
    metadata.fd_file = fd_file
    return f
  end

  local hash_key, cached = hash_check(fam_meta, config)
  metadata.hash_key  = hash_key

  -- If a cached emulated .fd exists, we're done unless force was used.
  if cached and not force then
    metadata.cached = cached
    return f
  end

  -- If not, get font data for family

  -- Returns indexed list, limited coverage
  -- local data = font_data.families[fam_meta]

  -- Returns key-val list, wider coverage
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
  data_by_filename = mirrored(data_by_filename)

  -- Discard dupes -- ??????
  -- Data doesn't include full paths, so add these now.
  for name, fdata in pairs(data) do
    if data_by_filename[name] == nil then
      data[name] = nil
    elseif fdata.fullpath == nil then
      -- Gets full path from file name.
      fdata.fullpath = lookup_font_file(fdata.filename)
    end
  end

  f.data = data

  return f
end 
-- }}}

---@function resolve_one(fnt) {{{
---@param fnt <string>
---@description Returns full path if found; o/w nil.
local function resolve_one(fnt)
  if not fnt then return nil end
  fnt = resolve(fnt)
  msg_assert(fnt, "Invalid font specification: " .. fnt .. ".", "warn")
  return (fnt and lookup_font_file(fnt)) or nil
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
  -- oldstyle = "oldstyle",
  smallcaps = "sc",
} -- }}}

-------------------------------------------------------------------------------
-- Parsers
-------------------------------------------------------------------------------
---@function parse_spec -- {{{
---@param kind:       'weights' | 'variants' | 'widths' | 'styles'
---@param descriptor: weight | width | variant | style as given in db
-- @description Turns a descriptor into a LaTeX NFSS identifier; warns if unknown
local function parse_spec(kind, descriptor)
  local spec = kind[descriptor]
  if spec ~= nil then return spec 
  else
    msg(descriptor .. " not a valid value.")
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
  local auto = true
  if not config then 
    configs[fam] = str_fea_default
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
        local pre, post = "", ""
        -- Should use long suffixes here, but this is more convenient for now.
        for sign,subs in gmatch(config.fea, "([+-])(%a%a%a%a);") do
          if sign == "+" then
            if subs == "tnum" then pre = ""
            elseif subs == "pnum" then pre = "2"
            elseif subs == "lnum" then post = ""
            elseif subs == "onum" then post = "j"
            elseif subs == "subs" then pre = "0"
            elseif subs == "sups" then pre = "1"
            end
          elseif subs == "pnum" and pre == "2" then pre = ""
          elseif subs == "onum" and post == "j" then post = ""
          elseif subs == "subs" and pre == "0" then pre = ""
          elseif subs == "sups" and pre == "1" then pre = ""
          end
        end
        local suff = pre .. post
        if suff ~= "" then suff = "-" .. suff end
        if configs[fam .. suff] ~= nil then
          local n = 1
          while configs[fam .. suff .. format("%c", n)] ~= nil do 
            n = n + 1 
          end
          suff = suff .. format("%c", n)
        end
        configs[fam .. suff] = concat(cfg, ";")
      end
    end
  else
    msg_assert(type(config) == "string", 
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
      while configs[fam .. suff .. format("%c", n)] ~= nil do 
        n = n + 1 
      end
      suff = suff .. format("%c", n)
    end
    configs[fam .. suff] = config
  end
  return configs
end
-- }}}

---@function prepare_fake_fd(fam, fam_data, fea) {{{
---@description Returns a table of tables
---@description Each table uses fam[-suffix] containing lines 
---@description   suitable for emulating an .fd file
---@param fam       <string>  NFSS family
---@param fam_data  <table>   Sorted data for fonts
---@param config    <string> | <indexed table> | <keyed table> configs
---@param force     <boolean>
---@status internal
-- Should be split??
-- Cache format:
--  lfc_cache ->
--    callbacks_data = {
--      <fullpath>,
--      ...,
--    },
--    callbacks_smcp = {
--      <fullpath> = {
--        <line no.> = true,
--        ...,
--        fam = <nfss fam>,
--        rel = {<path>, ...},
--      },
--      ...,
--    },
--    incomplete = {
--      <nfss fam> = {
--        <line no.> = true,
--        ...,
--      },
--      ...,
--    },
--    meta_families = {
--      by_hash = {
--        <hash> = {<nfss fam>, ...},
--        ...,
--      },
--    },
--    resources = {
--      full path> = {
--        features = {
--          gsub = <data>,
--          gpos = <data>,
--        },
--      },
--    },
--    <nfss fam> = {
--      complete = <boolean>,
--      config = <feature string>,
--      fake_fd = {
--        {<series>, <shape>, <fullpath>, <cfg>} 
--        | {<series>, <shape>, {
--            <min>, <max>, <fullpath>
--          }, <cfg>}
--        | {<series>, <shape>, ssub = {<fam>, <series>, <shape>}}
--        | {<series>, <shape>, sub = {<fam>, <series>, <shape>}},
--        ...,
--      },
--      scalable = <boolean>,
--    }
local function prepare_fake_fd(fam, fam_data, config, force) 

  force = force or false

  lfc_cache = lfc_cache or read_cache()

  local configs = parse_config(fam, config)
  local fake_fds = {}

  for fam_var,cfg in pairs(configs) do

    lfc_cache[fam_var] = lfc_cache[fam_var] or {}

    -- Does config check make any sense?
    -- The problem is we can't use the hash yet ...
    if lfc_cache[fam_var].config ~= nil and lfc_cache[fam_var].config == config
      and lfc_cache[fam_var].fake_fd and not force then

      fake_fds[fam_var] = lfc_cache[fam_var].fake_fd
      goto fake_fds_cont
    end

    lfc_cache[fam_var].paths = lfc_cache[fam_var].paths or {}
    local path_list = lfc_cache[fam_var].paths

    lfc_cache.callbacks_data = lfc_cache.callbacks_data or {}
    local callbacks_data = lfc_cache.callbacks_data

    lfc_cache.resources = lfc_cache.resources or {}
    local resources = lfc_cache.resources

    local fake_fd = {}

    lfc_cache[fam_var].complete = true

    local scalable = true

    local curr_line = 0
    local function fake_fd_insert(s)
      curr_line = curr_line + 1
      insert(fake_fd, s)
    end
    local function add_path(p)
      insert(path_list, p)
      if not resources[p] then
        callbacks_data[p] = true
        if not lfc_callback_data_active then add_callback_data() end
      end
    end

    for series,series_data in pairs(fam_data) do
      local std_lines = {n = 0, it = 0, sl = 0}
      for shape,fnts in pairs(series_data) do
        msg("Processing font(s) for " .. series .. " and " .. shape, "debug")

        msg_assert(#fnts ~= 0, "The number of fonts should never be zero!")

        -- Add path to list for family and add callback if needed.
        for _,ff in ipairs(fnts) do add_path(ff.fullpath) end

        if #fnts == 1 then

          fake_fd_insert({series, shape, enquote(fnts[1].fullpath), cfg})

        else

          sort(fnts, 
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
          local max_max = 0
          local min_min
          local opt_size = false

          for shape_data,fnt in ipairs(fnts) do
            local min, max
            local pre = ""
            if fnt.nfss_hash == hash_last then
              pre = "%% "
              msg("Duplicate fonts found: hash " .. 
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

            if min == max then
              min = ""
              max = ""
            end

            -- Needed to reinsert scaling if duplicate fonts
            if min ~= "" or max ~= "" then opt_size = true end

            insert(ssubs, {"<" .. min .. "-" .. max .. ">", enquote(fnt.fullpath)})

            max_max = (max ~= "" and max > max_max) and max or max_max
            if min ~= "" then
              min_min = min_min or min
              min_min = min < min_min and min or min_min
            end
            hash_last = fnt.nfss_hash
          end

          if max_max == 0 or not min_min then opt_size = false
          elseif max_max == min_min then opt_size = false
          end

          if opt_size then
            fake_fd_insert({series, shape, fastcopy(ssubs), cfg})
            scalable = false
          else
            for _,i in ipairs(ssubs) do
              fake_fd_insert({series, shape, enquote(i[2]), cfg})
            end
            msg("Apparent duplicates for " .. fam .. "/" .. series ..
              "/" .. shape .. ".")
          end

        end
        if shape == "n" then std_lines.n = curr_line 
        elseif shape == "it" then std_lines.it = curr_line
        elseif shape == "sl" then std_lines.sl = curr_line
        end
      end

      -- Check for missing basic shapes
      if series_data.it == nil then
        if series_data.sl ~= nil then
          fake_fd_insert({series, "it", ssub = {fam_var, series, "sl"}})
        end
      elseif series_data.sl == nil then
        fake_fd_insert({series, "sl", ssub = {fam_var, series, "it"}})
      end

      local trans = { sc = "n", scit = "it", scsl = "sl" }
      for to_shape,base_shape in pairs(trans) do
        if series_data[to_shape] == nil and series_data[base_shape] then

          if not (std_lines[base_shape] > 0) then
            msg("No std_lines for " .. base_shape .. ".")
            goto trans_skip
          end

          local curr_path = series_data[base_shape][1].fullpath

          local checked = false

          if lfc_cache.resources and lfc_cache.resources[curr_path] then
            local rsc = lfc_cache.resources[curr_path]
            if rsc.features and rsc.features.gsub and rsc.features.gsub.smcp then
              checked = true
            else
              goto trans_skip
            end
          end

          local line_no = curr_line + 1

          -- Temporary defn
          -- This may get replaced when the font is used:
          --    - if +smcp, retain spec
          --    - if not, replaced by blank line
          -- This works better than an initial subs or blank and 
          --  _seems_ not to error???
          local line_mod = fastcopy(fake_fd[std_lines[base_shape]])
          line_mod[4] = line_mod[4] .. ";+smcp"
          line_mod[2] = to_shape
          fake_fd_insert(line_mod)

          if not checked then 
            lfc_cache[fam_var].complete = false

            lfc_cache.incomplete = lfc_cache.incomplete or {}
            lfc_cache.incomplete[fam_var] = lfc_cache.incomplete[fam_var] or {}
            lfc_cache.incomplete[fam_var][line_no] = true

            lfc_cache.callbacks_smcp = lfc_cache.callbacks_smcp or {}
            lfc_cache.callbacks_smcp[curr_path] = {
              fam = fam_var,
              [line_no] = true,
            }
            if #series_data[base_shape] > 1 then 
              local tmp = lfc_cache.callbacks_smcp[curr_path]
              tmp.related = { curr_path }
              for curr = 2, #series_data[base_shape] do
                lfc_cache.callbacks_smcp[curr_path] = tmp
                insert(tmp.related, curr_path)
              end
            end
          end
        end
        :: trans_skip ::
      end

      if series_data.scit == nil then
        if series_data.scsl ~= nil then
          fake_fd_insert({series, "scit", ssub = {fam_var, series, "scsl"}})
          fake_fd_insert({series, "si", ssub = {fam_var, series, "scit"}})
        end
      elseif series_data.scsl == nil then
        fake_fd_insert({series, "scsl", ssub = {fam_var, series, "scit"}})
        fake_fd_insert({series, "si", ssub = {fam_var, series, "scsl"}})
      else 
        fake_fd_insert({series, "si", ssub = {fam_var, series, "scit"}})
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
          fake_fd_insert({"b", shape, ssub = {fam_var, "bx", shape}})
        end
      end
    elseif fam_data.bx == nil then
      for shape,_ in pairs(fam_data.b) do
        fake_fd_insert({"bx", shape, ssub = {fam_var, "b", shape}})
      end
    end

    lfc_cache[fam_var].fake_fd = fake_fd
    lfc_cache[fam_var].scalable = scalable
    lfc_cache[fam_var].config = cfg
    fake_fds[fam_var] = fake_fd

    :: fake_fds_cont ::
  end

  return fake_fds
end
-- }}}
-------------------------------------------------------------------------------
-- Manage font definition files, cache etc.
-- get_toks()   write_declare_shape()   write_fake_fd()   add_callback_smcp()
-------------------------------------------------------------------------------
---@function get_toks(items) {{{
---@param items   <table> of [tables of] toks, strings
---@description   Returns sequence of toks, strings for sprint()
local function get_toks(items)
  local toks = {}
  for _,item in ipairs(items) do
    if item ~= "" then
      if type(item) == "userdata" or type(item) == "string" then 
        insert(toks, item)
      elseif type(item) == "table" then append(toks, get_toks(item))
      else msg_assert(false, "Unidentified Lua Object: "
        .. type(item) .. " (" .. item .. ")!")
      end
    end
  end
  return toks
end
-- }}}

---@function write_declare_shape(pre, line, post[, size_spec]) {{{
---@param pre       <table> of toks/strings e.g. \DeclareFontShape{<fam>}{<enc>}
---@param line      <table> rep. font spec  e.g. {<series>}, {<shape>}, ... 
---@param post      <table> of toks/strings e.g. {}
---@param size_spec <string> e.g. "<-5.0>" or "<->s*" etc.
---@Description Returns table of (tables of) toks/strings for a font shape
---@Description declaration. <line> may include ["sub"] or ["ssub"].
local function write_declare_shape(pre, line, post, size_spec) 

  msg_assert(pre and line and post, 
    "Partial or no spec to write. This should never happen!")

  size_spec = size_spec or str_onesize

  local out = {pre}

  -- series
  append(out, seq_n(line[1]))
  -- shape
  append(out, seq_n(line[2]))

  if line[3] then

    local kind = type(line[3])

    if kind == "string" then 

      append(out, { tok_group_begin, str_onesize, tok_uni_fontfile,
      seq_n(line[3]), seq_n(line[4]), tok_group_end })

    else 
      msg_assert(kind == "table", "Unexpected type " .. kind .. "!")

      insert(out, tok_group_begin)

      for _,item in ipairs(line[3]) do
        append(out, {item[1], tok_uni_fontfile, seq_n(item[2]), 
        seq_n(line[4]) })
      end

      insert(out, tok_group_end)
    end

  else

    msg_assert(line.sub or line.ssub, "Malformed line!")
    local subs = line.sub or line.ssub

    append(out, {
      tok_group_begin, str_onesize, line.ssub and "ssub*" or "sub*",
      subs[1] .. "/" .. subs[2] .. "/" .. subs[3], tok_group_end })

  end

  -- hyph or whatever
  insert(out, post)

  return out

end
-- }}}

---@function write_fake_fd(fam[, scale_factor]) {{{
---@param fam:            NFSS family
---@param scale_factor:   Scaling factor
---@param fake_fd:        If not cached
---@description fake_fd should be nil unless something has gone wrong.
---@description This should never happen in the automated case.
-- Cache format: see above
local function write_fake_fd(fam, scale_factor, fake_fd)
  msg("Emulating font definition file for NFSS family " .. fam .. ".")
  if scale_factor and not fake_fd and type(scale_factor) == "table" then
    fake_fd = scale_factor
    scale_factor = nil
  end
  if not fake_fd then
    msg_assert(lfc_cache[fam] and lfc_cache[fam].fake_fd and 
    type(lfc_cache[fam].fake_fd) == "table", "Cannot find definition for " ..
    fam .. "!")
    fake_fd = lfc_cache[fam].fake_fd
  end
  local pre = fastcopy(seq_enc_tu)
  append(pre, seq_n(fam))
  local out = {
    tok_declare_fam, fastcopy(pre), seq_empty_n
  }
  insert(pre, 1, tok_declare_shape)

  local onesize = str_onesize
  if scale_factor and scale_factor ~= 1 then
    if lfc_cache[fam].scalable then
      inspect(scale_factor)
      msg("Scaling " .. fam .. " to " .. scale_factor .. ".")
      onesize = onesize .. "s*[" .. scale_factor .. "]"
    else
      msg("Ignoring scaling factor for fonts with optical sizes.")
    end
  end

  for _,line in ipairs(fake_fd) do
    if line ~= "" then 
      append(out, write_declare_shape(pre, line, seq_empty_n, onesize))
    end
  end

  out = get_toks(out)
  sprint(-2,out)

end
-- }}}

---@function add_callback_smcp -- {{{
---@description Adds code into the luaotfload.patch_font callback.
---@description This adjusts font definition files as fonts are loaded and data
---@description   becomes available to avoid pre-loading unnecessarily.
local function add_callback_smcp()
  if lfc_callback_smcp_active then
    msg("Callback already active.", "debug")
  end
  msg("Adding callback.", "info")
  luatexbase.add_to_callback(
    "luaotfload.patch_font",
    function(data, spec, id)
      local path = data.filename
      lfc_cache = lfc_cache or read_cache()

      if lfc_cache.callbacks_smcp and lfc_cache.callbacks_smcp[path] then

        msg("Processing callback ...", "info")
        msg("Path:\t" .. path, "debug")
        msg("Spec:\t" .. spec, "debug")
        msg("Id:\t" .. id, "debug")
        local fam = lfc_cache.callbacks_smcp[path].fam
        local incomplete = lfc_cache.incomplete 
        -- local fd 
        local fake_fd 
        if lfc_cache[fam] and lfc_cache[fam].fake_fd then 
          fake_fd = lfc_cache[fam].fake_fd end

        for line_no,_ in pairs(lfc_cache.callbacks_smcp[path]) do
          if line_no == "fam" or line_no == "related" then goto not_line_ref end

          if incomplete and incomplete[fam] and incomplete[fam][line_no] then

            msg("Completing " .. fam .. "...", "log")

            msg_assert(fake_fd, "Data missing from cache!")
            msg("line:\t" .. line_no, "debug")

            if not data.resources.features.gsub or 
              not data.resources.features.gsub.smcp then
              fake_fd[line_no] = ""
              -- Warn because the usual LaTeX warning gets eaten.
              msg("Missing small-caps (italic/oblique/upright).")
            end
            msg("fake_fd[line_no]:\t" .. line_no .. ": " .. 
              (fake_fd[line_no] == "" and "" or serialize(fake_fd[line_no])), 
              "debug")

            -- tidy up incompletes list
            incomplete[fam][line_no] = nil
            if count(incomplete[fam]) == 0 then 
              incomplete[fam] = nil 
              lfc_cache[fam].complete = true
            end
          end

          lfc_cache.callbacks_smcp[path][line_no] = nil


          :: not_line_ref ::
        end
        
        -- tidy up callbacks
        local cnt = count(lfc_cache.callbacks_smcp[path])
        if cnt == 1 and lfc_cache.callbacks_smcp[path].fam then 
          lfc_cache.callbacks_smcp[path] = nil 
        -- Cannot rely on symlink-type effect here because refs get resolved 
        --    when saving to disk.
        -- How does the loader manage this?
        -- What I'd like is to save and restore a pointer to the array (or
        --    whatever a table is, which I still have no idea what it is).
        elseif cnt == 2 and lfc_cache.callbacks_smcp[path].fam and 
          lfc_cache.callbacks_smcp[path].related then
          for _,rel_path in ipairs(lfc_cache.callbacks_smcp[path].related) do
            lfc_cache.callbacks_smcp[rel_path] = nil
          end
          lfc_cache.callbacks_smcp[path] = nil
        end

        msg("Rewrote fd for " .. fam .. " ...", "log")
        if lfc_debug then inspect(fake_fd) end

        msg("Updating cache ...", "info")
        write_cache(lfc_cache)

      end

    end,
    "lfc check for +smcp"
  )
  lfc_callback_smcp_active = true

end
--}}}

---@function add_callback_data -- {{{
---@description Adds code into the luaotfload.patch_font callback.
---@description This just gathers data as fonts become available
---@description   to avoid pre-loading unnecessarily.
-- This was made local earlier so it could be used above.
-- Ref. https://stackoverflow.com/a/10272049/3186474 (but I do not want it in 
--  _G!
add_callback_data = function()
  if lfc_callback_data_active then
    msg("Callback already active.", "debug")
  end
  msg("Adding data callback.", "info")
  luatexbase.add_to_callback(
    "luaotfload.patch_font",
    function(data, spec, id)
      local path = data.filename
      lfc_cache = lfc_cache or read_cache()

      if lfc_cache.callbacks_data and lfc_cache.callbacks_data[path] then

        msg("Processing data callback ...", "info")
        msg("Path:\t" .. path, "debug")
        msg("Spec:\t" .. spec, "debug")
        msg("Id:\t" .. id, "debug")

        lfc_cache.resources = lfc_cache.resources or {}
        lfc_cache.resources[path] = lfc_cache.resources[path] or {}
        local cached = lfc_cache.resources[path]
        cached.features = cached.features or {}
        local fea = cached.features

        local rfea = data.resources.features
        
        fea.gsub = rfea.gsub and {} or nil
        if fea.gsub then
          fea.gsub.tnum = rfea.tnum and true or false
          fea.gsub.lnum = rfea.lnum and true or false
          fea.gsub.onum = rfea.onum and true or false
          fea.gsub.pnum = rfea.pnum and true or false
          fea.gsub.scmp = rfea.scmp and true or false
          fea.gsub.subs = rfea.subs and true or false
          fea.gsub.sups = rfea.sups and true or false
        else
          fea.gsub = false
        end

        -- tidy up callbacks
        lfc_cache.callbacks_data[path] = nil
        if count(lfc_cache.callbacks_data) == 0 then 
          lfc_cache.callbacks_data = nil 
        end

        msg("Cached resources for " .. path .. " ...", "log")
        if lfc_debug then inspect(lfc_cache.resources[path]) end

        msg("Updating cache ...", "info")
        write_cache(lfc_cache)

      end

    end,
    "lfc cache font resources"
  )
  lfc_callback_data_active = true

end
--}}}
-------------------------------------------------------------------------------
-- Main configuration function
-- font_config()
-------------------------------------------------------------------------------
---@function used_cached_fd(fam, scale) {{{
---@param fam   <string>  Name of a cached meta-family.
---@param scale <numeric> Potential scaling factor or nil.
local function use_cached_fd(fam, scale) 
  msg_assert(lfc_cache[fam] and lfc_cache[fam].fake_fd,
    "Cache failure. Try removing the cache before recompiling.")
  msg("Using cached fd emulation for " .. fam .. ".")

  if not lfc_callback_smcp_active and not lfc_cache[fam].complete then
    add_callback_smcp()
  end

  -- This is a sledge hammer for a glass spider.
  if not lfc_callback_data_active and lfc_cache.callbacks_data ~= nil then 
    msg("Enabling data callback", "debug")
    add_callback_data() 
  end

  return write_fake_fd(fam, lfc_cache[fam].scalable and scale or nil) 
end
-- }}}

---@function font_config -- {{{
---@param target required font specification to resolve
---@param config optional configuration details
---@description Main function: configures NFSS families on-the-fly, similar to
---@description   fontspec.
---@description Takes a font request and configuration, possibly writes one or 
---@description   more font definition files and returns table of data.
-- Should be broken up?!
local function font_config(targ, config)

  if targ == nil then return nil end

  lfc_cache = lfc_cache or read_cache()

  local callback_done = lfc_cache and lfc_cache.callbacks_smcp and true or false

  targ = lower(targ)
  config = config or {}

  local scale = config.scale
  
  local f = get_font_data(targ)

  if f == nil or f.metadata == nil then return nil end
  local metadata = f.metadata

  local fam_meta = metadata.fam_meta
  msg_assert(fam_meta ~= nil, "No reults for " .. targ)

  if metadata.fd_file then return f end

  local hash_key = metadata.hash_key
  if not metadata.cached then 

    local data = f.data
    if data == nil then return nil end

    local parsed_fam
    -- local parsed_fam_oldstyle

    local nfss_hashes = {}
    local regular = false
    local book = false
    local medium = false
    -- local maybe_not_scale = false

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

      -- if font.minsize ~= nil or font.maxsize ~= nil then
      --   maybe_not_scale = true
      -- end

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

      -- What is this for exactly?
      -- if variant ~= "oldstyle" then
        if parsed_fam == nil then parsed_fam = {} end
        t = parsed_fam
      -- else
      --   if parsed_fam_oldstyle == nil then parsed_fam_oldstyle = {} end
      --   t = parsed_fam_oldstyle
      -- end
      t[family] = t[family] or {}
      t = t[family]


      -- translate to NFSS identifiers (texdoc fntguide)
      local nfss_weight   = parse_spec(weights, weight)
      local nfss_width    = parse_spec(widths, width)
      local nfss_style    = parse_spec(styles, style)
      local nfss_variant  = parse_spec(variants, variant)

      -- Is this really needed and for what?
      -- if nfss_variant == "oldstyle" then nfss_variant = "n" end

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

    if parsed_fam == nil then --and parsed_fam_oldstyle == nil then 
      return nil 
    end

    -- ConTeXt's database treats distinct ‘oldstyle’ fonts as variants
    -- but this doesn't fit NFSS, so it needs to be a family
    -- I'm not sure what this is aimed at, so not sure if it should just
    --    be +j ??

    -- if parsed_fam_oldstyle ~= nil then
    --   if parsed_fam == nil then
    --     parsed_fam = parsed_fam_oldstyle
    --   else 
    --     for fam,i in pairs(parsed_fam_oldstyle) do
    --       if parsed_fam[fam] ~= nil then
    --         local hash_fam = fam .. "oldstyle"
    --         if parsed_fam[fam .. "oldstyle"] ~= nil then
    --           local n = 2
    --           while parsed_fam[fam .. "oldstyle" .. n] ~= nil do n = n + 1 end
    --           parsed_fam[fam .. "oldstyle" .. n] = i
    --           hash_fam = hash_fam .. n
    --         else
    --           parsed_fam[fam .. "oldstyle"] = i
    --         end
    --         for series,j in pairs(i) do
    --           for shape,fnts in pairs(j) do
    --             for _,fnt in ipairs(fnts) do
    --               fnt.nfss_hash = (gsub(fnt.nfss_hash, fam, hash_fam))
    --               fnt.nfss_family = (gsub(fnt.nfss_family, fam, hash_fam))
    --             end
    --           end
    --         end
    --       else
    --         parsed_fam[fam] = i
    --       end
    --     end
    --   end
    --   parsed_fam_oldstyle = nil
    -- end

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
          msg_assert(parsed_fam[book_fam] == nil, 
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
          msg_assert(parsed_fam[medium_fam] == nil, 
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
          

    -- local scale = true

    -- Don't scale if optical sizes are present, but just checking for
    --  minsize/maxsize when parsing fails because font data's so poor.
    -- One would think that checking the range was greater than some min
    --  would be a good heuristic, but some fonts set minsize = maxsize
    --  even though there is only one font (e.g. TeX Gyre Pagella).

    -- if maybe_not_scale then
    --   for fam,fam_data in pairs(parsed_fam) do
    --     for series,i in pairs(fam_data) do
    --       for shape,fnts in pairs(i) do
    --         if #fnts > 1 then
    --           scale = false
    --           goto set_scale
    --         end
    --       end
    --     end
    --   end
    -- end
    --
    -- :: set_scale ::

    lfc_cache.meta_families = lfc_cache.meta_families or {}
    lfc_cache.meta_families.by_hash = lfc_cache.meta_families.by_hash or {}
    lfc_cache.meta_families.by_hash[hash_key] = {}
    local by_hash = lfc_cache.meta_families.by_hash[hash_key] 

    for fam,fam_data in pairs(parsed_fam) do
      local fake_fds = prepare_fake_fd(fam, fam_data, config)
      for fam_name,fake_fd in pairs(fake_fds) do
        insert(by_hash, fam_name)
        local scale = config[fam_name] and config[fam_name].scale and 
          config[fam_name].scale or (config.scale and config.scale or nil)
        write_fake_fd(fam_name, scale) 
      end
    end

    write_cache(lfc_cache)

    -- Sledge hammer and fairy lights.
    if lfc_callback_smcp_active == false and lfc_cache.callbacks_smcp ~= nil then 
      msg("Enabling callback", "debug")
      add_callback_smcp() 
    end

  else

    for _,fam_name in ipairs(lfc_cache.meta_families.by_hash[hash_key]) do
      local scale = config[fam_name] and config[fam_name].scale and 
        config[fam_name].scale or (config.scale and config.scale or nil)
      use_cached_fd(fam_name, scale) 
    end

  end


  return f
end
-- }}}


---@function fast_font_config(fam, config) {{{
---@param fam     <string>  Suitable for NFSS family name.
---@param config  <table>   Configuration.
---@param force   <boolean> Whether to force regeneration.
local function fast_font_config(fam, config, force) 

  force = force or false

  msg_assert(fam, "Expected at least one argument, but found none!", "err")

  if type(fam) == "table" then

    local configs, force = fam, force or config or nil
    for _,cfg in ipairs(configs) do
      for fam,config in pairs(cfg) do
        fast_font_config(fam, config, force)
      end
    end

  else

    -- We should have a family name, configuration table [and force or not].

    -- Errors
    msg_assert(type(fam) == "string", "Expected family name to be a string, \z
      but found " .. type(fam) .. "!", "err")
    msg_assert(config and type(config) == "table", "Expected configuration table, \z
      but found " .. (config and type(config) or "nothing") .. "!", "err")

    fam = cleanfilename(fam)

    -- Get hash and check for cached data.
    local hash_key, cached = hash_check(fam, config)

    -- If fd is cached, use unless force.
    if cached and not force then
      use_cached_fd(fam, config.scale or nil)
    end

    local scalable = true
    local paths = {}
    local do_not_cache = false

    local function get_spec(wght, wd, var, stl)
      local weight, width, variant, style =
        parse_spec(weights, wght),
        parse_spec(widths, wd),
        parse_spec(variants, var),
        parse_spec(styles, stl)
      return weight == "m" and width or (width == "m" and weight or weight .. width),
        variant == "n" and style or (style == "n" and variant or variant .. style)
    end

    -- Config should consist of indexed tables, one for each shape declaration,
    --  with possibly some keyed values in the mix.
    for i,cfg in ipairs(config) do

      -- Error if there's no font spec to resolve.
      msg_assert((cfg.font and type(cfg.font) == "string") or
        (cfg.fonts and type(cfg.fonts) == "table") or cfg.sub or cfg.ssub,
        "Invalid or missing font specification!", "err")

      local weight, width, variant, style = cfg.weight or "medium", cfg.width 
        or "medium", 
        (cfg.sc or cfg.smallcaps) and "sc" or "normal", 
        cfg.shape or "normal"

      cfg.series, cfg.shape = get_spec(weight, width, variant, style)


      -- Resolves the actual font requests
      if not cfg.sub and not cfg.ssub then
        cfg.fea = cfg.fea or cfg.features or str_fea_default
        if cfg.font then
          cfg.font = resolve_one(cfg.font)
          if not cfg.font then
            config[i] = ""
            do_not_cache = true
            goto invalid_font_request
          end
          insert(paths, cfg.font)
        else
          scalable = false
          for j,frag in ipairs(cfg.fonts) do
            if not (frag.min or frag.max) or not (frag.font and 
              type(frag.font) == "string") then
              msg("Invalid font specification: <" .. (frag.min or "0") .. "-" ..
                (frag.max or "0") .. ">" .. (frag.font and tostring(frag.font) 
                or "\"\"") .. "!")
              config[i] = ""
              do_not_cache = true
              goto invalid_font_request
            end
            local min = frag.min or ""
            local max = frag.max or ""
            local font = resolve_one(frag.font)
            if not font then
              config[i] = ""
              do_not_cache = true
              goto invalid_font_request
            end
            cfg.fonts[j] = {min, max, frag.font}
            insert(paths, frag.font)
            if not lfc_cache.resources or not lfc_cache.resources[frag.font] 
              then
                lfc_cache.callbacks_data = lfc_cache.callbacks_data or {}
                lfc_cache.callbacks_data[frag.font] = true
                if not lfc_callback_data_active then add_callback_data() end
            end
          end
        end
      end

      config[i] = {cfg.series, cfg.shape, cfg.font or cfg.fonts or cfg.sub or 
        cfg.ssub, cfg.fea or nil}

      :: invalid_font_request ::

    end

    -- Cache only if no error occurred in processing.
    if not do_not_cache then
      lfc_cache = lfc_cache or read_cache()
      if lfc_cache[fam] then
        lfc_cache[fam].fake_fd = config
        lfc_cache[fam].scalable = scalable
        lfc_cache[fam].complete = true
        lfc_cache[fam].config = serialize(config)
        lfc_cache[fam].paths = paths
      else 
        lfc_cache[fam] = {
          fake_fd = config,
          scalable = scalable,
          complete = true,
          config = serialize(config),
          paths = paths
        }
      end
    end

    -- Try to create a family even after erroneous user input.
    write_fake_fd(fam, scalable and config.scale or nil or nil, config)

  end
end
-- }}}

-------------------------------------------------------------------------------
-- Setup on load
-------------------------------------------------------------------------------
-- {{{
-- Forced for now
-- Probably the callback should only be added when a family is defined.
-- For now, this loads regardless of what the font uses.
local cache_path = get_cache_path()
if isfile(cache_path) then
  lfc_cache = read_cache()
  if lfc_cache then
    if lfc_cache.callbacks_smcp then 
      msg("Activating callback", "debug")
      add_callback_smcp() 
    end
    if lfc_cache.callbacks_data then 
      msg("Activating callback", "debug")
      add_callback_data() 
    end
  end
end
-- }}}
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Public exports
-- Probably get_cache_path should be exposed, at least.
-------------------------------------------------------------------------------
-- lfc.get_font_data = get_font_data
lfc.font_config = font_config
lfc.fast_font_config = fast_font_config
-- lfc.fonts = fonts
-- lfc.write_cache = write_cache
-- lfc.read_cache = read_cache
-- lfc.get_cache_path = get_cache_path
-- lfc.add_callback_smcp = add_callback_smcp


return lfc
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-- vim: et:foldmethod=marker:
