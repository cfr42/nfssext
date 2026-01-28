-- $Id: fixtounicode.lua 11568 2026-01-28 03:12:06Z cfrees $
-- addaswyd o ateb Max Chernoff: ihttps://tex.stackexchange.com/a/740937/
-- gweler ateb-max-chernoff-ee-4-tfm-workaround.tex ateb-max-chernoff.md

luatexbase.provides_module({
  name = "fixtounicode",
  date = "2026/01/24",
  version = "0.1.1",
  description = [[Provides functions to add tounicode mappings for SOME type1 
    symbol fonts in LuaLaTeX. Whether this works for any particular font or 
    not depends on the configuration.]] 
})
pdf.setgentounicode(1) -- oes pwrpas?
local function fnt_tounicodes (targtexfont,targfont,targtab)
  if fixtounicode_debug then
    print("Adding callback for",targtexfont,targfont,targtab)
  end
  -- Register the callback. We need "luaotfload.patch_font_unsafe" since only
  -- the unsafe version applies to TFM fonts.
  luatexbase.add_to_callback("luaotfload.patch_font_unsafe", 
    -- luaotfload-loaders.lua: fn gets these three args 
    function(tfmdata, specification, id)
      if not specification:match(targtexfont) then
        return
      end
      
      if fixtounicode_debug then
        print("Mapping tounicode values for",targtexfont,targfont,targtab)
        for i,j in pairs(targtab) do print(targtexfont,targfont,i,j) end
      end

      for index, character in pairs(tfmdata.characters) do
        -- Max's solution needed them in tfm order, but don't assume this
        -- so we would like have a table not an array
        -- but that doesn't work because you can't get the names
        -- there is a more complicated way, but meh
        -- this will be obsolete in a few months anyhow

        -- angen error check 
        -- ditto - chances of anybody else using this version are essentially
        -- zero

        -- For Type 1 fonts, you need to set the index of the character.
        -- This isn't done for TFM fonts, so we need to do it here.

        -- a/c for lua indexing from 1
        character.index = index + 1

        -- Max's comment below now applies to the construction of targtab, 
        -- I think ...
        -- The LuaTeX manual says that "<character>.tounicode" needs to be
        -- character, first encoded in UTF-16BE, and then encoded in
        -- hexadecimal. This _will_ work, but encoding non-BMP characters
        -- in UTF-16 is pretty tricky. However, you can instead pass an
        -- array of codepoints (as integers), and LuaTeX will handle the
        -- encoding for you. This is completely undocumented, but it works.

        local u = targtab[index]

        character.tounicode = { u }

        if fixtounicode_debug then 
          print("Mapping:",index,character.index,u,character.tounicode) 
        end
      end

      tfmdata.filename = kpse.find_file(targfont .. ".pfb", "type1 fonts")
      tfmdata.type = "real"
      tfmdata.format = "type1"
      tfmdata.tounicode = 1
      tfmdata.encodingbytes = 2  -- Needed for Type 1 fonts
    end, 
    targtexfont .. "_" .. targfont .. "_tounicode")
end

fixtounicode = {}
fixtounicode.tounicodes = fnt_tounicodes
return 0
