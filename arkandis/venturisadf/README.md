$Id: README.md 10322 2024-09-05 05:31:35Z cfrees $

Copyright (C) 2008-2024 Hirwen Harendal and Clea F. Rees

This work may be distributed and/or modified under the conditions of the LaTeX
Project Public License, either version 1.3 of this license or (at your option)
any later version.  The latest version of this license is in
http://www.latex-project.org/lppl.txt and version 1.3 or later is part of all
distributions of LaTeX version 2005/12/01 or later.

This work has the LPPL maintenance status `maintained'.

The Current Maintainer of this work is Clea F. Rees.

This work consists of all files listed in manifest.txt.


# Overview 

This package includes the VenturisADF font collection in postscript type 1
format, LaTeX support files and documentation.

Opentype versions of the fonts are also available (see below).


# Copyright and licensing 

## Fonts 

The Venturis Collection consists of fonts made by Arkandis Digital Foundry
(ADF), collectively known as the "Software", currently maintained by ADF.  As
the Software is modified from Utopia fonts, they are under the same license as
the Utopia fonts themselves (see LICENSE-utopia.txt).  That is, Akandis Digital
Foundry hereby grants the TeX Users Group and any and all other interested
parties the rights enumerated in the Utopia license.

As Venturis is a trademark of Arkandis Digital Foundry, any modified versions
of Software shall not use the font name(s) or trademark(s), in whole or in
part, unless explicit written permission is granted by ADF as described in the
initial license.

The following changes have been made to the standard Venturis Collection font
files in preparing this package for use with (La)TeX:
- the postscript versions of the fonts have been renamed according to the Karl
  Berry fontname scheme;
- the opentype fonts have been removed from the package.

## TeX/LaTeX support files and documentation

As explained in comments at the top of each file, many of the encoding (.etx)
files are based on standard fontinst files such as t1.etx and ts1.etx.
Modifications are Copyright (C) 2008-2024 Clea F. Rees (see below).

Code from t1.etx Copyright (C) 2005 Alan Jeffrey and Sebastian Rahtz and Ulrik
Vieth and Lars Hellstr{\"o}m (see below).

Code from ts1.etx Copyright (C) 2005 Sebastian Rahtz and Ulrik Vieth and Lars
Hellstr{\"o}m (see below).

The file lining.etx is Copyright (C) 2003 Philipp Lehman (see below).

Batch and source files (.dtx, .ins) are based on from skeleton.ins and 
skeleton.dtx, both Copyright (C) 2015-2024 Scott Pakin (see below).

README (this file) and LIST-Venturis.txt are Copyright (C) 2008-2024 Hirwen 
Harendal and Clea F. Rees.

All other non-derived files listed in manifest.txt are Copyright (C) 2008-2024 
Clea F.  Rees.

This work may be distributed and/or modified under the conditions of the LaTeX
Project Public License, either version 1.3 of this license or (at your option)
any later version.  The latest version of this license is in
http://www.latex-project.org/lppl.txt and version 1.3 or later is part of all
distributions of LaTeX version 2005/12/01 or later.

This work has the LPPL maintenance status `maintained'.

The Current Maintainer of this work is Clea F. Rees.

This work consists of all files listed in manifest.txt.

The following changes have been made to the standard Venturis Collection
documentation in preparing this package:
- a new README (this file) has replaced the original README, incorporating both
  relevant parts of the original and additional information concerning TeX/LaTeX
  support
- LIST-Venturis.txt has been edited to reflect the Karl Berry fontname scheme
  used for the postscript type 1 fonts (see below) and to update the date,
  version and font list, as appropriate.

The following files are derived works under the terms of the LPPL:

## lining.etx 

lining.etx is derived from The Font Installation Guide by Philipp Lehman.
lining.etx is unmodified.  

## oldstyle.etx

oldstyle.etx is a variation on the same theme.

A copy of The Font Installation Guide is available from
http://tug.ctan.org/cgi-bin/ctanPackageInformation.py?id=fontinstallationguide.
The included archive figuide-examples.tar.gz consists of files and templates
released under the LPPL.  These include lining.etx.

## fonts based on t1.etx and ts1.etx 

The following files are  derived from the file t1.etx supplied with the
package fontinst.  
- t1-f_f.etx
- t1-dotalt-f_f.etx
- t1-venturis.etx
- t1-venturisold.etx
- t1-venturisold-longs.etx
- ucdotalt.etx
ts1-euro.etx is derived from ts1.etx supplied with fontinst. t1j-venturis.etx
and t1j-f_f.etx are based on t1j.etx. 

For details, see the notices included in files themselves.
fontinst is released under the LPPL.

## all .dtx and .ins files

The source files all began life as modifications of skeleton.dtx and 
skeleton.ins from version 2.4 of dtxtut by Scott Pakin. A copy of dtxtut,
including the unmodified version of skeleton.dtx is available from
https://www.ctan.org/pkg/dtxtut and released under the LPPL.


# Status 

## Fonts and documentation 

PS-Type1: ANSI Adobe standard encoding. All fonts are hinted with kerning and
subroutines.  

OTF:  All fonts include full opentype features and subroutines, are generated
with FontForge. 

PS 1.005 RELEASE VERSION: July 2010
- AFDKO's compilation bugs correction.
- Typographical features addition. (All typo spaces and all typo hyphens.)
- Q redrawn.
- Minor corrections.

PS 1.004 RELEASE VERSION: November 2008
- Minor corrections, liga addition, new kerning table.

PS 1.003 RELEASE VERSION: June -06- 2008
- Minor corrections, hinting ajustements.

PS 1.002 RELEASE VERSION: December -28- 2007
- New kerning table, and minor corrections. 

PS 1.001 RELEASE VERSION: December -15-2007
- Add VenturisOld family, VenturisSans heavy and heavy oblique,
  VenturisTitlingNo4 (outlines).
  
PS 1.000 RELEASE VERSION: October-01-2007
- Add VenturisN2 Condensed and Medium families. 

## TeX/LaTeX support files and documentation

I previously said that I did not think the LaTeX support files would persuade 
your cat to revolt, partly on the grounds that so few cats require such 
persuasion. I also expressed some confidence that they would not drink all 
your tea, while remaining sceptical regarding further claims about their 
performance.

I'm now reasonably confident that they will more-or-less behave as documented,
Whether this is the behaviour you --- as opposed to I --- would expect is a 
question I must leave each reader to decide.

Please report issues on the bug-tracker (see below). Suggested fixes are 
always welcome, as are proposals for improvements and notwithstanding the 
fact that I may on occasion be unable or unwilling to accommodate them.


# Installation and use 

## TeX/LaTeX support 

See included documentation, venturisadf.pdf, for information regarding (La)TeX
support. The documentation source, venturisadf.dtx uses various other
packages. These are all standard and available from CTAN but may be commented
out if preferred.

The LaTeX packages (venturis, venturis2 and venturisold) nfssext-cfr, 
available from CTAN.


# Further information 

For further information about the Venturis Collection and other Arkandis Digital
Foundry fonts, see the ADF homepage: http://arkandis.tuxfamily.org/

Further information about ADF font development of fonts specifically designed
for use with TeX is available at:
http://arkandis.tuxfamily.org/tugfonts.htm 
This page includes full Venturis font previews and the opentype version of
the fonts.


# Maintenance 

Package maintained by ADF
- font development and maintenance by Hiwen HARENDAL 
	(harendalh <at> hotmail <dot> com)
- TeX/LaTeX support and documentation by Clea F. Rees 
    (https://codeberg.org/cfr/nfssext/issues)

## Code Repositories

Code for the LaTeX support package is hosted at 
	https://codeberg.org/cfr/nfssext
For convenience, the repository is mirrored at
  https://github.com/cfr42/nfssext

Version 2.0
2024/08/18

<!-- vim: tw=80:et:sw=2: -->
