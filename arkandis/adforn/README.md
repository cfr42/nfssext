$Id: README.md 10440 2024-09-29 16:02:57Z cfrees $

# adforn

adforn consists of:
1. the Ornements ADF font developed by Hirwen Harendel, Arkandis Digital
Foundry (ADF) and released under the terms set out in the files COPYING and
NOTICE in postscript type 1 format; 
1. (La)TeX support by Clea F. Rees released under the LPPL. All files covered
by the LPPL are listed in the file manifest.txt.

Information and resources concerning Ornements ADF, including an opentype
version of the font, and other ADF fonts can be found on the foundry's
homepage:
	http://arkandis.tuxfamily.org/

## (La)TeX Support

For details, please see adforn.pdf. The main command is \adforn{} which 
takes any integer between 1 and 75. Commands for slightly more semantic markup
are provided as alternatives.

## Versioning

Version 1.1a corrects a bug **if** I've understood the problem correctly, which 
I'm far from convinced of. (All it does is add a pair of curly brackets in the
.sty.)

Version 1.1b includes the PDF documentation *and* the TFM. Apologies for the
inconvenience.

Version 1.2 removes dependency on pifont and offers scaling option.

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
Version 1.2
2024-09-29

<!-- vim: tw=80:et:sw=2: -->
