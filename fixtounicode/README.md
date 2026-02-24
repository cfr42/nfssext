$Id: README.md 11681 2026-02-24 02:46:15Z cfrees $

=================================================
# fixtounicode
=================================================

Simple convenience wrappers designed to help in adding 'tounicode' values
to Postscript type1 fonts installed as TeX fonts for use in LaTeX. 

The package is primarily designed for use in type1 symbol font packages.
So the main interface consists of a couple of expl3 functions. This can 
either be used directly or via a 2e command using key-value syntax.

In case document authors wish to add mappings for symbols which do
not have them (perhaps to make the resulting PDFs accessible via screen-
readers), a more convenient key supports setting Unicode values by glyph name.
This is intended for use where an author needs to add mappings for a small
number of symbols from a font, rather than mapping all symbols as a package
would.

=================================================
# Compatibility
=================================================

## pdfTeX | LuaTeX 1.24 or later

pdfTeX and recent LuaTeX (1.24 or later) are fully supported if output is 
direct to PDF.

## LuaTeX 1.22 or earlier

LuaTeX 1.22 and earlier is partially supported, but the interface is more
restricted and the addition of supplemental mappings depends on how 'nice'
the encoding is. 

For example, adforn, adfarrows and adfbullets exemplify ideal
encodings: glyphs are assigned to slots starting from 0 with no gaps. Hence,
these can be fully mapped.

Zapf Dingbats exemplifies a trickier case. The first used slot is not 0 and
the encoding has multiple gaps. It is, therefore, possible to map any contiguous
range of glyphs, but not all at the same time. (At least, it is not possible
with this package.)

marvosym, however, I could not get to work at all with TL2025's unfixed LuaTeX.

=================================================
# Licence
=================================================

Copyright (C) 2025--2026 Clea F. Rees.

This work may be distributed and/or modified under the conditions of the 
LaTeX Project Public License, either version 1.3c of this license or (at your 
option) any later version. The latest version of this license is in
  https://www.latex-project.org/lppl.txt
and version 1.3c or later is part of all distributions of LaTeX version 
2008-05-04 or later.

This work has the LPPL maintenance status `maintained'.

The Current Maintainer of this work is Clea F. Rees.

This work consists of all files listed in manifest.txt.

fixtounicode.dtx and fixtounicode.ins use infrastructure derived 
from skeleton.ins and skeleton.dtx, both part of of version 2.4 of Scott 
Pakin's dtxtut. A copy of dtxtut including unmodified copies of skeleton.dtx 
and skeleton ins is available from https://www.ctan.org/pkg/dtxtut and 
released under the LPPL.

Other attributions are included in the source of the package itself.

=================================================
## Code Repositories
=================================================

Code for the LaTeX support package is hosted at 
	https://codeberg.org/cfr/nfssext
For convenience, the repository is mirrored at
  https://github.com/cfr42/nfssext

=================================================
## Contact Details
=================================================

Bug reports, feature requests etc. concerning the LaTeX support or packaging
should be filed at
  https://codeberg.org/cfr/nfssext/issues


Clea F. Rees 
Version 0.1
2026-02-24

=================================================
vim: et:tw=80:sw=2:
