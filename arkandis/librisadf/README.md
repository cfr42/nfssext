$Id: README.md 10322 2024-09-05 05:31:35Z cfrees $

# librisadf

librisadf consists of:
1. the Libris ADF Std fonts developed by Hirwen Harendel, Arkandis Digital
Foundry (ADF) and released under the terms set out in the files COPYING and
NOTICE.txt in postscript type 1 format;
2. (La)TeX support by Clea F. Rees released under the LPPL. All files covered
by the LPPL are listed in the file manifest.txt.

Information and resources concerning Libris ADF, including opentype versions
of the fonts, and other ADF fonts can be found on the foundry's homepage:
	http://arkandis.tuxfamily.org/

## (La)TeX Support

For details, please see librisadf.pdf.

The (La)TeX support uses modified T1 encodings. The regular version reassigns
certain slots which would otherwise be empty due to missing glyphs. The
"swash" version reassigns additional slots so that certain glyphs are not
accessible when the swash variant is active even though they are provided by
the font. To access these glyphs, ensure that the regular version of the font
is active. For details of the modifications, see comments in t1-libris.etx and
t1-librisswash.etx. For a full list of the reassigned slots and of the
characters normally available in T1 but not in these encodings, see
librisadf.pdf.

The (La)TeX support requires nfssext-cfr.sty. This file is available from
CTAN.

To use the fonts in a LaTeX document, add
	\usepackage{libris}
to your preamble. This will set the default sans-serif family to Libris ADF
Std. To use this as the default font, add the line
	\renewcommand{\familydefault}{\sfdefault}
to your preamble.

To use the "swash" variant which provides some alternative characters and
additional ligatures, use
	\swashstyle
to set this as default until further notice or
	\textswash{Hello!}
to typeset just the text "Hello!" in this style.


## Code Repositories

Code for the LaTeX support package is hosted at 
	https://codeberg.org/cfr/nfssext
For convenience, the repository is mirrored at
  https://github.com/cfr42/nfssext

## Contact Details

Bug reports, feature requests etc. concerning the LaTeX support or packaging
should be filed at
  https://codeberg.org/cfr/nfssext/issues

If you have comments about the fonts themselves, please contact Hirwen
Harendal (harendalh <at> hotmail <dot> com). 

Clea F. Rees
Version 0.0
0000/00/00

<!-- vim: tw=80:et:sw=2: -->
