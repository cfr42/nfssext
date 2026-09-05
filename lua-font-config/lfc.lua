-- $Id: lfc.lua 12023 2026-09-05 03:57:58Z cfrees $
-------------------------------------------------------------------------------

lfc = {}
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Max Chernoff: https://chat.stackexchange.com/transcript/message/69175678#69175678
-- Use ConTeXt's font name database code.
-------------------------------------------------------------------------------

-- Define a new private environment into which to load "font-syn.lua".
local lfc_env = table.copy(luaotfload.fontloader)
lfc_env.table = table.copy(lfc_env.table)

-- Define some functions required by "font-syn.lua".
local match = string.match
local split = "^(.-)([^/]-)([^/]-)$"

function lfc_env.resolvers.dowithfilesintree(pattern, handle, before, after)
  local files = luaotfload.aux.font_index().files.full
  for i = 1, #files do
    local filename = files[i]
    if match(filename, pattern) then
      local root, path, name = match(filename, split)
      handle("file", root, path, name)
    end
  end
end

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
-- local paths = {}
--
-- do
--   local files = luaotfload.aux.font_index().files
--   for _, key in ipairs(config.luaotfload.db.location_precedence) do
--     for file, index in pairs(files.base[key]) do
--       paths[cleanfilename(file)] = files.full[index]
--     end
--   end
-- end
--
-- Public exports.
_G.lfc = _G.lfc or {}

local insert = table.insert
-- local function search_family(family_name)
--   family_name = lfc_env.fonts.names.cleanname(family_name)
--   local font = lfc_env.fonts.names.data.families[family_name]
--
--   if font then
--     local output = {}
--     for _, data in pairs(font) do
--       insert(output, {
--         family = data.familyname or family_name,
--         path   = paths[cleanfilename(data.filename)],
--         style  = data.style == "normal" and "upright" or data.style,
--         type   = data.format,
--         weight = data.weight == "normal" and "regular" or data.weight,
--         width  = data.width,
--       })
--     end
--     return output
--   else
--     return {}
--   end
-- end
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-- print("**** lfc_env ****")
-- for i,j in pairs(lfc_env) do print(i,type(i),j,type(j)) end
-- print("*****************")
--
-- print("**** lfc_env.fonts ****")
-- for i,j in pairs(lfc_env.fonts) do print(i,type(i),j,type(j)) end
-- print("*****************")

-- print("**** lfc_env.fonts.handlers.otf.readers ****")
-- getinfo (fn) helpers (table)
-- for i,j in pairs(lfc_env.fonts.handlers.otf.readers.helpers) do print(i,type(i),j,type(j)) end
-- print("*****************")

-- print("**** lfc_env.fonts.names.data ****")
-- for i,j in pairs(lfc_env.fonts.names.data) do print(i,type(i),j,type(j)) end
-- print("*****************")

local fonts = lfc_env.fonts
local names = fonts.names
local resolve = names.resolve
-- local resolvespec = names.resolvespec
-- local cleanname = names.cleanname
-- local cleanfilename = names.cleanfilename
-- local lookup = names.lookup
-- local lookup_fullpath = names.lookup_fullpath
local lookup_font_file = names.lookup_font_file
-- local sanitize_fontname = names.sanitize_fontname
-- local getmetadata = names.getmetadata
-- -- local getfilename = names.getfilename -- broken
local font_data = names.data
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-- Resolves a font specification and turns the family name into
--    an .fd file name
-- If the file exists, records this and returns the metadata
-- If not, returns a table of font data, too
local function get_font_data(fnt, suffix, force) -- {{{
  if fnt == nil then return nil end
  suffix = suffix or ""

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

  local fd = "tu" .. fam_meta .. suffix .. ".fd", "tex"
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


  -- SCRATCH

  -- print("*********************************\n")
  -- -- for i,j in pairs(data.latinmodernroman10regular) do print(i,type(i),j,type(j)) end
  -- print("*********************************\n")
  -- for i,j in pairs(lfc_env.fonts.analyzers.features) do print(i,type(i),j,type(j)) end
  -- print("*********************************\n")
  -- for i,j in pairs(fonts) do print(i,type(i),j,type(j)) end
  -- print("*********************************\n")
  -- for i,j in pairs(lfc_env.fonts.handlers.otf) do print(i,type(i),j,type(j)) end
  -- getgsub
  -- getstreams
  -- getalternate
  -- getkern
  -- getmultiple
  -- collectlookups
  -- scriptandlanguage
  -- getsubstitution
  -- load
  -- loadoutlinedata
  -- loadestreamdata
  -- tables, handlers, readers, cache, features
  -- print("*********************************\n")
  -- for i,j in pairs(lfc_env.fonts.handlers.otf.helpers) do print(i,type(i),j,type(j)) end
  -- print("*********************************\n")
  -- print("*********************************\n")
  -- for i,j in pairs(lfc_env.fonts.handlers.otf.cache) do print(i,type(i),j,type(j)) end
  -- print("*********************************\n")
  -- for i,j in pairs(lfc_env.fonts.handlers.otf.cache.storage["lmroman10-regular"].resources.features.gsub) do print(i,type(i),j,type(j)) end
  -- print("*********************************\n")
  -- for i,j in pairs(lfc_env.fonts.handlers.otf.cache.readables) do print(i,type(i),j,type(j)) end
  -- print("*********************************\n")
  -- for i,j in pairs(lfc_env.fonts.readers) do print(i,type(i),j,type(j)) end
  -- print("*********************************\n")
  -- for i,j in pairs(lfc_env.fonts.mappings) do print(i,type(i),j,type(j)) end
  -- print("*********************************\n")
  -- for i,j in pairs(lfc_env.fonts.helpers) do print(i,type(i),j,type(j)) end
  -- assert(false)

  -- END SCRATCH


  -- names.list returns duplicate names for some font files
  -- this de-duplicates the list, though I wonder if there's a better method?
  local data_by_filename = {}

  -- one would prefer to use index IDs here, but I'm not sure how to get that
  --  in a nice way
  for name, fdata in pairs(data) do
    -- choice of name is arbitrary
    data_by_filename[fdata.filename] = data_by_filename[fdata.filename] or name
  end

  -- ‘in place’ doesn't mean what you think :(
  data_by_filename = table.mirrored(data_by_filename)

  -- discard dupes
  for name, fdata in pairs(data) do
    if data_by_filename[name] == nil then
      data[name] = nil
    end
  end

  -- data doesn't include full paths, so add these now
  for name,info in pairs(data) do
    if info.fullpath == nil then
      -- gets full path from file name
      info.fullpath = lookup_font_file(info.filename)
    end
  end

  f.data = data

  return f
end 
-- }}}

-- tables to translate db descriptors for context into 
-- latex nfss identifiers from fntguide
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

-- turns a descriptor into a latex nfss identifier or warns if unknown
-- type: 'weights' | 'variants' | 'widths' | 'styles'
-- descriptor is weight | width | variant | style as given in db
local function parse_spec(type, descriptor) -- {{{
  local spec = type[descriptor]
  if spec ~= nil then return spec 
  else
    texio.write_nl("Warning: " .. descriptor .. " not a known " .. type .. "!")
    return descriptor
  end
end
-- }}}

---@function prepare_fd(fam, fam_data, fea) {{{
  ---@description returns a table of lines suitable for writing to 
  ---             an .fd file
  ---@param fam <string> NFSS family
  ---@param fam_data <table> sorted data for fonts
  ---@param fea <string> features
  ---@param scale <boolean>
  ---@status internal
local function prepare_fd(fam, fam_data, fea, scale) 

  if scale == nil then scale = true end

  local fd = {}
  local sscale = (scale and fam .. "@scale") or ""
  local ssscale = (scale and "\\" .. fam .. "@@scale") or ""

  local function fd_insert(s)
    insert(fd, s)
  end

  fd_insert("\\ProvidesFile{tu" .. fam .. ".fd}[Font definitions for TU/" .. 
    fam .. "generated by lfc v0.0]")
  if scale then
    fd_insert("  \\expandafter\\ifx\\csname " .. sscale .. 
      "\\endcsname\\relax\n    \\let" .. ssscale .. "\\@empty\n  \\else\n    \\edef" ..
      ssscale .. "{*[\\csname " .. sscale .. "\\endcsname]}%\n  \\fi")
  end
  -- not needed again & errors will be clearer
  sscale = nil

  fd_insert("\\DeclareFontFamily{TU}{" .. fam .. "}{}")

  -- inspect(fam_data)

  local shape_begin = "\\DeclareFontShape{TU}{" .. fam .. "}{"
  local shape_mid   = "}{<-> " .. ssscale .. " \\UnicodeFontFile{\""

  for series,i in pairs(fam_data) do
    for shape,fnts in pairs(i) do
      texio.write_nl("Processing font(s) for " .. series .. 
        " and " .. shape)

      assert(#fnts ~= 0, "The number of fonts should never be zero!")

      if #fnts == 1 then

        fd_insert(shape_begin .. series .. "}{" .. shape .. 
          shape_mid .. fnts[1].fullpath .. "\"}{" .. 
          fea .. "}}{}")

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

        for i,fnt in ipairs(fnts) do
          local min, max
          local opt_size = false
          local pre = ""
          if fnt.nfss_hash == hash_last then
            pre = "%% "
            texio.write_nl("Warning: duplicate fonts found: hash " .. 
              hash_last .. " for family " .. fam)
          end

          if i == 1 then min = ""
          else
            min = fnt.minsize and fnt.minsize/10 or fnt.designsize 
              and fnt.designsize/10 or ""
          end
          if i == #fnts then max = ""
          else
            max = fnt.maxsize and fnt.maxsize/10 or fnt.designsize and 
              fnt.designsize/10 or ""
          end

          -- needed to reinsert scaling if duplicate fonts
          if min ~= "" or max ~= "" then opt_size = true end

          insert(ssubs, pre .. "  <" .. min .. "-" .. max 
            .. "> \\UnicodeFontFile{\"" .. fnt.fullpath .. "\"}{" 
            .. fea .. "}")

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
          table.concat(ssubs, "\n")
          .. "\n}{}")

      end

      -- check for missing basic shapes
      if series.it == nil then
        if series.sl ~= nil then
          fd_insert(shape_begin .. series .. 
          "}{it}{<->ssub * " .. fam .. "/" .. series .. "/sl}{}")
        end
      elseif series.sl == nil then
        fd_insert(shape_begin .. series .. 
        "}{sl}{<->ssub * " .. fam .. "/" .. series .. "/it}{}")
      end
      if series.scit == nil then
        if series.scsl ~= nil then
          fd_insert(shape_begin .. series .. 
          "}{scit}{<->ssub * " .. fam .. "/" .. series .. "/scsl}{}")
          fd_insert(shape_begin .. series .. 
          "}{si}{<->ssub * " .. fam .. "/" .. series .. "/scit}{}")
        end
      elseif series.scsl == nil then
        fd_insert(shape_begin .. series .. 
        "}{scsl}{<->ssub * " .. fam .. "/" .. series .. "/scit}{}")
        fd_insert(shape_begin .. series .. 
        "}{si}{<->ssub * " .. fam .. "/" .. series .. "/scsl}{}")
      end

    end
  end

  -- check for missing basic series
  if fam_data.b == nil then
    if fam_data.bx ~= nil then
      for shape,_ in pairs(fam_data.bx) do
        fd_insert(shape_begin .. "b}{" .. shape .. 
          "}{<->ssub * " .. fam .. "/bx/" .. shape .. "}{}")
      end
    end
  elseif fam_data.bx == nil then
    for shape,_ in pairs(fam_data.b) do
      fd_insert(shape_begin .. "bx}{" .. shape .. 
        "}{<->ssub * " .. fam .. "/b/" .. shape .. "}{}")
    end
  end
    
  return fd
end-- }}}

local function write_fd(fam, fd_lines, fd_file) -- {{{
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

-- should be broken up?!
-- takes a font request, configuration details and name suffix
-- only targ is required
-- either returns metadata with .fd details, if existent
-- or returns the same after writing one or more (hopefully suitable) .fd
local function font_config(targ, config, suffix) -- {{{

  -- for i,j in pairs(fonts.names) do
  --   print(i,type(i),j,type(j))
  -- end
  -- print("************** <index>.fontnames *******************")
  -- local font_index = fonts.names.access_font_index()
  -- for i,j in pairs(fonts.mappings) do
  --   print(i,type(i),j,type(j))
  -- end
  -- assert(false)


  -- inspect(lfc_env)
  -- print("**** lfc_env ****")
  -- for i,j in pairs(lfc_env) do
  --   print("\n", i, type(i), j, type(j))
  -- end
  -- print("**** resolvers ****")
  -- for i,j in pairs(lfc_env.resolvers) do
  --   print("\n", i, type(i), j, type(j))
  -- end
  -- print("**** fonts ****")
  -- for i,j in pairs(lfc_env.fonts) do
  --   print("\n", i, type(i), j, type(j))
  -- end
  -- print("**** fonts.analyzers ****")
  -- for i,j in pairs(lfc_env.fonts.analyzers.methods) do
  --   print("\n", i, type(i), j, type(j), lfc_env.fonts.analyzers.methods.latn)
  -- end
  -- print("**** fonts.analyzers.features ****")
  -- for i,j in pairs(lfc_env.fonts.analyzers.features) do
  --   print("\n", i, type(i), j, type(j))
  -- end
  -- print("**** fonts.handlers ****")
  -- for i,j in pairs(lfc_env.fonts.specifiers.variants) do
  --   print("\n", i, type(i), j, type(j))
  -- end

  if targ == nil then return nil end

  config = config or {}
  config.fea = config.fea or "\\UnicodeFontTeXLigatures"
  config.size = config.size or "10"
  local scale = config.scale
  
  suffix = suffix or ""

  local f = get_font_data(targ, suffix)

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
    local width = font.width
    local weight = font.weight
    local style = font.style
    local variant = font.variant
    -- family is more specific than familyname
    local family = font.familyname
    local fullname = font.fullname

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

      -- for latin modern roman unslanted, which claims to be perfectly ‘normal’
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
    -- not allowed
    if nfss_weight == "m" then
      series = nfss_width
    elseif nfss_width == "m" then
      series = nfss_weight
    else 
      series = nfss_weight .. nfss_width
    end

    -- likewise ‘n’, but I never saw anybody combine this, so nothing broken
    if nfss_style == "n" then
      shape = nfss_variant
    elseif nfss_variant == "n" then
      shape = nfss_style
    else
      shape = nfss_variant .. nfss_style
    end

    -- hash is <family>:<series>:<shape>[<minsize>:<maxsize>]
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

  -- what to do about the common weights NFSS doesn't cover?
  -- e.g. ‘medium’ and ‘book’ often differ from both ‘regular’ and each other
  -- but treating them as distinct families still seems wrong
  -- they should be installed as weights, but this is tricky as it breaks
  --  font selections unless additional change rules are provided
  -- normally these are made into different families, but then you must 
  --  either assign other weights arbitrarily to those families or duplicate
  --  entries in multiple fds & neither is really good to do on-the-fly

  -- so what to do here?
  --    1) use ‘book’ or ‘k’ or ‘medium’ or ‘med’ or whatever?
  --    2) use ‘m’ and hope the fonts discarded as dupes are of-a-weight (not
  --      likely)?
  --    3) as (2) but discard all fonts with these weights if ‘regular’ is 
  --      available, presumably later?
  --    4) create separate families?
  --    5) error if a foundary is so inconveniently prolific?

  -- I can see the ‘m’ would have been sufficient in the past, though I used
  --    ‘mb’ before it got prohibited (and so did some core ‘.fd’ files).
  -- But now so many fonts distinguish these ...

  -- it would be so much nicer (and more efficient) if NFSS let this be done
  --    properly!
  
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

  -- Another possibility:
  --    Write the files at enddocument or stash in cache?
  --    Then try to intercept first requests for e.g. sc and update defns?
  --    Sounds very fragile, though.

  -- local fds = {}

  for fam,fam_data in pairs(parsed_fam) do
    local fd = prepare_fd(fam, fam_data, config.fea, scale)
    write_fd(fam, fd) 
  end

  -- for fam, fam_data in pairs(fds) do write_fd(fam, fam_data) end

  return f
end
-- }}}


-------------------------------------------------------------------------------
-- lfc.search_family = search_family
lfc.get_font_data = get_font_data
lfc.font_config = font_config
-- lfc.fonts = fonts

return lfc
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-- vim: et:foldmethod=marker:
