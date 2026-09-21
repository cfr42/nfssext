-- $Id: lfc.lua 12057 2026-09-21 07:53:34Z cfrees $
-------------------------------------------------------------------------------
-- TODO
--
-- Code should be cleaned up - I cannot need 2,000 lines to load a font!
--
-- Config parsing looks horrible.
--
-- There's almost no user interface.
--
-- There's some disconnect between the data I'm using and the data luaotfload
--    uses, even though they are the same data.
--      - I guess luaotfload doesn't recognise cleanfilename() returns.
--
-- The code is too long, too complex, too clunky and too simplistic.
--    (Yes, of course, it can be both.)
--
-- Cached data should depend on db/fnt versions.
--    - Or is this automatic?
--
-- Loading the ConTeXt file differently?
--
-- Use suffix or something to distinguish families by features?
-- Or some other way to deal with this?
-- 
-- Information for user.
--
-- Some (any) user interface.
--
-- Way to define individual font commands.
--
-- Cope with symbol fonts? Not sure is that really needed?
--
-- Too slow?
--
-- ** Modify database creation to avoid sorting the data twice? **
--
-------------------------------------------------------------------------------
-- Cache format:
-------------------------------------------------------------------------------
--  lfc_cache ->  {{{
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
--      by_meta_fam = {
--        <meta-family> = {<nfss fam>, ...},
--        ...,
--      },
--    },
--    resources = {
--      <full path> = {
--        features = {
--          gsub = {
--            lnum = true | false,
--            onum = true | false,
--            pnum = true | false,
--            smcp = true | false,
--            subs = true | false,
--            sups = true | false,
--            tnum = true | false,
--          },
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
--      paths = <table of paths to font files>,
--      scalable = true | false,
--    }
--  }}}
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- locals {{{

-- imports {{{
local is_writable           = file.is_writable
local isdir, isfile, mkdir  = lfs.isdir, lfs.isfile, lfs.mkdir
local get_functions_table   = lua.get_functions_table
local new_lua_function      = luatexbase.new_luafunction
-- string
local gsub, gmatch, match       = string.gsub, string.gmatch, string.match
local find, format, lower       = string.find, string.format, string.lower
-- table
local append, hashed, insert    = table.append, table.hashed, table.insert
local copy, count, fastcopy     = table.copy, table.count, table.fastcopy
local load, mirrored, sort      = table.load, table.mirrored, table.sort
local save, setmetatableindex   = table.save, table.setmetatableindex
local concat, serialize, unique = table.concat, table.serialize, table.unique
-- tex | texio | token
local sprint                  = tex.sprint
local write_nl                = texio.write_nl
-- Max Chernoff: ‘The Lua function token.scan_argument accepts a boolean argument (token.scan_argument(true) or token.scan_argument(false)) which determines whether to expand the TeX string argument’ (https://chat.stackexchange.com/transcript/message/69210787#69210787)
local create, param, set_lua  = token.create, token.scan_argument, token.set_lua
-- }}}

lfc = {} -- ours {{{

local lfc_cache

-- Booleans
local lfc_debug                 = lfc.debug or true
local lfc_callback_smcp_active  = false
local lfc_callback_data_active  = false
local lfc_callback_cache_active = false

-- Strings
local function enquote(str) return "\"" .. str .. "\"" end

local lfc_log_level         = lfc.log_level or (lfc_debug and "debug" or "info")

local str_onesize           = "<->"
local str_fea_default       = "mode=node;language=dflt;script=dflt;+tlig"

local function hook_file_before(filename) 
  return {"file/", filename, "/before"} end

-- Single tokens
local tok_group_begin       = create(123, 1)
local tok_group_end         = create(125, 2)
local tok_declare_fam       = create("DeclareFontFamily")
local tok_declare_shape     = create("DeclareFontShape")
local tok_fontfamily        = create("fontfamily")
local tok_selectfont        = create("selectfont")
local tok_renewcommand      = create("renewcommand")
local tok_rmdefault         = create("rmdefault")
local tok_sfdefault         = create("sfdefault")
local tok_ttdefault         = create("ttdefault")

local tok_file_subs         = create("declare@file@substitution")
local tok_hook_gput_code    = create("hook_gput_code:nnn")

-- Tables
local nfss_default_families = {}
local nfss_doc_families     = {}

-- Token lists
local toks_empty_n          = {tok_group_begin, tok_group_end}
local function embrace(arg) return {tok_group_begin, arg, tok_group_end} end
local toks_enc_tu          = embrace("TU")
local toks_file_empty      = embrace(".tex")
local toks_dot             = embrace(".")

---@function luafunction_to_cs(csname, fn, tex_global, protected) -- {{{
---@param csname      <string>    Macro to set/create.
---@param fn          <function>  Lua function.
---@param tex_global  <boolean>   Whether to create global macro.
---@param protected   <boolean>   Whether to create protected macro.
---@description Registers the Lua function fn in the table of functions and 
---@description   creates the macro \csname with the specified properties.
---@description tex_global, protected are optional, default to false. 
-- See exp-lua-fns.tex for example, explanation etc.
-- Simplification: Udi Fogiel:
--    https://chat.stackexchange.com/transcript/message/69209032#69209032
local function luafunction_to_cs(csname, fn, ...)

  local t = get_functions_table()

  local n = new_lua_function(csname)

  t[n] = fn

  set_lua(csname, n, ...)
end
-- }}}

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
local msg_log_levels = {
  "bug",
  "err",
  "warn",
  "info",
  "log",
  "debug",
}
msg_log_levels = hashed(msg_log_levels)
local msg_cfg = lfc.msg_cfg or {}
local function msg(text, level)
  level = level or "warn"
  level_n = msg_log_levels[level] or msg_log_levels.debug
  if level_n > msg_log_levels[lfc_log_level] then return end
  if type(text) == "string" then
    write_nl(concat({"[lfc] ", msg_level[level], ":\t", text, "\n"}, ""))
  else
    write_nl(concat({"[lfc] ", msg_level[level], ":\t", concat(text, ""), "\n"},
      ""))
  end
  if level == "bug" then
    write_nl("[lfc] Bug:\tPlease report to one of\n\
      [lfc] Bug:\t\thttps://www.codeberg.org/cfr/nfssext/issues\n\
      [lfc] Bug:\t\thttps://www.github.com/cfr42/nfssext/issues\n\
      [lfc] Bug:\tYou can get more information using\n\
      [lfc] Bug:\t\t\\usepackage[debug]{lua-font-config}\n")
    error(1)
  elseif level == "err" then
    error(2)
  end
end
local function msg_assert(cond, text, level) 
  if not cond then
    msg(text, level or "bug")
  end
end
local function msg_debug(...) end
if lfc_debug then
  function msg_assert(cond, text, level) assert(cond, (type(text) == "string" 
    and text) or concat(text)) end
  msg_cfg.debug = msg_cfg.debug or {
    cache     = true,
    callback  = true,
    defn      = true,
    doc       = true,
  }
  function msg_debug(m, cat, ...)
    if cat and not msg_cfg.debug[cat] then 
      msg({"Skipped debug ", cat}, "debug") 
      return 
    end
    cat = cat or "generic"
    msg({"[", cat, "] ", m}, "debug")
    local vargs = {...} -- Aaaarrrggghhh!!
    for _,i in ipairs(vargs) do inspect(i) end
  end
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
    msg_assert(is_writable(path), {"Cache ", path, " not writable!"})
    msg_assert(mkdir(path .. "/lfc"), {"Cannot create cache ", path, 
    "/lfc", " directory!"})
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
  msg_debug("Read cache state:\n", "cache", cache)
  return cache
end
-- }}}

---@function write_cache() -- {{{
local function write_cache()
  msg("Writing cache ...", "debug")
  if lfc_cache then
    local loc = get_cache_path()
    -- Duplicates data referenced by pointers/links/whatever they are.
    save (loc, lfc_cache)
    msg_debug("Saved cache state:\n", "cache", lfc_cache)
  end
end
-- }}}

-------------------------------------------------------------------------------
-- Lookup utilities
-------------------------------------------------------------------------------
---@function get_font_data(targ[, force]) -- {{{
---@param fnt     <string>  Font name/family/etc. to resolve.
---@param force   <boolean> Whether to force re-generation if .fd found.
-- @description Resolves a font specification and turns the family name into
-- @description    an .fd file name
-- @description If the file exists, records this and returns the metadata
-- @description If not, returns a table of font data, too
local function get_font_data(fnt, force)
  if fnt == nil then return nil end

  -- For return
  local f = {
    metadata = {}
  }
  local fam_meta

  -- Check for exact family match.
  local ff = font_data.families[fnt]

  if ff then

    -- We don't use the data, as it isn't very good.
    -- But we can bypass the longer search by filename/partial match.
    fam_meta = fnt

  else

    -- Gets file name.
    -- Should this be before or after the search below?
    --    - Which is fastest? Guessing this one ...
    ff = resolve(fnt)

    if ff then 
      -- We still have to get the family, but this should already be 
      --    in the data.
      ff = cleanfilename(ff)

      local ext = (gsub(ff, "^(.*)%.([^.]+)", "%2"))
      local basename = (gsub(ff, "([^/]*)%.([^.]+)", "%1"))

      if ext and basename then
        fam_meta = font_data.mappings[ext][basename].familyname
        f.metadata.ext = ext
      end
    end

    -- If we still have no match ...
    if not fam_meta then
      -- Iterate through the known families, checking if the name begins
      --    with the target i.e. search for '^${fnt}', ignoring any tail.
      for _,i in ipairs(font_data.sorted_families) do
        if find(i, "^" .. fnt) then 
          -- This should be the shortest match, which is hopefully 
          --    a reasonable guess.
          fam_meta = i[1].familyname
          break
        end
      end
    end
  end


  -- If we still find nothing, rhodd y ffidl yn y tor ...
  if not fam_meta then return nil end

  f.metadata.fam_meta = fam_meta


  -- Return extension (if known), family name and either fd file or font data.

  local metadata = f.metadata

  local fd = concat({"tu", fam_meta, ".fd"}, "")
  metadata.fd = fd
  local fd_file = kpse.find_file(fd, "tex") 
  -- If an .fd for family exists, use unless force was used.
  if fd_file and not force then
    metadata.fd_file = fd_file
    return f
  end

  -- We prefer cached even if we have data, as cached will be processed.
  local cached
  if lfc_cache.meta_families and lfc_cache.meta_families.by_meta_fam then
    if not force then
      cached = lfc_cache.meta_families.by_meta_fam[fam_meta]
    else
      lfc_cache.meta_families.by_meta_fam[fam_meta] = nil
    end
  end
  metadata.hash_key  = fam_meta

  -- If a cached emulated .fd exists, we're done unless force was used.
  if cached then
    metadata.cached = cached
    return f
  end

  -- If not, get font data for family.

  -- Returns indexed list, limited coverage.
  -- local data = font_data.families[fam_meta]

  -- Returns key-val list, wider coverage.
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
---@description This was written for the custom config function.
---@description That has gone, but this should probably get a different
---@description   interface to allow single lookups.
local function resolve_one(fnt)
  if not fnt then return nil end
  fnt = resolve(fnt)
  msg_assert(fnt, {"Invalid font specification: ", fnt, "."}, "warn")
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
    msg({descriptor, " not a valid value."})
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
        config.fea = (gsubs(gsubs(config.fea, "(%a%a%a%a)%s*=%s*true", "+%1"),
          "(%a%a%a%a)%s*=%s*false", "-%1"))
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
      {"Expected configuration to be table or string, but received ", 
      type(config), " for ", fam})
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
local function prepare_fake_fd(fam, fam_data, force) 
  force = force or false

  lfc_cache = lfc_cache or read_cache()

  lfc_cache[fam] = lfc_cache[fam] or {}

  if lfc_cache[fam].fake_fd and not force then

    return lfc_cache[fam].fake_fd
  end

  lfc_cache[fam].paths = lfc_cache[fam].paths or {}
  local path_list = lfc_cache[fam].paths

  lfc_cache.callbacks_data = lfc_cache.callbacks_data or {}
  local callbacks_data = lfc_cache.callbacks_data

  lfc_cache.resources = lfc_cache.resources or {}
  local resources = lfc_cache.resources

  local fake_fd = {}

  lfc_cache[fam].complete = true

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
    end
  end

  for series,series_data in pairs(fam_data) do
    local std_lines = {n = 0, it = 0, sl = 0}
    for shape,fnts in pairs(series_data) do
      msg({"Processing font(s) for ", series, " and ", shape}, "debug")

      msg_assert(#fnts ~= 0, "The number of fonts should never be zero!")

      -- Add path to list for family and add callback if needed.
      for _,ff in ipairs(fnts) do add_path(ff.fullpath) end

      if #fnts == 1 then

        -- Need an empty entry for cfg mods e.g. +smcp; etc.
        fake_fd_insert({series, shape, enquote(fnts[1].fullpath), ""})

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
            msg({"Duplicate fonts found: hash ", 
            hash_last, " for family ", fam})
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
          -- We need an empty cfg at the end to hold transformations
          -- such as smcp.
          fake_fd_insert({series, shape, fastcopy(ssubs), ""})
          scalable = false
        else
          for _,i in ipairs(ssubs) do
            -- Need empty placeholder for cfg.
            fake_fd_insert({series, shape, enquote(i[2]), ""})
          end
          msg({"Apparent duplicates for ", fam, "/", series,
          "/", shape, "."})
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
        fake_fd_insert({series, "it", ssub = {fam, series, "sl"}})
      end
    elseif series_data.sl == nil then
      fake_fd_insert({series, "sl", ssub = {fam, series, "it"}})
    end

    local trans = { sc = "n", scit = "it", scsl = "sl" }
    for to_shape,base_shape in pairs(trans) do
      if series_data[to_shape] == nil and series_data[base_shape] then

        if not (std_lines[base_shape] > 0) then
          msg({"No std_lines for ", base_shape, "."})
          goto trans_skip
        end

        local curr_path = series_data[base_shape][1].fullpath

        local checked_and_smcp = false

        if lfc_cache.resources and lfc_cache.resources[curr_path] then
          local rsc = lfc_cache.resources[curr_path]
          if rsc.features and rsc.features.gsub and rsc.features.gsub.smcp then
            checked_and_smcp = true
          else
            -- We've checked and it doesn't have smcp, so skip the rest.
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
        line_mod[4] = "+smcp"
        line_mod[2] = to_shape
        fake_fd_insert(line_mod)

        -- We haven't checked, so the addition may be wrong.
        if not checked_and_smcp then 
          lfc_cache[fam].complete = false

          lfc_cache.incomplete = lfc_cache.incomplete or {}
          lfc_cache.incomplete[fam] = lfc_cache.incomplete[fam] or {}
          lfc_cache.incomplete[fam][line_no] = true

          lfc_cache.callbacks_smcp = lfc_cache.callbacks_smcp or {}
          lfc_cache.callbacks_smcp[curr_path] = {
            fam = fam,
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
        fake_fd_insert({series, "scit", ssub = {fam, series, "scsl"}})
        fake_fd_insert({series, "si", ssub = {fam, series, "scit"}})
      end
    elseif series_data.scsl == nil then
      fake_fd_insert({series, "scsl", ssub = {fam, series, "scit"}})
      fake_fd_insert({series, "si", ssub = {fam, series, "scsl"}})
    else 
      fake_fd_insert({series, "si", ssub = {fam, series, "scit"}})
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

  lfc_cache[fam].paths = unique(path_list)

  -- Check for missing basic series
  if fam_data.b == nil then
    if fam_data.bx ~= nil then
      for shape,_ in pairs(fam_data.bx) do
        fake_fd_insert({"b", shape, ssub = {fam, "bx", shape}})
      end
    end
  elseif fam_data.bx == nil then
    for shape,_ in pairs(fam_data.b) do
      fake_fd_insert({"bx", shape, ssub = {fam, "b", shape}})
    end
  end


  lfc_cache[fam].fake_fd = fake_fd
  lfc_cache[fam].scalable = scalable

  return fake_fd
end
-- }}}

-------------------------------------------------------------------------------
-- Manage font definition files, cache etc.
-- get_toks()   write_declare_shape()   write_fake_fd()   add_callback_smcp()
-------------------------------------------------------------------------------
---@function get_toks(items) {{{
---@param items   <table> of [tables of] toks, strings
---@description   Returns sequence of toks, strings for sprint()
-- This is an internal fn, so it should™ only receive valid input --- if not,
--    I doubt type-checking here will help anything.
local function get_toks(items)
  msg_debug("Sequencing toks \'n things ...", "defn", items)
  if type(items) == "table" then 
    local toks = {}
    for _,item in ipairs(items) do
      append(toks, get_toks(item))
    end
    msg_debug("Sequenced toks: ", "defn", toks)
    return toks
  else 
    msg_debug("Returning toks: ", "defn", items)
    return {items}
  end
end
-- }}}

---@function write_declare_shape(pre, line, post[, fea] [, size_spec]) {{{
---@param pre       <table>   of toks/strings e.g. \DeclareFontShape{<fam>}{<enc>}
---@param line      <table>   rep. font spec  e.g. {<series>}, {<shape>}, ... 
---@param post      <table>   of toks/strings e.g. {}
---@param fea       <string>  of features e.g. "mode=node;script=dflt;+tlig+"
---@param size_spec <string>  e.g. "<-5.0>" or "<->s*" etc.
---@Description Returns table of (tables of) toks/strings for a font shape
---@Description declaration. <line> may include ["sub"] or ["ssub"].
local function write_declare_shape(pre, line, post, fea, size_spec) 

  msg_assert(pre and line and post, 
    "Partial or no spec to write. This should never happen!")

  if not size_spec and fea and (find(fea, "^<")) then
    size_spec = fea
    fea = nil
  end

  -- fea should be a table?
  fea = fea or str_fea_default
  fea = line[4] and line[4] ~= "" and (fea .. ";" .. line[4]) or fea

  size_spec = size_spec or str_onesize

  local out = {pre}

  local function toks_font_spec(fnt)
    return  { "\"[", fnt, "]:", fea, "\"" }
  end

  -- series
  append(out, embrace(line[1]))
  -- shape
  append(out, embrace(line[2]))

  if line[3] then

    local kind = type(line[3])

    if kind == "string" then 

      append(out, { tok_group_begin, size_spec, toks_font_spec(line[3], 
        fea), tok_group_end })

    else 
      msg_assert(kind == "table", {"Unexpected type ", kind, "!"})

      insert(out, tok_group_begin)

      for _,item in ipairs(line[3]) do
        append(out, {item[1], toks_font_spec(item[2], fea)}) 
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

---@function add_callback_cache() {{{
---@description This writes the cache at the end of the run.
---@description It should probably be done from LaTeX, though?
---@description Here the debugging is lost as the .log is closed already.
---@description The manual ominously warns ‘Use it at your own risk.’
local function add_callback_cache()
  if lfc_callback_cache_active then
    msg("Cache callback already active.", "debug")
  end
  msg("Adding cache callback.", "info")
  luatexbase.add_to_callback(
    "wrapup_run",
    function()
      if lfc_cache then
        msg("Updating cache ...", "log")
        write_cache()
      else
        msg("No cache data found!")
      end
    end,
    "lfc write cache to disk"
  )
  lfc_callback_cache_active = true
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
  msg("Adding smcp callback.", "info")
  luatexbase.add_to_callback(
    "luaotfload.patch_font",
    function(data, spec, id)
      local path = data.filename
      lfc_cache = lfc_cache or read_cache()

      if lfc_cache.callbacks_smcp and lfc_cache.callbacks_smcp[path] then

        msg("Processing smcp callback ...", "info")
        msg({"Path:\t", path}, "debug")
        msg({"Spec:\t", spec}, "debug")
        msg({"Id:\t", id}, "debug")
        local fam = lfc_cache.callbacks_smcp[path].fam
        local incomplete = lfc_cache.incomplete 
        -- local fd 
        local fake_fd 
        if lfc_cache[fam] and lfc_cache[fam].fake_fd then 
          fake_fd = lfc_cache[fam].fake_fd end

        for line_no,_ in pairs(lfc_cache.callbacks_smcp[path]) do
          if line_no == "fam" or line_no == "related" then goto not_line_ref end

          if incomplete and incomplete[fam] and incomplete[fam][line_no] then

            msg({"Completing ", fam, "...", "log"})

            msg_assert(fake_fd, "Data missing from cache!")
            msg({"line:\t", line_no}, "debug")

            if not data.resources.features.gsub or 
              not data.resources.features.gsub.smcp then
              fake_fd[line_no] = ""
              -- Warn because the usual LaTeX warning gets eaten.
              msg("Missing small-caps (italic/oblique/upright).")
            end
            msg({"fake_fd[line_no]:\t", line_no, ": ", 
              (fake_fd[line_no] == "" and "" or serialize(fake_fd[line_no]))},
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

        msg({"Rewrote fd for ", fam, "..."}, "log")
        msg_debug("fake_fd:", "callback", fake_fd)

        msg("Checking cache enabled ...", "info")
        if not lfc_callback_cache_active then
          add_callback_cache()
        end

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
        msg({"Path:\t", path}, "debug")
        msg({"Spec:\t", spec}, "debug")
        msg({"Id:\t", id}, "debug")

        lfc_cache.resources = lfc_cache.resources or {}
        lfc_cache.resources[path] = lfc_cache.resources[path] or {}
        local cached = lfc_cache.resources[path]
        cached.features = cached.features or {}
        local fea = cached.features

        local rfea = data.resources.features
        
        fea.gsub = rfea.gsub and {} or nil
        if fea.gsub then
          fea.gsub.tnum = rfea.gsub.tnum and true or false
          fea.gsub.lnum = rfea.gsub.lnum and true or false
          fea.gsub.onum = rfea.gsub.onum and true or false
          fea.gsub.pnum = rfea.gsub.pnum and true or false
          fea.gsub.smcp = rfea.gsub.smcp and true or false
          fea.gsub.subs = rfea.gsub.subs and true or false
          fea.gsub.sups = rfea.gsub.sups and true or false
        else
          fea.gsub = false
        end

        -- tidy up callbacks
        lfc_cache.callbacks_data[path] = nil
        if count(lfc_cache.callbacks_data) == 0 then 
          lfc_cache.callbacks_data = nil 
        end

        msg({"Cached resources for ", path, " ..."}, "log")
        msg_debug("Resources: ", "cache", lfc_cache.resources[path])

        msg("Checking cache is active ...", "info")
        if not lfc_callback_cache_active then
          add_callback_cache()
        end

      end

    end,
    "lfc cache font resources"
  )
  lfc_callback_data_active = true

end
--}}}

-------------------------------------------------------------------------------
-- Callback functions **must** come before write_fake_fd()!!
--    Or, for some reason, one works and one doesn't.
--    I have no idea why ...
-- write_fake_fd() should be the **only** function calling add_callback_*().
--    All other functions may write requests to lfc_cache **only**.
-- This function is nonetheless called too often.
-- E.g. it defines *all* family matches for lookups, even though only some
--    are likely required.
-------------------------------------------------------------------------------

---@function write_fake_fd(fam, fake_fd, fea[, scale_factor]) {{{
---@param fam:            NFSS family
---@param fake_fd:        If not cached
---@param fea:            Features
---@param scale_factor:   Scaling factor
---@description fake_fd should be nil unless something has gone wrong.
---@description This should never happen in the automated case.
-- Cache format: see above
local function write_fake_fd(fam, fake_fd, fea, scale_factor)
  msg({"Emulating font definition file for NFSS family ", fam, " with ",
    fea, " scaled ", scale_factor or "1", "."}, "log")
  local pre = {fastcopy(toks_enc_tu), embrace(fam)}
  local out = {
    tok_declare_fam, fastcopy(pre), toks_empty_n
  }
  insert(pre, 1, tok_declare_shape)

  local onesize = str_onesize
  if scale_factor and scale_factor ~= 1 then
    if lfc_cache[fam].scalable then
      msg({"Scaling ", fam, " to ", scale_factor, "."}, "info")
      onesize = onesize .. "s*[" .. scale_factor .. "]"
    else
      msg("Ignoring scaling factor for fonts with optical sizes.")
    end
  end

  for _,line in ipairs(fake_fd) do
    if line ~= "" then 
      msg({"Preparing line: ", fam, ": ", fea, " ", onesize}, "debug")
      append(out, write_declare_shape(pre, line, toks_empty_n, fea, onesize))
    end
  end

  msg_debug("Out (partially tokenized): ", "defn", out)
  out = get_toks(out)
  msg_debug("Out (streamed): ", "defn", out)
  sprint(-2,out)

  if not lfc_cache[fam].complete and not lfc_callback_smcp_active then
    add_callback_smcp()
  end

  msg_assert(lfc_cache[fam].paths, {"No paths cached for ", fam, "!"}, "debug")

  if lfc_cache.callbacks_data and not lfc_callback_data_active then
    for _,path in ipairs(lfc_cache[fam].paths) do
      if lfc_cache.callbacks_data[path] then
        add_callback_data()
        break
      end
    end
  end

end
-- }}}

---@function function file_subs_empty(filename) {{{
---@param       <string> filename (with any extension; no path)
---@description Substitutes the `.tex` file for <filename> using the LaTeX fn.
local function file_subs_empty(filename)
  return sprint(-2, get_toks({tok_file_subs, embrace(filename), 
    toks_file_empty}))
end
-- }}}

---@function add_fake_fd(fam, fake_fd, fea, scale_faction) {{{
---@see         write_fake_fd()
---@description A wrapper around write_fake_fd() which avoids defining fonts
---@description   unnecessarily (and so avoids unnecessary callbacks etc.).
local function add_fake_fd(fam, fake_fd, fea, scale_factor)
  local fd_filename = "tu" .. fam .. ".fd"
  local fn = "__lfc_" .. fd_filename
  luafunction_to_cs(fn, function ()
    return write_fake_fd(fam, fake_fd, fea, scale_factor)
  end, "protected")
  fn = create(fn)
  file_subs_empty(fd_filename)
  sprint(-2, get_toks({tok_hook_gput_code, tok_group_begin, 
    hook_file_before(fd_filename), tok_group_end, toks_dot, embrace(fn)}))
end
-- }}}

---@function use_cached_fd(fam, scale[, now]) {{{
---@param fam   <string>  Name of a cached meta-family.
---@param fea   <string>  Font features.
---@param scale <numeric> Potential scaling factor or nil.
---@param now   <boolean> Whether to write defns or setup hook.
local function use_cached_fd(fam, fea, scale, now) 
  msg_assert(lfc_cache[fam] and lfc_cache[fam].fake_fd,
    "Cache failure. Try removing the cache before recompiling.")
  msg({"Using cached fd emulation for ", fam, "."}, "debug")
  now = now or false

  if now then
    return write_fake_fd(fam, lfc_cache[fam].fake_fd, fea, scale) 
  else
    return add_fake_fd(fam, lfc_cache[fam].fake_fd, fea, scale) 
  end
end
-- }}}

-------------------------------------------------------------------------------
-- Main configuration function
-- font_config()
-------------------------------------------------------------------------------
---@function font_config(targ, config[, immediate]) -- {{{
---@param target    required <string>   Font specification to resolve.
---@param config    optional <table>    Configuration details.
---@param immediate optional <boolean>  Whether to write defns or setup hook.
---@description Main function: configures NFSS families on-the-fly, similar to
---@description   fontspec.
---@description Takes a font request and configuration, possibly writes one or 
---@description   more font definition files and returns table of data.
-- Should be broken up?!
local function font_config(targ, config, immediate)

  if targ == nil then return nil end

  lfc_cache = lfc_cache or read_cache()

  targ = lower(targ)
  if not immediate and (config == "true" or config == "false") then
    immediate = config
    config = nil
  end
  config = config or {}
  immediate = immediate or false

  local scale = config.scale
  
  local f = get_font_data(targ, config.force or false)

  if f == nil or f.metadata == nil then return nil end
  local metadata = f.metadata

  local fam_meta = metadata.fam_meta
  msg_assert(fam_meta ~= nil, {"No reults for ", targ})


  if not metadata.cached then 

    local data = f.data
    if data == nil then return nil end

    local parsed_fam

    local nfss_hashes = {}
    local regular = false
    local book = false
    local medium = false


    -- Adjust returned data for compatibility with NFSS
    --    - Reduce width + weight -> series
    --    - Reduce style + variant -> shape
    for name,font in pairs(data) do
      local fullname = font.fullname
      
      -- We don't want to parse maths fonts.
      -- Best would be to check for the MATH table, but we don't want to
      --    load every font for that, so do this for now.
      if (find(fullname, "math")) then
        goto discard
      end

      local width = font.width
      local weight = font.weight
      local style = font.style
      local variant = font.variant
      -- family is more specific than familyname
      local family = font.familyname

      local series, shape

      if fam_meta ~= family then

        family = (gsub(family, variant, ""))
        if not (find(fam_meta, "%d")) then
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
        if (find(name, "unslanted")) then
          family = (gsub(family, "unslanted", ""))
          if (style == "normal" or style == "regular") and variant == "normal" then
            style = "uprightitalic"
          end
        end

        if weight == "normal" or weight == "regular" then
          if (find(fullname, "book")) then weight = "book"
            book = true
          elseif (find(fullname, "medium")) then weight = "medium"
            medium = true
          else regular = true end
        end

      end


      local t

      if parsed_fam == nil then parsed_fam = {} end
      t = parsed_fam
      t[family] = t[family] or {}
      t = t[family]


      -- translate to NFSS identifiers (texdoc fntguide)
      local nfss_weight   = parse_spec(weights, weight)
      local nfss_width    = parse_spec(widths, width)
      local nfss_style    = parse_spec(styles, style)
      local nfss_variant  = parse_spec(variants, variant)


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
          
    -- link families to fam_meta

    lfc_cache.meta_families = lfc_cache.meta_families or {}
    lfc_cache.meta_families.by_meta_fam = lfc_cache.meta_families.by_meta_fam or {}
    lfc_cache.meta_families.by_meta_fam[fam_meta] = {}
    local by_meta_fam = lfc_cache.meta_families.by_meta_fam[fam_meta]


    for fam,fam_data in pairs(parsed_fam) do
      local fake_fd = prepare_fake_fd(fam, fam_data)
      if fake_fd then
        insert(by_meta_fam, fam)
        local scale = (config[fam] and config[fam].scale and 
          config[fam].scale) or (config.scale and config.scale) or nil
        local fea = (config[fam] and config[fam].fea and config[fam].fea) or
          (config.fea and config.fea) or str_fea_default
        if immediate then
          write_fake_fd(fam, fake_fd, fea, scale) 
        else
          add_fake_fd(fam, fake_fd, fea, scale) 
        end
      end
    end

    if not lfc_callback_cache_active then add_callback_cache() end

  else

    for _,fam_name in ipairs(lfc_cache.meta_families.by_meta_fam[fam_meta]) do
      local scale = (config[fam_name] and config[fam_name].scale and 
        config[fam_name].scale) or (config.scale and config.scale) or nil
      local fea = (config[fam_name] and config[fam_name].fea and 
        config[fam_name].fea) or (config.fea and config.fea) or str_fea_default
      use_cached_fd(fam_name, fea, scale, immediate) 
    end

  end


  return fam_meta
end
-- }}}


-------------------------------------------------------------------------------
-- LaTeX interface things
-------------------------------------------------------------------------------
---@function do_with_one_scanner(fn) {{{
---@param fn    <function>  Function to execute on argument.
---@description Returns a function which picks up and does something with
---@description one TeX argument.
---@description An attempt to generalise get_fam_default_scanner() above.
local function do_with_one_scanner(fn)
  return function()
    local one = param(false)
    msg({"Scanned one: ", one}, "debug")
    return fn(one)
  end
end
-- }}}

---@function do_with_two_scanner(fn) {{{
---@param fn    <function>  Function to execute on argument.
---@description Returns a function which picks up and does something with
---@description   two TeX arguments.
local function do_with_two_scanner(fn)
  return function()
    local one = param(false)
    local two = param(false)
    msg({"Scanned two: ", one, " | ", two}, "debug")
    return fn(one, two)
  end
end
-- }}}

local fam_defaults = { -- {{{
  rm = tok_rmdefault,
  sf = tok_sfdefault,
  tt = tok_ttdefault,
}
-- }}}

---@function get_fam_default_scanner(fam) {{{
---@param fam   <string: "rm" | "sf" | "tt">  NFSS default family.
---@description Returns a Lua function which scans an argument and sets the
---@description   specified family default to the given value.
local function get_fam_default_scanner(fam) 
  return do_with_one_scanner(
    function(fam_name)
      local cleanname = cleanfilename(fam_name)
      nfss_doc_families[cleanname] = {
        name = tostring(fam_name),
        cleanname = cleanname,
        default = fam,
      }
      nfss_default_families[fam] = nfss_doc_families[cleanname]
      nfss_doc_families.curr = cleanname
      msg_debug("NFSS default families: ", "doc", nfss_default_families)
    end)
end
-- }}}


---@function get_fam_name_scanner() {{{
---@description Returns a function which takes a name and stores it.
local function get_fam_name_scanner()
  return do_with_one_scanner(
    function(name)
      local cleanname = cleanfilename(name)
      nfss_doc_families[cleanname] = {
        name = tostring(name),
        cleanname = cleanname,
      }
      nfss_doc_families.curr = cleanname
      msg_debug("NFSS doc families: ", "doc", nfss_doc_families)
    end)
end
-- }}}

---@function get_fam_cfg_scanner() {{{
---@description Returns a function which takes a feature specification and 
---@description stores it.
local function get_fam_cfg_scanner()
  return do_with_two_scanner(
    function(key, value)
      local curr = nfss_doc_families.curr
      msg_assert(curr ~= nil, "No current family to set features for!")
      curr = nfss_doc_families[curr]
      curr[key] = lower(tostring(value))
      msg_debug("Scanned family configuration: ", "doc", curr)
    end)
end
-- }}}

---@function configure_doc_families() {{{
---@description Configures requested fonts.
---@description Sets defaults for rm/sf/tt, if applicable.
---@description This doesn't work if I make this a direct fn. rather than a
---@description generator. Something to do with (Lua) scope, maybe?
local function configure_doc_families()
  return function()
    msg_debug("Configuring doc families ...", "doc",
      nfss_default_families,
      nfss_doc_families,
      fam_defaults)
    local config = {fea = nil, scale = nil, force = nil}
    for name,cfg in pairs(nfss_doc_families) do
      if name ~= "curr" then
        config.fea = cfg.fea or nil
        config.scale = cfg.scale or nil
        config.force = cfg.force or nil
        -- Currently ignores features!!
        local nfss_fam = font_config(cfg.name, config, cfg.default and true or 
          false)
        if nfss_fam ~= nil then cfg.nfss_fam = nfss_fam
          if not cfg.default then
            msg({"Creating NFSS family ", nfss_fam}, "debug")
            luafunction_to_cs(cfg.cleanname, function()
              return sprint(-2, get_toks({tok_fontfamily, embrace(nfss_fam),
                tok_selectfont}), "protected")
            end)
          end
        else 
          msg({"No family found for ", cfg.name, "!"}, "warn") 
          nfss_doc_families[name] = nil
        end
      end
    end
    msg_debug("NFSS doc families: ", "doc", nfss_doc_families)
    msg("Setting default families ...", "debug") 
    for fam,cfg in pairs(nfss_default_families) do
      if cfg.nfss_fam then
        local fam_name = cfg.nfss_fam
        msg({"Setting ", fam, " default to ", fam_name, "."}, "log")
        sprint(-2, get_toks({tok_renewcommand, fam_defaults[fam], embrace(fam_name)}))
      else msg({"No family found for ", fam, "!"})
      end
    end
  end
end
-- }}}

-- Generate TeX macros to use Lua functions to set rm, sf and tt.
luafunction_to_cs("__lfc_set_rm:n", get_fam_default_scanner("rm"))
luafunction_to_cs("__lfc_set_sf:n", get_fam_default_scanner("sf"))
luafunction_to_cs("__lfc_set_tt:n", get_fam_default_scanner("tt"))

-- Scanners for additional family names and a general one for features.
luafunction_to_cs("__lfc_set_fam_name:n", get_fam_name_scanner())
luafunction_to_cs("__lfc_set_fam_cfg:nn", get_fam_cfg_scanner())

-- A macro to configure the fonts at begindocument.
luafunction_to_cs("__lfc_configure_doc_families:", configure_doc_families())
-------------------------------------------------------------------------------
-- Setup on load
-------------------------------------------------------------------------------
-- {{{
-- Forced for now
-- For now, this loads regardless of what the font uses.
local cache_path = get_cache_path()
lfc_cache = isfile(cache_path) and read_cache() or {}
-- }}}

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Public exports
-- Probably get_cache_path should be exposed, at least.
-------------------------------------------------------------------------------
-- Is this a bad idea? 
-- Max said most people want a separate function --- presumably they have some
--    reason for that?
-- lfc.font_config = font_config
-- lfc.get_font_data = get_font_data
-- lfc.fonts = fonts
-- lfc.write_cache = write_cache
-- lfc.read_cache = read_cache
-- lfc.get_cache_path = get_cache_path


-- return lfc
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-- vim: et:foldmethod=marker:
