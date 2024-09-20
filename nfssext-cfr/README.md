$Id: README.md 10366 2024-09-18 14:25:21Z cfrees $

=================================================
# nfssext-cfr
=================================================

Additions and changes Copyright (C) 2008-2024 Clea F. Rees.
Code from The Font Installation Guide Copyright (C) 2002-2004 Philipp Lehman
(see below)

This work may be distributed and/or modified under the conditions of the 
LaTeX Project Public License, either version 1.3c of this license or (at your 
option) any later version. The latest version of this license is in
  https://www.latex-project.org/lppl.txt
and version 1.3c or later is part of all distributions of LaTeX version 
2008-05-04 or later.

This work has the LPPL maintenance status `maintained'.

The Current Maintainer of this work is Clea F. Rees.

This work consists of all files listed in manifest.txt.


The files nfssext-cfr.sty, nfssext-cfr-nfss.sty and nfssext-cfr-nnfss.sty are
derived works under the terms of the LPPL. They are based on version 1.2 of 
nfssext.sty which was supplied with fontinstallationguide by Philipp Lehman.  
A copy of fontinstallationguide, including an unmodified version of 
nfssext.sty is available from
  https://tug.ctan.org/pkg/fontinstallationguide.
nfssext.sty wajs part of the included archive figuide-examples.tar.gz which 
consisted of examples and templates released under the LPPL. nfssext.sty was 
included in the files for tutorials 3, 5 and 6.

The main modifications made to this file are described in nfssext-cfr.dtx.


In versions which use docstrip, the docstrip files nfssext-cfr.ins, 
nfssext-cfr.dtx, nfssext-cfr-t1.dtx and nfssext-cfr-t1.ins are derived 
from skeleton.ins and skeleton.dtx, both part of of version 2.4 of Scott 
Pakin's dtxtut. A copy of dtxtut including unmodified copies of skeleton.dtx 
and skeleton ins is available from https://www.ctan.org/pkg/dtxtut and 
released under the LPPL.

Other attributions are included in the source of the package itself.

=================================================
## Origins & Purpose 
=================================================

nfssext-cfr is an extension of Philipp Lehman's nfssext. nfssext
provides commands which enable one to specify font features not covered by
the New Font Selection Scheme of LaTeX-2e. nfssext-cfr provides
additional commands, further extending the facilities offered by NFSS.

nfssext-cfr is required by various font support packages I've written.
It is released separately both to avoid unnecessary duplication and
confusion and to make it available for other purposes. 

=================================================
## Revision History
=================================================

Please see nfssext-cfr.pdf and nfssext-cfr.dtx.

=================================================
## Current Version
=================================================

The current version is an extremely belated update for compatibility with 
the (New) New Font Selection Scheme (NNFSS) introduced in 2020. This has 
somewhat complicated things in various ways and the current version may best
be described as a compromise which will please nobody equally.

The package includes three .sty files. The main package is a wrapper which 
decides which of the other two to load, together with a small amount of common
code.

The documentation explains changes required in font definition files for
backwards compatibility and the options users have if reliant on files which 
have not been updated. No additional incompabilities should be introduced by
the update to nfssext-cfr. At worst, things which were broken in 2020 will 
remain broken, but breakage which can be fixed in this package _should_ be 
fixed.

nfssext-cfr interferes with kernel code in various ways. This is nothing new.
nfssext rewrote kernel definitions. nfssext-cfr rewrote kernel definitions. 
The new version of nfssext-cfr rewrites kernel definitions. Details of what is
done under what conditions are included in the documentation.

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
Version 1.0
2024-09-18

=================================================
vim: et:tw=80:sw=2:
