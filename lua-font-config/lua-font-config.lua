-- $Id: lua-font-config.lua 12198 2026-11-10 02:44:24Z cfrees $
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
do
  local name, rev, date = string.match(
    "$Id: lua-font-config.lua 12198 2026-11-10 02:44:24Z cfrees $", 
    "Id: ([a-z][a-z-]*)%.lua (%d%d*) (%d%d%d%d%-%d%d%-%d%d) ")
  luatexbase.provides_module({
    name      = name,
    date      = date,
    revision  = rev,
    version   = "v0.1",
  })
end
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Cache format:
-------------------------------------------------------------------------------
--  lfc_cache ->  {{{
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
--      by_meta_math = {
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
--      fake_fd = {
--        {<series>, <shape>, <fullpath>, <subfont>, <cfg>} 
--        | {<series>, <shape>, {
--            <min>, <max>, <fullpath>, <subfont>
--          }, <cfg>}
--        | {<series>, <shape>, ssub = {<fam>, <series>, <shape>}}
--        | {<series>, <shape>, sub = {<fam>, <series>, <shape>}},
--        ...,
--      },
--      paths = <table of paths to font files>,
--      scalable = true | false,
--      typeset_mode = 0 | 1 [| 2? ]
--    }
--  }}}
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- locals {{{

-- imports {{{
local inspect                   = inspect
local is_writable, join         = file.is_writable, file.join
local isdir, isfile, mkdir      = lfs.isdir, lfs.isfile, lfs.mkdir
local get_functions_table       = lua.get_functions_table
local new_lua_function          = luatexbase.new_luafunction
-- string
local gsub, gmatch, match       = string.gsub, string.gmatch, string.match
local find, format, lower       = string.find, string.format, string.lower
-- table
local append, tohash, insert    = table.append, table.tohash, table.insert
local copy, count, fastcopy     = table.copy, table.count, table.fastcopy
local load, mirrored, sort      = table.load, table.mirrored, table.sort
local save, setmetatableindex   = table.save, table.setmetatableindex
local concat, serialize, unique = table.concat, table.serialize, table.unique
local prepend, sortedpairs      = table.prepend, table.sortedpairs
local hashed, flattened, merged = table.hashed, table.flattened, table.merged
-- tex | texio | token
local sprint, inputlineno       = tex.sprint, tex.inputlineno
local write, write_nl           = texio.write, texio.write_nl
-- Max Chernoff: ‘The Lua function token.scan_argument accepts a boolean argument (token.scan_argument(true) or token.scan_argument(false)) which determines whether to expand the TeX string argument’ (https://chat.stackexchange.com/transcript/message/69210787#69210787)
local create, param, set_lua    = token.create, token.scan_argument, token.set_lua
-- lpeg
local oneof, stripper, keeper       = lpeg.oneof, lpeg.stripper, lpeg.keeper
local firstofsplit, secondofsplit   = lpeg.firstofsplit, lpeg.secondofsplit
local Ct, splitat, lpeg_match       = lpeg.Ct, lpeg.splitat, lpeg.match
local checkedsplit                  = lpeg.checkedsplit
local patterns                      = lpeg.patterns
local p_comma, p_semicolon          = patterns.comma, patterns.semicolon
local p_is_sign, p_space            = patterns.sign, patterns.space
local p_equal, p_whitespace         = patterns.equal, patterns.whitespace
local p_colon                       = patterns.colon
-- }}}

-- ours {{{
-- Used for handling pre-config, but not sure this is either necessary or
--    wise.
local lfc   = lfc or {}

-- Used to store cache for access during run.
local lfc_cache

-- Booleans
local lfc_callback_smcp_active  = false
local lfc_callback_data_active  = false
local lfc_callback_cache_active = false

-- Strings
local function enquote(str) return format("%q", str) end

-- lpeg
local p_semicolon_or_comma  = oneof(p_semicolon, p_comma)
local p_key                 = firstofsplit("=")
local p_value               = secondofsplit("=")
local p_sign                = keeper(p_is_sign)
local p_unsign              = stripper(p_is_sign)
local p_fea_split           = splitat(p_semicolon_or_comma, false)
---@function fea_split(s_fea) {{{
---@param s_fea   <string>  List of semicolon or comma separated features
---@description Returns a table of structurally ‘normalised’ features.
---@example fea_split("script=dflt;language=dflt,+onum;pnum=true;-tlig;mode=node")
---@example -> {
---@example       ["script"]    = "dflt",
---@example       ["language"]  = "dflt",
---@example       ["onum"]      = "true",
---@example       ["pnum"]      = "true",
---@example       ["tlig"]      = "false",
---@example       ["mode"]      = "node"
---@example    }
local function fea_split(s_fea) 
  local t_fea   = lpeg_match(Ct(p_fea_split), s_fea) 
  local t_norm  = {}
  for ind,feature in ipairs(t_fea) do
    local key, val = lpeg_match(p_key, feature), lpeg_match(p_value, feature)
    if not val then
      val = lpeg_match(p_sign, key)
      key = lpeg_match(p_unsign, key)
      val = val == "+" and "true" or (val == "-" and "false" or val)
    end
    t_norm[key] = val
  end
  return t_norm
end
-- }}}

local str_onesize           = "<->"
local str_fea_default       = "mode=node;language=dflt;script=dflt;+tlig;"
local str_fea_math_default  = "mode=basic;language=dflt;script=math;"
local str_fea_math_sf       = "ssty=1"
local str_fea_math_ssf      = "ssty=2"

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

local tok_mathrm            = create("__lfc_set_mathrm:")
local tok_mathsf            = create("__lfc_set_mathsf:")
local tok_mathtt            = create("__lfc_set_mathtt:")

local tok_declare_m_scr_map = create("DeclareMathScriptfontMapping")
local tok_declare_lum_fnts  = create("__lfc_declare_lum_symbol_fonts:nn")

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
local msg_debug, msg_assert, lfc_debug, lfc_log_level

local msg_level = {
  bug   = "Bug",
  err   = "Error",
  warn  = "Warning",
  info  = "Info",
  log   = "Log",
  debug = "Debug",
}
local msg_log_levels 
do
  local h = {
    "bug",
    "err",
    "warn",
    "info",
    "log",
    "debug",
  }
  msg_log_levels = hashed(h)
end

---@function msg_format(msg, level) {{{
---@param   msg   <string|table>    Message.
---@param   level <string>          Level as string.
---@status  internal
---@description Module specific logging format based on ltluatex.lua's.
local function msg_format(msg, level)
  local head = format("Package lfc %s: ", level)
  if type(msg) == "table" then 
    insert(msg, format("on input line %s", inputlineno))
  else
    msg = {tostring(msg), format("on input line %s.", inputlineno)}
  end
  -- this should ideally start (lfc)<space> 
  local cont = (gsub(gsub(head, ".", " "), "^(.....)", "\n(lfc)"))
  return format("%s%s", head, concat(msg, cont))
end
-- }}}

---@function msg(text, level) {{{
---@param   text      <string|table>  Message.
---@param   level     <string>        Minimum logging level for issuing message.
---@status  internal
local function msg(text, level)
  level = level or "warn"
  level_n = msg_log_levels[level] or msg_log_levels.debug
  if level_n > msg_log_levels[lfc_log_level] then return end
  if level ~= "debug" then
    write_nl(msg_format(text, msg_level[level]))
  elseif type(text) == "string" then
    write_nl(concat({"[lfc] ", msg_level[level], ":\t", text, "\n"}, ""))
  else
    write_nl(concat({"[lfc] ", msg_level[level], ":\t", concat(text, ""), "\n"},
      ""))
  end
  if level == "bug" then
    write_nl(msg_format({"Please report to one of",
      "\thttps://www.codeberg.org/cfr/nfssext/issues",
      "You can get more information using",
      "\t\\usepackage[debug]{lua-font-config}"}))
    error(1)
  elseif level == "err" then
    error(2)
  end
end
-- }}}

---@function msg_config(log_level, cfg) {{{
---@param     log_level   <string>  Logging level from choices.
---@param     cfg         <table>   Key-value configuration.
---@status    internal
local function msg_config(log_level, cfg)
  lfc_debug = (cfg and cfg.state) and true or false
  lfc_log_level = log_level or (lfc_debug and "debug" or "info")

  if lfc_debug then

    -- Max Chernoff: https://chat.stackexchange.com/transcript/message/69252312#69252312.
    -- Also from fontloader-l-lua.lua.
    function inspect(...)
      for ind=1,select("#", ...) do
        local thing = select(ind, ...)
        local kind = type(thing)
        write_nl("term and log", thing == nil and "nil" 
          or (kind == "string" and thing 
          or (kind == "table" and serialize(thing)
          or tostring(thing))))
      end
    end
  
    function msg_assert(cond, text, level) assert(cond, (type(text) == "string" 
      and text) or concat(text, "")) end

    local cats = cfg.categories or {
      cache     = true,
      callback  = true,
      data      = true,
      defn      = true,
      doc       = true,
    }

    -- Debugging is typically enabled after the cache is read and the cache
    --    saved after the log is closed, so dump it to the log now if required.
    if cats.cache and lfc_cache ~= nil and #lfc_cache ~= 0 then
      inspect(lfc_cache)
    end

    local skipped_msg = {
      cache     = false,
      callback  = false,
      data      = false,
      defn      = false,
      doc       = false,
    }

    function msg_debug(m, cat, ...)
      if cat and not cats[cat] then 
        if not skipped_msg[cat] then
          msg({"Skipping debug messages for ", cat}, "debug") 
          skipped_msg[cat] = true
        end
        return 
      end
      cat = cat or "generic"
      msg({"[", cat, "] ", m}, "debug")
      local vargs = {...} -- Aaaarrrggghhh!!
      for _,i in ipairs(vargs) do inspect(i) end
    end

  else

    function msg_assert(cond, text, level) 
      if not cond then
        msg(text, level or "bug")
      end
    end

    function msg_debug(...) end

  end
end
-- }}}
msg_config(lfc.log_level, lfc.debug)
-- }}}

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Max Chernoff: https://chat.stackexchange.com/transcript/message/69175678#69175678
-- Use ConTeXt's font name database code.
-------------------------------------------------------------------------------

---@mcsubstitute -- {{{

local names = require("lfc-context-font-syn")
-- Unconditionally load the font name database, regenerating it if
-- necessary.
names.load(false, false)
-- names.load(true, true)

-- }}}


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- late locals {{{
local cleanfilename = names.cleanfilename
local resolve = names.resolve
-- References the original function rather than the copy?
local lookup_font_file = fonts.names.lookup_font_file
-- local font_data = names.data
local font_data = names.get_data()
-- }}}

-------------------------------------------------------------------------------
-- Utilities for caching data
-------------------------------------------------------------------------------
---@function get_cache_path() -- {{{
---@description Returns fullname of module cache.
---@statue internal
local function get_cache_path()
  msg("Accessing cache ...", "debug")
  local path = (gsub(names.cache.writable, "^(.*/)[^/]+$", "%1" ))
  msg_assert(path ~= nil, "Cannot find place for cache!")
  if not isdir(join(path, "lfc")) then
    msg_assert(is_writable(path), {"Cache ", path, " not writable!"})
    msg_assert(mkdir(join(path, "lfc")), {"Cannot create cache ", path,
    "/lfc", " directory!"})
  end
  return join(path, "lfc", "lfc_cache.lua")
end
-- }}}

---@function read_cache()  -- {{{
---@param loc <string> Optional alternate full path for cache.
---@status internal
local function read_cache(loc)
  write_nl("[lfc] Reading cache ...")
  loc = loc or get_cache_path()
  local cache = isfile(loc) and load(loc) or {}
  cache.resources = cache.resources or {}
  cache.meta_families = cache.meta_families or {}
  cache.meta_families.by_meta_fam = cache.meta_families.by_meta_fam or {}
  cache.meta_families.by_meta_math = cache.meta_families.by_meta_math or {}
  msg_debug("Read cache state:\n", "cache", cache)
  return cache
end
-- }}}

---@function write_cache() -- {{{
local function write_cache()
  msg("Writing cache ...", "debug")
  if lfc_cache then
    local loc = get_cache_path()
    msg_debug("Saving cache state:\n", "cache", lfc_cache)
    -- Duplicates data referenced by pointers/links/whatever they are.
    save (loc, lfc_cache)
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

      local ff_ext = file.suffix(ff)
      local ff_nameonly = file.nameonly(ff)

      if ff_ext and ff_nameonly then
        fam_meta = font_data.mappings[ff_ext][ff_nameonly].familyname
        f.metadata.ext = ff_ext
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
  if not force then
    cached = lfc_cache.meta_families.by_meta_fam[fam_meta] or
    lfc_cache.meta_families.by_meta_math[fam_meta]
  else
    lfc_cache.meta_families.by_meta_fam[fam_meta] = nil
    lfc_cache.meta_families.by_meta_math[fam_meta] = nil
  end
  metadata.hash_key  = fam_meta

  -- If a cached emulated .fd exists, we're done.
  if cached then
    metadata.cached = cached
    msg_debug("Returning cached data:", "data", f)
    return f
  end

  -- If not, get font data for family.

  -- Returns indexed list, limited coverage.
  -- local data = font_data.families[fam_meta]

  msg({"get_font_data() :: search term: ", fam_meta}, "debug")

  -- Returns key-val list, wider coverage.
  local data = names.list(fam_meta .. ".*",false,true)
  if data == nil then return nil end

  msg_debug("get_font_data() :: data:", "data", data)

  -- Unfortunately, the returned names are strange.
  -- Worse, different fonts get the same name, so some silently vanish.

  local data_fams, data_by_cleanfilename = {}, {}
  for _,datum in pairs(data) do
    insert(data_fams, datum.familyname)
  end
  for _,famname in ipairs(data_fams) do
    local t = font_data.families[famname]
    for _,fntdata in pairs(t) do
      fntdata.fullpath = lookup_font_file(fntdata.filename)
      data_by_cleanfilename[fntdata.cleanfilename] = fntdata
    end
  end

  -- Belt and braces ... and still don't get 100% of e.g. newcomputermodern,
  --    due to the wonky metadata.
  for name, fdata in pairs(data) do
    local cname = fdata.cleanfilename
    if data_by_cleanfilename[cname] == nil then
      fdata.fullpath = lookup_font_file(fdata.filename)
      data_by_cleanfilename[cname] = fdata
    end
  end

  msg_debug("get_font_data() :: data_by_cleanfilename:", "data", 
    data_by_cleanfilename)

  -- -- names.list returns duplicate names for some font files.
  -- -- This de-duplicates the list, though I wonder if there's a better method?
  -- local data_by_filename = {}
  --
  -- -- One would prefer to use index IDs here, but I'm not sure how to get that
  -- --  in a nice way.
  -- for name, fdata in pairs(data) do
  --   -- choice of name is arbitrary
  --   data_by_filename[fdata.filename] = data_by_filename[fdata.filename] or name
  -- end
  --
  -- msg_debug("get_font_data() :: data_by_filename:", "data", data_by_filename)
  --
  -- -- ‘In place’ doesn't mean what you think :(.
  -- data_by_filename = mirrored(data_by_filename)
  --
  -- msg_debug("get_font_data() :: data_by_filename (mirrored):", "data", data_by_filename)

  -- -- Discard dupes -- ??????
  -- -- Data doesn't include full paths, so add these now.
  -- for name, fdata in pairs(data) do
  --   if data_by_filename[name] == nil then -- ?????
  --     data[name] = nil
  --   elseif fdata.fullpath == nil then
  --     -- Gets full path from file name.
  --     fdata.fullpath = lookup_font_file(fdata.filename)
  --   end
  -- end

  -- f.data = data
  f.data = data_by_cleanfilename

  msg_debug("Returning fresh data:", "data", f)

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
  medium = "f", -- deviant
  book = "k",   -- deviant
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
-- parse_spec() parse_nfss() prepare_fake_fd() parse_fea()
-------------------------------------------------------------------------------
--- {{{
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

---@function parse_nfss(nfss_rep1, nfss_rep2, nfss_default_rep) -- {{{
---@param   nfss_rep1         nfss_weight | nfss_variant
---@param   nfss_rep2         nfss_case   | nfss_style
---@param   nfss_default_rep  m           | n
local function parse_nfss(nfss_rep1, nfss_rep2, nfss_default_rep)
  local nfss_rep
  -- ‘m’ must not be combined, as of the 2020 changes, so ‘mb’ is
  --    not allowed
  -- Likewise ‘n’, but I never saw anybody combine this, so nothing broken
  if nfss_rep1 == nfss_default_rep then
    nfss_rep = nfss_rep2
  elseif nfss_rep2 == nfss_default_rep then
    nfss_rep = nfss_rep1
  else 
    nfss_rep = format("%s%s", nfss_rep1, nfss_rep2)
  end
  return nfss_rep
end
-- }}}

---@function prepare_fake_fd(fam, fam_data, typeset_mode, force) {{{
---@description Returns a table of tables
---@description Each table uses fam[-suffix] containing lines 
---@description   suitable for emulating an .fd file
---@param fam           <string>  NFSS family
---@param fam_data      <table>   Sorted data for fonts
---@param typeset_mode  <int>     0 (text) | 1 (math) | 2 (symbol - ignored)
---@param force         <boolean>
---@status internal
-- Should be split??
local function prepare_fake_fd(fam, fam_data, typeset_mode, force) 
  force = force or false
  typeset_mode = typeset_mode or 0
  msg(concat({"prepare_fake_fd params:", fam, tostring(fam_data), typeset_mode,
    tostring(force)}, " "), "info")

  lfc_cache[fam] = lfc_cache[fam] or {}

  if lfc_cache[fam].fake_fd and not force then

    if typeset_mode ~= 1 then return lfc_cache[fam].fake_fd
    elseif lfc_cache.meta_families.by_meta_math[fam] then 
      local t = lfc_cache.meta_families.by_meta_math[fam]
      for ind,mfam in ipairs(t) do
        t[ind] = lfc_cache[mfam].fake_fd
        if not t[ind] then 
          msg(concat({"Missing defns for ", mfam, " (family ", fam, ").\n\z
            This should not really happen, but I will try to recover."}, ""))
          goto math_awol 
        end
      end
      if not #t == 3 then 
        msg("Not exactly 3 maths families!", "warn") 
        goto math_awol
      end
      return t[1], t[2], t[3]
    else
      msg(concat({"Missing maths family for ", fam, ". Regenerating data."}, ""))
    end
  end
  :: math_awol ::

  lfc_cache[fam].paths = lfc_cache[fam].paths or {}
  local path_list = lfc_cache[fam].paths

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
  end

  local std_series = {b = {}, bx = {}}

  for series,series_data in pairs(fam_data) do

    local std_lines = {n = 0, it = 0, sl = 0, scit = 0, scsl = 0}

    for shape,fnts in pairs(series_data) do

      msg({"Processing font(s) for ", series, " and ", shape}, "info")

      msg_assert(#fnts ~= 0, "The number of fonts should never be zero!")

      -- Add path to list for family and add callback if needed.
      for _,ff in ipairs(fnts) do add_path(ff.fullpath) end

      if #fnts == 1 then

        -- Need an empty entry for cfg mods e.g. +smcp; etc.
        fake_fd_insert({series, shape, enquote(fnts[1].fullpath),
          fnts[1].subfont or 0, ""})

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

          insert(ssubs, {format("<%s-%s>", min, max),
            enquote(fnt.fullpath), fnt.subfont or 0 })

          hash_last = fnt.nfss_hash

          -- In case there are just 2 sizes, as opposed to a range, we need 
          --    to undo the "" setting to avoid discarding optical sizes 
          --    completely.
          min = fnt.minsize or fnt.designsize or 0
          max = fnt.maxsize or fnt.designsize or 0

          max_max = (max > max_max) and max or max_max
          min_min = min_min or min
          min_min = (min < min_min) and min or min_min

        end

        -- Is this necessary? 
        -- If not, could also discard the last part of the loop ...
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
            fake_fd_insert({series, shape, enquote(i[2]), i[3], ""})
          end
          msg({"Apparent duplicates for ", fam, "/", series,
          "/", shape, "."})
        end

      end

      if typeset_mode == 0 then

        msg("(prepare_fake_fd) typeset_mode is 0", "debug")

        if shape == "n" then std_lines.n = curr_line 
        elseif shape == "it" then std_lines.it = curr_line
        elseif shape == "sl" then std_lines.sl = curr_line
        elseif shape == "scit" then std_lines.scit = curr_line
        elseif shape == "scsl" then std_lines.scsl = curr_line
        end

        if series == "b" and not fam_data.bx then
          if #series_data[shape] == 1 then
            fake_fd_insert({"bx", shape, ssub = {"b", shape}})
          else
            local reuse_line = fake_fd[curr_line]
            fake_fd_insert({"bx", shape, reuse_line[3], reuse_line[4], reuse_line[5]})
          end
        elseif series == "bx" and not fam_data.b then
          if #series_data[shape] == 1 then
            fake_fd_insert({"bx", shape, ssub = {"b", shape}})
          else
            local reuse_line = fake_fd[curr_line]
            fake_fd_insert({"b", shape, reuse_line[3], reuse_line[4], reuse_line[5]})
          end
        end

      end
    end

    if typeset_mode == 0 then
      -- For text fonts, check for missing basic shapes
      msg("(prepare_fake_fd) typeset_mode is 0", "debug")

      if series_data.it == nil then
        if series_data.sl ~= nil then
          if #series_data.sl == 1 then
            fake_fd_insert({series, "it", ssub = {series, "sl"}})
          else
            local reuse_line = fake_fd[std_lines.sl]
            fake_fd_insert({series, "it", reuse_line[3], reuse_line[4], reuse_line[5]})
          end
        end
      elseif series_data.sl == nil then
        if #series_data.it == 1 then
          fake_fd_insert({series, "sl", ssub = {series, "it"}})
        else
          local reuse_line = fake_fd[std_lines.it]
          fake_fd_insert({series, "sl", reuse_line[3], reuse_line[4], reuse_line[5]})
        end
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

          if lfc_cache.resources[curr_path] then
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
          if type(line_mod[3]) == "table" then
            -- Optical sizes.
            line_mod[4] = "+smcp"
          else
            -- Single size, so subfont is at index 4.
            line_mod[5] = "+smcp"
          end
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
          if #series_data.scsl == 1 then
            fake_fd_insert({series, "scit", ssub = {series, "scsl"}})
            fake_fd_insert({series, "si", ssub = {series, "scit"}})
          else
            local reuse_line = fake_fd[std_lines.scsl]
            fake_fd_insert({series, "scit", reuse_line[3], reuse_line[4], reuse_line[5]})
            fake_fd_insert({series, "si", reuse_line[3], reuse_line[4], reuse_line[5]})
          end
        end
      elseif series_data.scsl == nil then
        if #series_data.scit == 1 then
          fake_fd_insert({series, "scsl", ssub = {series, "scit"}})
          fake_fd_insert({series, "si", ssub = {series, "scsl"}})
        else
          local reuse_line = fake_fd[std_lines.scit]
          fake_fd_insert({series, "scsl", reuse_line[3], reuse_line[4], reuse_line[5]})
          fake_fd_insert({series, "si", reuse_line[3], reuse_line[4], reuse_line[5]})
        end
      else 
        if #series_data.scit == 1 then
          fake_fd_insert({series, "si", ssub = {series, "scit"}})
        else
          local reuse_line = fake_fd[std_lines.scit]
          fake_fd_insert({series, "si", reuse_line[3], reuse_line[4], reuse_line[5]})
        end
      end

      -- Other possibilities:
      --    - Auto-generate fds for different figure styles?
      --    - Swash/alternates?
      --    - How does this do with .ttc or variable fonts?

      -- It is (relatively) cheap to create additional families once the base
      --  case is done, if features can be inferred on loading.
      -- But I'm not sure how that would work for families, as opposed to 
      --  shapes?
    end
  end

  lfc_cache[fam].paths = unique(path_list)

  lfc_cache[fam].fake_fd = fake_fd
  lfc_cache[fam].scalable = scalable
  lfc_cache[fam].typeset_mode = typeset_mode


  -- This probably would be better wrapped into a mechanism to handle variants.
  -- ^^ Nah?

  local fake_fd_sf, fake_fd_ssf

  if typeset_mode == 1 then

    msg("(prepare_fake_fd) typeset_mode is 1", "info")

    local sf, ssf = format("%s-sf", fam), format("%s-ssf", fam)
    msg(concat({"Emulating ", sf, " and ", ssf, "."}, ""), "log")

    -- We need extra cache data for maths families so that cache look-up
    -- catches scripts.
    lfc_cache.meta_families.by_meta_math[fam] = {fam, sf, ssf}
    lfc_cache[sf] = {}
    lfc_cache[ssf] = {}

    fake_fd_sf = fastcopy(fake_fd)
    fake_fd_ssf = fastcopy(fake_fd)

    for _,line in ipairs(fake_fd_sf) do
      if not line.ssub and not line.sub then
        if type(line[3]) == "string" then 
          line[5] = str_fea_math_sf
        else
          msg_assert(type(line[3]) == "table")
          line[4] = str_fea_math_sf 
        end
      end
    end
    for _,line in ipairs(fake_fd_ssf) do
      if not line.ssub and not line.sub then
        if type(line[3]) == "string" then 
          line[5] = str_fea_math_ssf
        else
          msg_assert(type(line[3]) == "table")
          line[4] = str_fea_math_ssf 
        end
      end
    end

    lfc_cache[sf].fake_fd = fake_fd_sf
    lfc_cache[ssf].fake_fd = fake_fd_ssf

    for i,j in pairs(lfc_cache[fam]) do
      if not lfc_cache[sf][i] then lfc_cache[sf][i] = j end
      if not lfc_cache[ssf][i] then lfc_cache[ssf][i] = j end
    end
    
  end

  return fake_fd, fake_fd_sf, fake_fd_ssf
end
-- }}}

---@table fea_lookup, fea_ignore {{{
local fea_lookup = {
  figures       = {
    "lnum",
    "onum",
    "pnum",
    "subs",
    "sups",
    "tnum",
  },
  -- script    = {default = "dflt", latin = "ltn"},
  -- language    = {
  -- },
  mode       = {
    harfbuzz      = "harf",
    node          = nil,
  },
  -- script      = {
  -- },
}
local fea_ignore = {
  calt          = "true",
  kern          = "true",
  language      = "dflt",
  liga          = "true",
  lnum          = "true",
  mode          = "node",
  rlig          = "true",
  script        = "dflt",
  tlig          = "true",
  tnum          = "true",
}
local fea_known = {
  c2pc          = true, 
  c2sc          = true, 
  calt          = true, 
  case          = true, 
  clig          = true, 
  cpsp          = true, 
  cswh          = true, 
  dlig          = true, 
  falt          = true, 
  fina          = true, 
  frac          = true,
  hist          = true, 
  hlig          = true, 
  jalt          = true, 
  kern          = true, 
  liga          = true, 
  lnum          = true,
  onum          = true,
  pcap          = true,
  pnum          = true,
  rand          = true,
  rlig          = true, 
  sinf          = true,
  subs          = true,
  sups          = true,
  swsh          = true,
  titl          = true,
  tlig          = true,
  tnum          = true,
  unic          = true,
  zero          = true,
}
-- }}}
---@function parse_fea(fea) {{{
---@param       <string>
---@return      (string) <feature spec.>, (string) <suffix> or nil
---@description Assumes typeset mode is 0. Normalises feature spec. for loader,
---@description constructs suffix for family name.
local function parse_fea(fea)
  if not fea then return str_fea_default, nil end
  local t_fea = fea_split(lower(tostring(fea)))
  local suffix = {}
  local cat_suffix
  -- Paid â cheisio leihau nifer o dablau yma!!!
  local t_feat = {str_fea_default}
  -- sortedpairs for regression testing ...
  for key,val in sortedpairs(t_fea) do
    if key == "" then
      t_fea[key] = nil
    elseif fea_ignore[key] and fea_ignore[key] == val then
      t_fea[key] = nil
    elseif fea_known[key] then
      insert(t_feat, format("%s=%s;", key, val))
    elseif find(key, "^+cv%d%d$") or find(key, "^[+-]nalt$") or 
      find(key, "^[+-]salt$") then insert(t_feat, format("%s=%s;", key, val))
    elseif find(key, "^[+-]ss%d%d$") then
      insert(t_feat, key .. ";")
    else
      local code = fea_lookup[key]
      if code then
        local c = code[val]
        if c then
          t_fea[key]  = nil
          t_fea[c] = "true"
          insert(t_feat, format("%s=true;", c))
        else 
          insert(t_feat, format("%s=%s;", key, val)) 
        end
      else
        insert(t_feat, format("%s=%s;", key, val)) 
      end
    end
  end
  fea = concat(t_feat, "")
  -- According to fntguide, these should use the autoinst suffixes,
  -- but this makes things really awkward because then (mapping to 
  -- nfssext) we have
  --    LF      \plstyle
  --    TLF     \tlstyle
  --    OsF     \postyle
  --    TOsF    \tostyle
  -- But, as the font loader code points out, tnum and lnum are 
  -- supposed to be default, onum and pnum should be variants.
  -- So the above is very awkward to implement for opentype fonts.
  -- Nor does it make much sense in terms of historical norms, since
  -- LaTeX always uses tabular by default.
  -- And I really want the no-feature form to get no suffixes here
  -- as that seems much easier to understand, from a user perspective.
  -- Moreover, I really want these either split or Berry.
  -- Berry would be easier, but split does less violence to Frank's
  -- decrees, so let's see how that works.
  --      -prop   \pstyle   aka 2
  --      -osf    \ostyle   aka j
  -- autoinst doesn't give anything for subscript/superscript, but 
  -- uses Sup for superiors and Numr, Dnom for fractions.
  --      -subs   aka 0
  --      -sups   aka 1
  -- And we hereby decree, with no authority whatsoever that -prop
  -- precede -osf, following Berry, if both apply.
  if t_fea.sups then cat_suffix = "-sups" 
  elseif t_fea.subs then cat_suffix = "-subs"
  else
    -- prop before osf b/c 2j
    if t_fea.pnum then cat_suffix = "-prop" end
    if t_fea.onum then 
      cat_suffix = cat_suffix and format("%s-osf", cat_suffix) or "-osf"
    end
  end
  for _,i in ipairs(fea_lookup.figures) do t_fea[i] = nil end
  if t_fea.tlig  == "false" then insert(suffix, "-notlig") end
  if t_fea.liga  == "false" then insert(suffix, "-noliga") end
  t_fea.tlig = nil
  t_fea.liga = nil
  for key,val in sortedpairs(t_fea) do
    if val == "true" or val == "false" then
      insert(suffix, format("-%s%s", val == "true" and "" or "no", key))
    else
      insert(suffix, format("-%s:%s", key, val or ""))
    end
  end
  if #suffix > 0 then 
    suffix = concat(suffix, "")
    cat_suffix = cat_suffix and format("%s%s", cat_suffix, suffix) or suffix
  end
  return fea, cat_suffix
end
-- }}}
---@table features_lookup {{{
local features_lookup = {
  -- script    = {default = "dflt", latin = "ltn"},
  -- language  = {},
  alternates = {
    ["annotation"]        = function(val) 
      if type(val) == "string" then return format("+nalt=%d", tonumber(val)) end
      for i,v in ipairs(val) do val[i] = format("+nalt=%d", tonumber(v)) end
      return concat(val, ";")
    end,
    ["charactervariant"]  = function(val) 
      if type(val) == "string" then val = {val} end
      for n,v in ipairs(val) do
        local t = lpeg_match(Ct(splitat(p_colon,true)), v)
        for i,j in ipairs(t) do t[i] = tonumber(j) end
        val[n] = format("+cv%02d=%d", t[1] or 0, t[2] or 0)
      end
      return concat(val, ";")
    end,
    ["stylistic"]         = function(val) 
      if type(val) == "string" then return format("+salt=%d", tonumber(val)) end
      for i,v in ipairs(val) do val[i] = format("+salt=%d", tonumber(v)) end
      return concat(val, ";")
    end,
    ["sset"]              = function(val) 
      if type(val) == "string" then return format("+ss%02d", tonumber(val)) end
      for i,v in ipairs(val) do val[i] = format("+ss%02d", tonumber(v)) end
      return concat(val, ";")
    end,
    ["contextual"]        = "calt",
    ["contextualswash"]   = "cswh",
    ["linefinal"]         = "falt",
    ["wordfinal"]         = "fina",
    ["justification"]     = "jalt",
    -- The spec suggests this should take a number, but fontspec does it
    -- like this.
    ["swash"]             = "swsh",
  },
  figures  = {
    ["lining"]        = "lnum", 
    ["oldstyle"]      = "onum", 
    ["osf"]           = "onum", 
    ["prop"]          = "pnum", 
    ["proportional"]  = "pnum", 
    ["tab"]           = "tnum",
    ["tabular"]       = "tnum",
    ["superscript"]   = "sups",
    ["subscript"]     = "subs",
    ["zero"]          = "zero",
  },
  forms = {
    ["capstopetite"]  = "c2pc",
    ["capstosc"]      = "c2sc",
    ["case"]          = "case",
    ["hist"]          = "hist",
    ["historical"]    = "hist",
    ["random"]        = "rand",
    ["smalltopetite"] = "pcap",
    ["titling"]       = "titl",
    ["unicase"]       = "unic",
  },
  language    = {
    dflt          = "dflt",
  },
  ligatures  = {
    ["contextual"]    = "clig",
    ["discretionary"] = "dlig",
    ["hist"]          = "hlig",
    ["historic"]      = "hlig",
    ["required"]      = "rlig",
    ["standard"]      = "liga",
    ["tex"]           = "tlig",
  },
  mode       = {
    ["base"]          = "base",
    ["harf"]          = "harf",
    ["harfbuzz"]      = "harf",
    ["node"]          = "node",
  },
  script      = {
    dflt          = "dflt",
  },
  -- Use a metamethod here, probably?
  -- numbers    = fea_lookup.figures,
  spacings = {
    ["capsspacing"]   = "cpsp",
    ["kern"]          = "kern",
  },
}
-- }}}
---@function parse_features(t_fea,fea_type) {{{
---@param       t_fea     <table>
---@param       fea_type  <string>  (optional)
---@return      (string) <feature spec.>
---@description Turns a features kv list into a fea spec,
local function parse_features(t_fea,fea_type)
  if not t_fea then return nil end
  -- Paid â cheisio leihau nifer o dablau yma!!!
  local t_feat = {}
  local lookup = (fea_type and features_lookup[fea_type]) and 
    features_lookup[fea_type] or features_lookup
  -- sortedpairs for regression testing ...
  for key,val in sortedpairs(t_fea) do
    if key ~= "" then
      local nokey = (gsub(key, "^no", ""))
      local code = lookup[key]
      local nocode = lookup[nokey]
      if not code and nocode then
        code = nocode
        key = nokey
        val = "false"
      end
      if code and type(code) == "string" then
        insert(t_feat, format("%s=%s", code, val))
      elseif code then
        local tag = code(val)
        insert(t_feat, tag)
      else
        t_fea[key] = nil
        msg(concat({"Unknown key \'", key, "\' in ", fea_type or "features",
          ": ignoring"}, ""))
      end
    end
  end
  return concat(t_feat, ";")
end
-- }}}
--- }}}
-------------------------------------------------------------------------------
-- Manage font definition files, cache etc.
-- write_declare_shape()   write_fake_fd()   add_callback_smcp()
-- add_callback_data()  add_callback_cache()  file_subs_empty()
-- add_fake_fd() use_cached_fd()
-------------------------------------------------------------------------------
--- {{{

---@function write_declare_shape(fam, pre, line, post, fea [, size_spec]) {{{
---@param fam       <string>  for use in subs lines, should inc. suffix
---@param pre       <table>   of toks/strings e.g. \DeclareFontShape{<fam>}{<enc>}
---@param line      <table>   rep. font spec  e.g. {<series>}, {<shape>}, ... 
---@param post      <table>   of toks/strings e.g. {}
---@param fea       <string>  of features e.g. "mode=node;script=dflt;+tlig+"
---@param size_spec <string>  e.g. "<-5.0>" or "<->s*" etc.
---@Description Returns table of (tables of) toks/strings for a font shape
---@Description declaration. <line> may include ["sub"] or ["ssub"].
local function write_declare_shape(fam, pre, line, post, fea, size_spec) 

  msg({"Preparing line for ", fam, "."}, "debug")

  msg_assert(fam and pre and line and post, 
    "Partial or no spec to write. This should never happen!")

  -- fea should be a table?

  size_spec = size_spec or str_onesize

  local out = {pre}
  local kind = line[3] and type(line[3]) or nil

  if kind then
    if kind == "string" then
      fea = (line[5] ~= "") and format("%s%s;", fea, line[5]) or fea
    else
      msg_assert(kind == "table", {"Unexpected type ", kind, "!"})
      fea = line[4] ~= "" and format("%s%s;", fea, line[4]) or fea
    end
  end

  local function toks_font_spec(fnt, subfnt)
    return subfnt == 0 and { "\"[", fnt, "]:", fea, "\"" } or  
      { "\"[", fnt, "]:(", subfnt, ")", fea, "\"" }
  end

  -- series
  append(out, embrace(line[1]))
  -- shape
  append(out, embrace(line[2]))

  if line[3] then


    if kind == "string" then 

      -- Simple case: {<-> "[<path>]":           <features>"}
      --          or: {<-> "[<path>]":(<subfont>)<features>"}
      append(out, { tok_group_begin, size_spec, toks_font_spec(line[3], 
        line[4]), tok_group_end })

    else 

      -- Otherwise: {
      --              <min-max> "[<path>]":           <features>"
      --       (or)   <min-max> "[<path>]":(<subfont>)<features>"
      --              ...
      --             }
      insert(out, tok_group_begin)

      for _,item in ipairs(line[3]) do
        append(out, {item[1], toks_font_spec(item[2], item[3])}) 
      end

      insert(out, tok_group_end)
    end

  else
    -- Else we must have a substitution - silent or o/w.
    msg_assert(line.sub or line.ssub, "Malformed line!")
    local subst = line.sub or line.ssub

    append(out, {
      tok_group_begin, str_onesize, line.ssub and "ssub*" or "sub*",
      fam, "/", subst[1], "/", subst[2], tok_group_end })
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

      if lfc_cache.callbacks_smcp and lfc_cache.callbacks_smcp[path] then

        msg("Processing smcp callback ...", "info")
        msg({"Path:\t", path}, "debug")
        msg({"Spec:\t", spec}, "debug")
        msg({"Id:\t", id}, "debug")
        local fam = lfc_cache.callbacks_smcp[path].fam
        local incomplete = lfc_cache.incomplete 
        local fake_fd 
        if lfc_cache[fam] and lfc_cache[fam].fake_fd then 
          fake_fd = lfc_cache[fam].fake_fd end

        for line_no,_ in pairs(lfc_cache.callbacks_smcp[path]) do
          if line_no == "fam" or line_no == "related" then goto not_line_ref end

          if incomplete and incomplete[fam] and incomplete[fam][line_no] then

            msg({"Completing ", fam, "..."}, "log")

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
local function add_callback_data()
  if lfc_callback_data_active then
    msg("Callback already active.", "debug")
  end
  msg("Adding data callback.", "info")
  luatexbase.add_to_callback(
    "luaotfload.patch_font",
    function(data, spec, id)
      local path = data.filename

      if not lfc_cache.resources[path] then

        msg("Processing data callback ...", "info")
        msg({"Path:\t", path}, "debug")
        msg({"Spec:\t", spec}, "debug")
        msg({"Id:\t", id}, "debug")

        lfc_cache.resources[path] = {}
        local cached = lfc_cache.resources[path]
        cached.features = cached.features or {}
        local fea = cached.features

        local rfea = data.resources.features
        
        fea.gsub = rfea.gsub and {} or nil
        if fea.gsub then
          for _,i in ipairs({"tnum", "lnum", "onum", "pnum", "smcp", "subs",
            "sups"}) do
            fea.gsub[i] = rfea.gsub[i] and true or false
          end
        else
          fea.gsub = false
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

---@function write_fake_fd(fam, fake_fd, fea, scale_factor, suffix[, cfg_scoped]) {{{
---@param fam:            <string>  NFSS family
---@param fake_fd:        <table>   If not cached
---@param fea:            <string>  Features
---@param scale_factor:   <number>  Scaling factor
---@param suffix:         <string>  Suffix for NFSS family
---@param cfg_scoped:     <table>   Special feature configs (if required)
---@description fake_fd should not be nil unless something has gone wrong.
---@description This should never happen in the automated case.
-- Cache format: see above
local function write_fake_fd(fam, fake_fd, fea, scale_factor, suffix, cfg_scoped)
  msg({"Emulating font definition file for NFSS family ", fam, " with ",
    fea, " scaled ", scale_factor or "1", " suffixed ", suffix or "[none]",
    cfg_scoped and " with special configs." or "."}, "log")

  suffix = suffix ~= "" and suffix or nil
  scale_factor = (scale_factor and scale_factor ~= 1) and scale_factor or nil

  -- Note this **DEPENDS** on b preceding o when sorted ....
  local fake_lookup = {
    ["fakebold"]    = {"b","*", function(curr, val) 
      return concat({curr, "embolden=", val, ";"}, "") end},
    ["fakeoblique"] = {"*","sl", function(curr, val) 
      return concat({curr, "slant=", val, ";"}, "") end},
  }
  if cfg_scoped and cfg_scoped.fake then
    local t = {}
    for no,line in ipairs(fake_fd) do
      if line ~= "" then
        t[line[1]] = t[line[1]] or {}
        t[line[1]][line[2]] = no
      end
    end
    for fake,value in sortedpairs(cfg_scoped.fake) do
      -- t must be updated when changes are made to ensure that e.g. bold oblique is faked.
      local lookup = fake_lookup[fake]
      if lookup then
        if lookup[1] ~= "*" and not t[lookup[1]] then
          local newlines = t.m and t.m or (t.k and t.k or (t.f and t.f or nil))
          if newlines then
            t[lookup[1]] = {}
            for shape,newline in pairs(newlines) do
              local l = fastcopy(fake_fd[newline])
              local base = l[1]
              l[1] = lookup[1]
              if l.ssub and l.ssub[1] == base then
                l.ssub[1] = lookup[1]
              end
              insert(fake_fd, l)
              t[lookup[1]][shape] = #fake_fd
            end
            local hash = format("%s:%s", lookup[1], lookup[2])
            cfg_scoped[hash] = cfg_scoped[hash] or {}
            cfg_scoped[hash].fea = lookup[3](cfg_scoped[hash].fea or "", value)
          else
            msg({"Sorry, but I cannot make ", fake, " as I can't find a base series."})
          end
        elseif lookup[2] ~= "*" then
          for series,shapes in pairs(t) do
            local no
            if shapes[lookup[2]] then
              local l = fake_fd[shapes[lookup[2]]]
              if l.ssub then
                no = shapes[lookup[2]]
              end
            elseif not shapes[lookup[2]] then
              no = #fake_fd + 1
            end
            if no then
              if shapes.n then
                local l = fastcopy(fake_fd[shapes.n])
                l[2] = lookup[2]
                fake_fd[no] = l
                local hash = format("%s:%s", series, lookup[2])
                cfg_scoped[hash] = cfg_scoped[hash] or {}
                cfg_scoped[hash].fea = lookup[3](cfg_scoped[hash].fea or "", value)
                t[series][lookup[2]] = no
              else
                msg({"Sorry, but I cannot make ", fake, " without a base shape."})
              end
            end
          end
        end
      else
        msg({"Sorry. I do not know how to make ", fake, "."})
      end
    end
  end

  local use_name = suffix and format("%s%s", fam, suffix) or fam
  local pre = {fastcopy(toks_enc_tu), embrace(use_name)}
  local out = {
    tok_declare_fam, fastcopy(pre), toks_empty_n
  }
  insert(pre, 1, tok_declare_shape)

  local onesize = str_onesize
  if scale_factor then
    if lfc_cache[fam].scalable then
      msg({"Scaling ", use_name, " to ", scale_factor, "."}, "info")
      onesize = concat({onesize, "s*[", scale_factor, "]"}, "")
    else
      msg("Ignoring scaling factor for fonts with optical sizes.")
    end
  end

  local typeset_mode = lfc_cache[fam].typeset_mode or 0

  for _,line in ipairs(fake_fd) do
    if line ~= "" then 
      msg({"Preparing line: ", use_name, ": ", fea, " ", onesize}, "debug")
      local fea = fea
      if cfg_scoped then
        local scope_hash_series = concat({line[1], ":*"}, "")
        local scope_hash_shape = concat({"*:", line[2]}, "")
        local scope_hash = concat({line[1], line[2]}, ":")
        for _,h in ipairs({scope_hash_series, scope_hash_shape, scope_hash}) do
          if cfg_scoped[h] then
            local cfg = cfg_scoped[h]
            fea = cfg.fea and concat({fea or "", cfg.fea}, "") or fea
          end 
        end
      end
      msg_debug("Concatenated fea: ", "defn", fea)
      msg_debug(" ... for line: ", "defn", line)
      append(out, write_declare_shape(use_name, pre, line, toks_empty_n, fea, 
        onesize))
    end
  end

  -- Requires lua-unicode-math.
  -- No suffix for maths, so fam is OK here.
  if typeset_mode == 1 and not find(fam, "%-sf$") and not find (fam, "%-ssf$") then
    append(out, {tok_declare_m_scr_map, toks_enc_tu, embrace(fam),
      toks_enc_tu, embrace(format("%s-sf", fam)), toks_enc_tu, embrace(format("%s-ssf", fam))})
  end

  msg_debug("Out (partially tokenized): ", "defn", out)
  out = flattened({out})
  msg_debug("Out (streamed): ", "defn", out)
  sprint(-2,out)

  if typeset_mode == 0 then

    -- text may be incomplete

    if not lfc_cache[fam].complete and not lfc_callback_smcp_active then
      add_callback_smcp()
    end

    msg_assert(lfc_cache[fam].paths, {"No paths cached for ", fam, "!"}, "debug")

    if not lfc_callback_data_active then
      for _,path in ipairs(lfc_cache[fam].paths) do
        if not lfc_cache.resources[path] then
          add_callback_data()
          break
        end
      end
    end

  end
end
-- }}}

---@function function file_subs_empty(filename) {{{
---@param       <string> filename (with any extension; no path)
---@description Substitutes the `.tex` file for <filename> using the LaTeX fn.
local function file_subs_empty(filename)
  return sprint(-2, flattened({tok_file_subs, embrace(filename), 
    toks_file_empty}))
end
-- }}}

---@function add_fake_fd(fam, fake_fd, fea, scale_factor, suffix, cfg_scoped) {{{
---@see         write_fake_fd()
---@description A wrapper around write_fake_fd() which avoids defining fonts
---@description   unnecessarily (and so avoids unnecessary callbacks etc.).
local function add_fake_fd(fam, fake_fd, fea, scale_factor, suffix, cfg_scoped)
  local fd_filename = suffix and format("tu%s%s.fd", fam, suffix) or format("tu%s.fd", fam)
  local fn = format("__lfc_%s", fd_filename)
  luafunction_to_cs(fn, function ()
    return write_fake_fd(fam, fake_fd, fea, scale_factor, suffix, cfg_scoped)
  end, "protected")
  fn = create(fn)
  file_subs_empty(fd_filename)
  sprint(-2, flattened({tok_hook_gput_code, tok_group_begin, 
    hook_file_before(fd_filename), tok_group_end, toks_dot, embrace(fn)}))
end
-- }}}

---@function use_cached_fd(fam, fea, scale, now, suffix[, cfg_scoped]) {{{
---@param fam        <string>   Name of a cached meta-family.
---@param fea        <string>   Font features.
---@param scale      <numeric>  Potential scaling factor or nil.
---@param now        <boolean>  Whether to write defns or setup hook.
---@param suffix     <string>   Family suffix.
---@param cfg_scoped <table>    Special configs, If required.
local function use_cached_fd(fam, fea, scale, now, suffix, cfg_scoped) 
  msg_assert(lfc_cache[fam] and lfc_cache[fam].fake_fd,
    "Cache failure. Try removing the cache before recompiling.")
  msg({"Using cached fd emulation for ", fam, "."}, "debug")

  msg_debug("Cached fd:\n", "cache", lfc_cache[fam].fake_fd)
  if now then
    return write_fake_fd(fam, lfc_cache[fam].fake_fd, fea, scale, suffix, cfg_scoped) 
  else
    return add_fake_fd(fam, lfc_cache[fam].fake_fd, fea, scale, suffix, cfg_scoped) 
  end
end
-- }}}

--- }}}
-------------------------------------------------------------------------------
-- Main configuration function & auxiliaries 
-- font_config_aux()  font_config()
-------------------------------------------------------------------------------
---@function font_config_aux(fam, config, typeset_mode) {{{
---@param   fam           <string>  family name
---@param   config        <table>   overall config passed/created/modified 
---                                   to/by font_config()
---@param   typeset_mode  <int>     0 (text) or 1 (math)
---@description Returns configured features (string), scale (number) or 1, 
---@description   suffix (string) or "" and cfg_scoped (table) or nil
---@description These may be passed more-or-less as-is to the writing 
---@description   functions.
local function font_config_aux(fam, config, typeset_mode)

  local scale = (config[fam] and config[fam].scale and config[fam].scale) or
    (config.scale and config.scale) or 1

  local fea = (config[fam] and config[fam].fea and config[fam].fea) or
    (config.fea and config.fea) or nil

  local suffix
  if typeset_mode == 0 and fea then fea, suffix = parse_fea(fea) 
  else 
    fea = typeset_mode ~= 1 and str_fea_default or str_fea_math_default
  end
  msg_assert(fea ~= nil, "fea should never be nil!")

  local cfg_scoped = (config[fam] and config[fam].cfg_scoped and
    config[fam].cfg_scoped) or (config.cfg_scoped and config.cfg_scoped)
    or nil
  if cfg_scoped then
    for this,cfg_scope in ipairs(cfg_scoped) do
      if cfg_scope.fea then
        cfg_scope.fea, discard = parse_fea(cfg_scope.fea)
      else
        -- Discard do-nothing entries.
        cfg_scoped[this] = nil
      end
    end
  end

  return fea, scale, suffix or "", cfg_scoped
end
-- }}}

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
  local meta_suffix

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
      msg_debug("font_config() :: NFSSify " .. name, "data", font)

      local fullname = font.fullname
      -- text: 0 ; maths: 1; other: 2
      local typeset_mode = 0
      
      -- Best would be to check for the MATH table, but we don't want to
      --    load every font for that, so do this for now.
      if find(fullname, "math") and not (find(fullname, "mathematica") 
        or find(fullname, "cyrillic")) then typeset_mode = 1 end

      local width = font.width
      local weight = font.weight
      local fontweight = font.fontweight
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
        if fontweight then family = (gsub(family, fontweight, "")) end
        family = (gsub(family, width, ""))

        if style == "oblique" or style == "slanted" then
          family = (gsub((gsub(family, "oblique", "")), "slanted", ""))
        end

        if variant == "smallcaps" then
          family = (gsub(family, "caps", ""))
          family = (gsub(family, "sc", ""))
        end

        -- For latin modern roman unslanted, which claims to be perfectly ‘normal’
        if (find(family, "unslanted")) then
          msg_debug("Found \'unslanted\' in family name.", "data", family)

          family = (gsub(family, "unslanted", ""))
          if (style == "normal" or style == "regular") and variant == "normal" then
            style = "uprightitalic"
          end

          msg({name, ": family -> ", family, "; style -> ", style, "."}, "debug")

        end

      end

      parsed_fam = parsed_fam or {}
      parsed_fam[family] = parsed_fam[family] or {}
      local t = parsed_fam[family]

      if weight == "normal" then
        if fontweight then
          if fontweight == "regular" then
            regular = true
            weight = fontweight
          elseif fontweight == "book" then 
            book = true
            weight = fontweight
          elseif  fontweight == "medium" then 
            medium = true
            weight = fontweight
          end
        end
      end

      -- translate to NFSS identifiers (texdoc fntguide)
      local nfss_weight   = parse_spec(weights, weight)
      local nfss_width    = parse_spec(widths, width)
      local nfss_style    = parse_spec(styles, style)
      local nfss_variant  = parse_spec(variants, variant)

      series  = parse_nfss(nfss_weight, nfss_width, "m")
      shape   = parse_nfss(nfss_variant, nfss_style, "n")

      -- Hash is <family>:<series>:<shape>[<minsize>:<maxsize>]
      local nfss_hash = format("%s:%s:%s%s%s", family, series, shape, 
        font.minsize ~= nil and format(":%s", font.minsize) or "", 
        font.maxsize ~= nil and format(":%s", font.maxsize) or "")

      font.series = series
      font.shape = shape
      font.nfss_hash = nfss_hash
      font.nfss_family = family
      font.typeset_mode = typeset_mode
      
      nfss_hashes[family] = nfss_hashes[family] or {}
      nfss_hashes[family][nfss_hash] = nfss_hashes[family][nfss_hash] or 0
      nfss_hashes[family][nfss_hash] = nfss_hashes[family][nfss_hash] + 1

      t[series] = t[series] or {}
      t[series][shape] = t[series][shape] or {}

      insert(t[series][shape], font)

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
    -- (6) 1. book    :-> k (non-standard)
    --        medium  :-> f (arbitrary)
    --        regular :-> m
    --     2. ~(\exists x) (m = x) --> ((\exists x} (k = x) --> (k :-> m))
    --     3. ~(\exists x) (m = x) --> ((\exists x} (f = x) --> (f :-> m))

    -- Nowadays so many fonts distinguish these ...
    
    for fam,data in pairs(parsed_fam) do
      if not data.m then
        if data.k then
          data.m = data.k
          data.k = nil
        elseif data.f then
          data.m = data.f
          data.f = nil
        end
      end
    end

    -- link families to fam_meta

    lfc_cache.meta_families.by_meta_fam[fam_meta] = {}
    local by_meta_fam = lfc_cache.meta_families.by_meta_fam[fam_meta]


    for fam,fam_data in pairs(parsed_fam) do

      local typeset_mode
      for series,shapes in pairs(fam_data) do
        for shape,fnts in pairs(shapes) do
          typeset_mode = fnts[1].typeset_mode
          break
        end
      end

      local fam_sf, fam_ssf, by_meta_math
      if typeset_mode == 1 then 
        fam_sf, fam_ssf = format("%s-sf", fam), format("%s-ssf", fam) 
      end

      local fake_fd, fake_fd_sf, fake_fd_ssf
      -- Obviously, this is a stupid way to do this ....
      -- Probably better to get the data back from the cache or return a
      --    keyed table?
      local f1, f2, f3 = prepare_fake_fd(fam, fam_data, typeset_mode)
      if not f2 then fake_fd = f1
      else
        for _,fd in ipairs({f1,f2,f3}) do
          for _,line in ipairs(fd) do
            local fs = line[5] or line[4]
            if not fs then goto maybe end
            if fs == "" then fake_fd = fd
            elseif find(fs, str_fea_math_sf) then fake_fd_sf = fd
            elseif find(fs, str_fea_math_ssf) then fake_fd_ssf = fd
            end
            break
            :: maybe ::
          end
        end
        msg_assert(fake_fd and fake_fd_sf and fake_fd_ssf, "Mismatching maths \z
          families!")
      end

      if fake_fd then
        insert(by_meta_fam, fam)

        if typeset_mode == 1 then 
          msg_assert(fake_fd_sf and fake_fd_ssf, 
            "Missing script and scriptscript!")
          lfc_cache.meta_families.by_meta_math[fam] = {
            fam, fam_sf, fam_ssf
          }
        end


        local fea, scale, suffix, cfg_scoped = 
          font_config_aux(fam, config, typeset_mode)


        if immediate then
          write_fake_fd(fam, fake_fd, fea, scale, suffix, cfg_scoped) 

          if fake_fd_sf then 
            write_fake_fd(fam_sf, fake_fd_sf, fea, scale, suffix, cfg_scoped) 
          end
          if fake_fd_ssf then 
            write_fake_fd(fam_ssf, fake_fd_ssf, fea, scale, suffix, cfg_scoped)
          end
        else
          add_fake_fd(fam, fake_fd, fea, scale, suffix, cfg_scoped)

          if fake_fd_sf then 
            add_fake_fd(fam_sf, fake_fd_sf, fea, scale, suffix, cfg_scoped)
          end
          if fake_fd_ssf then 
            add_fake_fd(fam_ssf, fake_fd_ssf, fea, scale, suffix, cfg_scoped)
          end
        end

        suffix = suffix ~= "" and suffix or nil

        -- Need a different way to handle this.
        -- It shouldn't be disconnected this way.
        if suffix and fam_meta == fam then meta_suffix = suffix end
      end

    end

    if not lfc_callback_cache_active then add_callback_cache() end

  else

    local by_meta_fam = lfc_cache.meta_families.by_meta_fam[fam_meta]
    local all_math = false
    if not by_meta_fam then
      by_meta_fam = lfc_cache.meta_families.by_meta_math[fam_meta]
      all_math = true
    end

    if not all_math then
      for _,fam in ipairs(by_meta_fam) do

        local typeset_mode = lfc_cache[fam].typeset_mode


        local fea, scale, suffix, cfg_scoped = 
          font_config_aux(fam, config, typeset_mode)


        if typeset_mode ~= 1 then
          use_cached_fd(fam, fea, scale, immediate, suffix, cfg_scoped) 
        else
          -- Pick up the additional maths fds.
          local meta_math = lfc_cache.meta_families.by_meta_math[fam]
          msg_assert(meta_math, "Missing meta math from cache!")
          for _,mfam in ipairs(meta_math) do
            use_cached_fd(mfam, fea, scale, immediate, suffix, cfg_scoped) 
          end
        end

        suffix = suffix ~= "" and suffix or nil

        -- Need a different way to handle this.
        -- It shouldn't be disconnected this way.
        if suffix and fam_meta == fam then meta_suffix = suffix end
      end
    else
      for _,fam in ipairs(by_meta_fam) do
        -- Not sure if scale is really appropriate here.
        local scale = (config[fam] and config[fam].scale and 
          config[fam].scale) or (config.scale and config.scale) or 1

        use_cached_fd(fam, str_fea_math_default, scale, immediate, "", nil)
      end
    end

  end

  if meta_suffix then fam_meta = format("%s%s", fam_meta, meta_suffix) end
  return fam_meta
end
-- }}}

-------------------------------------------------------------------------------
-- LaTeX interface things
-- do_with_<one|two|three>_scanner()
-- get_fam_default_scanner()  get_fam_name_scanner()  get_fam_cfg_scanner()
-- get_fam_scoped_fea_scanner()         get_fam_features_scanner()
-- configure_doc_families()
-- \__lfc_set_rm:n    \__lfc_set_sf:n   \__lfc_set_tt:n   \__lfc_set_math:n
-- \__lfc_set_fam_name:n                \__lfc_set_fam_cfg:nn   
-- \__lfc_set_fam_scoped_fea:nn         \__lfc_set_fam_features:nnn
-- \__lfc_configure_doc_families:
-- parse_spec_scanner()                 \__lfc_parse_spec:nn
-- parse_nfss_scanner()                 \__lfc_parse_nfss:nnn
-- tables: fam_defaults, fam_to_maths
-- \__lfc_set_log_level:n \__lfc_debug_set_true:  \__lfc_debug_set_false:
-- \__lfc_debug_set_cats_scanner:n
-------------------------------------------------------------------------------
--- {{{
-- Scanners for 1, 2 or 3 arguments.
-- {{{
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
---@param fn    <function>  Function to execute on arguments.
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

---@function do_with_three_scanner(fn) {{{
---@param fn    <function>  Function to execute on arguments.
---@description Returns a function which picks up and does something with
---@description   three TeX arguments.
local function do_with_three_scanner(fn)
  return function()
    local one = param(false)
    local two = param(false)
    local three = param(false)
    msg({"Scanned three: ", one, " | ", two, " | ", three}, "debug")
    return fn(one, two, three)
  end
end
-- }}}
-- }}}

-- Lookup tables for default text families, text families in maths mode.
-- {{{
local fam_defaults = { -- {{{
  rm = tok_rmdefault,
  sf = tok_sfdefault,
  tt = tok_ttdefault,
}
-- }}}

local fam_to_maths = { -- {{{
  rm = tok_mathrm,
  sf = tok_mathsf,
  tt = tok_mathtt,
}
-- }}}
-- }}}

local nfss_doc_families_cnt = 0

-- Scanner creators.
-- {{{
---@function get_fam_default_scanner(fam) {{{
---@param fam   <string: "rm" | "sf" | "tt">  NFSS default family.
---@description Returns a Lua function which scans an argument and sets the
---@description   specified family default to the given value.
local function get_fam_default_scanner(fam) 
  return do_with_one_scanner(
    function(fam_name)
      local cleanname = cleanfilename(fam_name)
      nfss_doc_families_cnt = nfss_doc_families_cnt + 1
      local t_name = concat({cleanname, nfss_doc_families_cnt}, "_")
      nfss_doc_families[t_name] = {
        name = tostring(fam_name),
        cleanname = cleanname,
        default = {fam},
      }
      nfss_doc_families[t_name].typeset_mode = fam ~= "math" and 0 or 1
      nfss_default_families[fam] = nfss_doc_families[t_name]
      nfss_doc_families.curr = t_name
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
      nfss_doc_families_cnt = nfss_doc_families_cnt + 1
      local t_name = concat({cleanname, nfss_doc_families_cnt}, "_")
      nfss_doc_families[t_name] = {
        name = tostring(name),
        cleanname = cleanname,
      }
      nfss_doc_families.curr = t_name
      msg_debug("NFSS doc families: ", "doc", nfss_doc_families)
    end)
end
-- }}}

---@function get_fam_cfg_scanner() {{{
---@description Returns a function which takes a param/val specification and 
---@description stores it.
local function get_fam_cfg_scanner()
  return do_with_two_scanner(
    function(key, value)
      local curr = nfss_doc_families.curr
      msg_assert(curr ~= nil, "No current family to set parameters for!")
      curr = nfss_doc_families[curr]
      if find(key, "^fake") then
        curr.cfg_scoped = curr.cfg_scoped or {}
        curr.cfg_scoped.fake = curr.cfg_scoped.fake or {}
        curr.cfg_scoped.fake[key] = value
      elseif key ~= "fea" then
        curr[key] = lower(tostring(value))
      else
        curr.fea = format("%s%s;", curr.fea or "", lower(tostring(value)))
      end
      msg_debug("Scanned (std/late) family configuration: ", "doc", curr)
    end)
end
-- }}}

---@function get_fam_scoped_fea_scanner() {{{
---@description scope: {<series or *>, <shape or *>}
---@description Returns a function which takes a scope/fea specification and 
---@description stores it.
local function get_fam_scoped_fea_scanner()
  return do_with_two_scanner(
    function(scope_hash, value)
      local curr = nfss_doc_families.curr
      msg_assert(curr ~= nil, "No current family to set parameters for!")
      curr = nfss_doc_families[curr]

      curr.cfg_scoped = curr.cfg_scoped or {}
      local cfg = curr.cfg_scoped[scope_hash] or nil
      if not cfg then
        curr.cfg_scoped[scope_hash] = {}
        cfg = curr.cfg_scoped[scope_hash]
      end

      if not cfg.fea then
        cfg.fea = format("%s;", lower(tostring(value)))
      else
        cfg.fea = format("%s%s;", cfg.fea, lower(tostring(value)))
      end

      msg_debug("Scanned scoped (std/late) font configuration: ", "doc",
        nfss_doc_families[curr])
    end)
end
-- }}}

---@function get_fam_features_scanner() {{{
---@description Returns a function which takes a key-val specification, 
---@description   turns it into a fea spec and stores it.
local function get_fam_features_scanner()
  return do_with_three_scanner(
    function(scope_hash, fea_type, list)
      local curr = nfss_doc_families.curr
      msg_assert(curr ~= nil, "No current family to set features for!")
      curr = nfss_doc_families[curr]

      local cfg
      if scope_hash == "*:*" then
        curr.fea = curr.fea or str_fea_default
        cfg = curr
      else
        curr.cfg_scoped = curr.cfg_scoped or {}
        cfg = curr.cfg_scoped[scope_hash] or nil
        if not cfg then
          curr.cfg_scoped[scope_hash] = {}
          cfg = curr.cfg_scoped[scope_hash]
        end
      end

      if fea_type == "" then fea_type = nil end
      list = checkedsplit(",", lpeg_match(stripper(p_whitespace),
        lower(tostring(list))))
      local t = {}
      for i,j in ipairs(list) do
        list[i] = lpeg_match(Ct(splitat(p_equal,true)), j)
        local tag, value = list[i][1] or j, list[i][2] or "true"
        if tag and tag ~= "" then 
          if not t[tag] or value == "true" or value == "false" then
            t[tag] = value 
          elseif type(t[tag]) == "table" then
            insert(t[tag], value)
          else
            t[tag] = {t[tag], value}
          end
        end
      end
      local feas = parse_features(t, fea_type)
      if feas and feas ~= "" then
        cfg.fea = format("%s%s;", cfg.fea or "", feas)
      end
      msg_debug(concat({"Scanned kv features family configuration", scope_hash and " "
        or "", scope_hash or "", ": "}), "doc", nfss_doc_families[curr], key)
    end)
end
-- }}}
-- }}}

-- Configuration function.
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
    local config = {fea = nil, scale = nil, force = nil, typeset_mode = nil}
    for t_name,cfg in sortedpairs(nfss_doc_families) do
      if t_name ~= "curr" then
        if cfg.features then -- is this ever true?
          if cfg.fea then
            cfg.fea = format("%s%s;", cfg.fea, concat(cfg.features, ";"))
          else
            cfg.fea = format("%s;", concat(cfg.features, ";"))
          end
        end
        config.fea = cfg.fea or nil
        config.scale = cfg.scale or nil
        config.force = cfg.force or nil
        config.cfg_scoped = cfg.cfg_scoped or nil

        -- text: 0, maths: 1
        config.typeset_mode = cfg.typeset_mode or 0

        local nfss_fam = font_config(cfg.name, config, cfg.default and true or 
        false)

        if nfss_fam ~= nil then 
          cfg.nfss_fam = nfss_fam

          if config.typeset_mode == 0 then
          -- text mode
            if not cfg.default then
              msg({"Creating NFSS family ", nfss_fam}, "debug")
              luafunction_to_cs(cfg.csname or cfg.cleanname, function()
                return sprint(-2, flattened({tok_fontfamily, embrace(nfss_fam),
                tok_selectfont}), "protected")
              end)
            end

          -- Support specific maths families?
          -- elseif cfg.typeset_mode == 1 then

          end

        else
          msg({"No family found for ", cfg.name, "!"}, "warn") 
          nfss_doc_families[t_name] = nil
        end
      end
    end
    msg_debug("NFSS doc families: ", "doc", nfss_doc_families)
    msg("Setting default families ...", "debug") 
    for fam,cfg in sortedpairs(nfss_default_families) do
      if cfg.nfss_fam then
        local fam_name = cfg.nfss_fam
        if cfg.typeset_mode == 0 then
          -- Use of text fonts in maths mode.
          local maths = cfg.maths or true
          msg({"Setting ", fam, " default to ", fam_name, "."}, "log")
          sprint(-2, flattened({tok_renewcommand, fam_defaults[fam], embrace(fam_name)}))
          if maths then
            msg({"Setting math", fam, "."}, "log")
            sprint(-2, fam_to_maths[fam])
          end
        elseif cfg.typeset_mode == 1 then
          -- Use of Unicode maths fonts in maths mode.
          -- This assumes lua-unicode-math.
          msg({"Setting main maths fonts to ", fam_name, "."}, "log")
          sprint(-2, flattened({tok_declare_lum_fnts, embrace(fam_name), 
            embrace(fam_name)}))
        end
      else msg({"No family found for ", fam, "!"})
      end
    end
    -- Discard data to avoid duplicating configuration if called again.
    nfss_doc_families = {}
    nfss_default_families = {}
  end
end
-- }}}

-- Generate TeX macros to use Lua functions to set rm, sf and tt.
-- {{{
luafunction_to_cs("__lfc_set_rm:n",   get_fam_default_scanner("rm"))
luafunction_to_cs("__lfc_set_sf:n",   get_fam_default_scanner("sf"))
luafunction_to_cs("__lfc_set_tt:n",   get_fam_default_scanner("tt"))
luafunction_to_cs("__lfc_set_math:n", get_fam_default_scanner("math"))
-- }}}

-- Scanners for additional family names, a general one for features, and specifics one for scoped features and the features key-value interface.
-- {{{
luafunction_to_cs("__lfc_set_fam_name:n", get_fam_name_scanner())
luafunction_to_cs("__lfc_set_fam_cfg:nn", get_fam_cfg_scanner())
luafunction_to_cs("__lfc_set_fam_scoped_fea:nn", get_fam_scoped_fea_scanner())
luafunction_to_cs("__lfc_set_fam_features:nnn", get_fam_features_scanner())
-- }}}

-- A macro to actually configure the font families.
luafunction_to_cs("__lfc_configure_doc_families:", configure_doc_families())

-- Auxiliary utility functions.
-- Reuse fn. rather than messing about with complicated sequence lookups in LaTeX.
-- This simplifies the key-val code, but erroneous input is left there (for now).
---@function parse_spec_scanner() {{{
local function parse_spec_scanner()
  return do_with_two_scanner(function(kind,descriptor)
    local kinds = {
      ["case"]    = variants,
      ["shape"]   = shapes,
      ["weight"]  = weights,
      ["width"]   = widths
    }
    return sprint(-2, parse_spec(kinds[kind],descriptor))
  end)
end
-- }}}
luafunction_to_cs("__lfc_parse_spec:nn", parse_spec_scanner())

luafunction_to_cs("__lfc_parse_series:nn", 
  do_with_two_scanner(function(weight,width)
    weight = lower(weight)
    width = lower(width)
    return sprint(-2, parse_nfss(weights[weight] or "m", widths[width] or "m", "m"))
  end)
)

---@function get_log_level_scanner() {{{
local function get_log_level_scanner()
  return do_with_one_scanner(
    function(level)
      -- Make sure these are set as used all over.
      lfc_log_level = msg_level[level] and level or lfc_log_level
      lfc_debug = (lfc_log_level == "debug") and true or false
      -- Note this will set all cats true if "debug".
      return msg_config(lfc_log_level, { state = lfc_debug })
    end)
end
-- }}}

-- An expl3 function to set the log level.
luafunction_to_cs("__lfc_set_log_level:n", get_log_level_scanner())

---@function get_cats_scanner() {{{
local function get_cats_scanner()
  return do_with_one_scanner(
    function(cats)
      local t = lpeg_match(Ct(splitat(p_comma,false)), cats)
      for n,i in ipairs(t) do 
        if i == "" then t[n] = nil
        else
          t[n] = lpeg_match(stripper(p_space), i) 
          t[i] = nil
        end
      end
      local h = tohash(t)
      return msg_config(lfc_log_level, {
        state = lfc_debug and true or false,
        categories = h,
      })
    end)
end
-- }}}

-- Macros to toggle debugging.
luafunction_to_cs("__lfc_debug_set_true:", function() 
  lfc_debug = true 
  lfc_log_level = "debug"
end)
luafunction_to_cs("__lfc_debug_set_false:", function() 
  lfc_debug = false 
  lfc_log_level = (lfc_log_level == "debug") and "info" or lfc_log_level
end)
luafunction_to_cs("__lfc_debug_set_cats_scanner:n", get_cats_scanner())

--- }}}
-------------------------------------------------------------------------------
-- Setup on load
-------------------------------------------------------------------------------
-- {{{
local cache_path = get_cache_path()
lfc_cache = read_cache()
-- }}}

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-- vim: et:foldmethod=marker:
