OrnementsADF puts ornaments into arbitrarily named slots in the font e.g. `A`, `B` and so on. For example, an arrowhead is in the slot named as the right square bracket. By default, then, all `tounicode` mappings are incorrect.

For pdfTeX, this is easily, if tediously, corrected as `\pdfglyphtounicode` supports a per-`tfm` syntax. LuaTeX, however, [does not][1]. 

According to my (doubtless flawed) reading of the LuaTeX manual, setting `tounicode` values on a per-character basis, combined with a setting of `tounicode` to `1` for the font ought to tell LuaTeX the defined font provides Unicode mappings.

At least for `plain`<sup>1</sup>, I can set up the font tables in a seemingly correct<sup>2</sup> way using the `define_font` callback. 

MNWE:
```latex
\directlua{
  pdf.setgentounicode(1)
  callback.register('define_font',
    function (name,size)
      if name == "OrnementsADF" then
        local f = font.read_tfm('OrnementsADF.tfm',size)
        for i,_ in ipairs(f.characters) do
          f.characters[i].tounicode = "2B9E"
        end
        f.tounicode = 1
        f.size = size
        return f
      else
        return font.read_tfm(name,size)
      end
    end)
}
\font\orn = OrnementsADF at 10pt \orn\char42
\directlua{
  for i,j in font.each() do
    if j.name == 'OrnementsADF' then
      print(j.characters[42].tounicode)
      print(j.tounicode)
    end
  end
}
\bye
```
The output on the console is as expected: `2B9E` followed by `1`. However, LuaTeX still overrides the `tounicode` value: copying the character from the PDF produces a square bracket rather than an arrowhead (U+2B9E).

[I am not convinced this shouldn't be a different question, but, in light of feedback in comments ...]

If `luaotfload.sty` is loaded in `plain` or `LaTeX`, it is not very easy to see how even to modify the font tables without breaking things. `luaotfload.patch_font` obviously can't be used and neither can `define_font` (that is, again without breaking stuff).

Here is an MWE for LaTeX with `luaotfload`:
```latex
\DocumentMetadata{lang=en-GB,tagging=on,pdfversion=2.0,pdfstandard=UA-2,uncompress}
\documentclass{article}
\font\lmr = {file:lmroman10-regular.otf} at 10pt
\font\orn = OrnementsADF at 10pt 
\begin{document}
\lmr ŵ
\orn\char42
\end{document}
```
and here's a modification which is close to the example which motivated my exploration of this particular rabbit hole.
```latex
\DocumentMetadata{lang=en-GB,tagging=on,pdfversion=2.0,pdfstandard=UA-2,uncompress}
\documentclass{article}
\usepackage{adforn}
\begin{document}
ŵ
\adforn{43}
\end{document}
```
What is/are the correct way/s to do this?

I also have some MWEs involving `luaotfload` in plain, which I can post if anybody wants them. (They are a bit messier because I've been playing in that sandbox, but I can clean them up.)

Note that I am aware there are many alternative Unicode fonts which could be used to provide similar symbols. I am specifically interested in ways to get correct mappings in LuaTeX for 7/8-bit symbol fonts (mostly type1 postscript), which typically assign glyphs to slots arbitrarily. `pifont` is probably the paradigmatic example.

<sub><sup>1</sup>Obviously, things are more complicated in LaTeX.</sub>

<sub><sup>2</sup>Again obviously, the mappings defined in the example are not correct as not every ornament in the font is an arrowhead. But a single Unicode point suffices for experimental purposes.</sub>

  [1]: https://github.com/TeX-Live/texlive-source/blob/2b52d2eeac072021fb40a324a333a95f698520b8/texk/web2c/luatexdir/font/pdfglyphtounicode-readme.txt
