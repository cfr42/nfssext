$Id: README.md 10358 2024-09-17 11:19:36Z cfrees $
=================================================
Copyright (C) 2008-2024 Clea F. Rees.

This work may be distributed and/or modified under the
conditions of the LaTeX Project Public License, either version 1.3c
of this license or (at your option) any later version.
The latest version of this license is in
  https://www.latex-project.org/lppl.txt
and version 1.3c or later is part of all distributions of LaTeX
version 2008-05-04 or later.

This work has the LPPL maintenance status `maintained'.

The Current Maintainer of this work is Clea F. Rees.

This work consists of all files listed in manifest.txt.


All TeX Font Metric files (suffix .tfm in subdirectory fonts/tfm),
Virtual Fonts (suffix  .vf in subdirectory fonts/vf) etc. are
derived from the relevant Latin Modern fonts, version 2.004,
released by GUST and available from
http://www.gust.org.pl/projects/e-foundry/latin-modern. The TFM and
VF files are derived specifically from the Adobe Font Metric (suffix
.afm) and TeX Font Metric (suffix .tfm) files supplied with the 
postscript type 1 version of the fonts.

The encoding t1-clm.etx is derived from the file t1.etx supplied with
fontinst. A copy of fontinst including an unmodified copy of t1.etx is 
available from https://mirror.ctan.org/fonts/utilities/fontinst.

In version 1.6 and later, the docstrip files cfr-lm.ins, cfr-lm.dtx and 
cfr-lm-build.dtx are derived from skeleton.ins and skeleton.dtx, both part of
of version 2.4 of Scott Pakin's dtxtut. A copy of dtxtut including unmodified
copies of skeleton.dtx and skeleton ins is available from 
https://www.ctan.org/pkg/dtxtut and released under the LPPL.

Other attributions are included in the source of the package itself.
=================================================


# Selected Version History

Version 1.3 (and the unpublished 1.2) of the package benefited greatly 
from feedback provided by Enrico Gregorio, who essentially rewrote the style 
file using keyval to show me how I ought to be setting the various options
up, and Lars Hellström who demonstrated considerable patience in 
answering my many questions about using fontinst and some peculiarities
of the Latin Modern fonts.

Version 1.4 adds experimental support for microtype. While this 
should work fine since it basically uses the settings for Latin Modern and
Computer Modern Roman, I'm far from confident about this.

Version 1.5 corrects 2 typos in the -drv.tex files (1 in each). These caused
inaccuracies in two of the .fd files. Since it takes a long time to run
fontinst, the .fd files have been corrected by hand in a way which should, I
hope effect the same corrections as would be obtained by recreating them.

Version 1.6 (unpublished) included updates for compatibility with the (New) New
Font Selection Scheme (NNFSS), which replaced, but is still officially called,
the New Font Selection Scheme (NFSS) in 2020. This required an update to
nfssest-cfr, which now loads either an extension of NFSS (on older kernels) or
an extension of NNFSS (on newer). It also required changes to the font
definition files and, hence, the drivers used to generate them. This release
also removed the dependency on xkeyval and reimplemented the option processing
in expl3

Verion 1.7 corrects some errors in the source, adds some convenience shorthands
to the options and switches to docstrip. It also uses l3build to generate the
TeX font files using a custom build target and to tidy up the font definition
files. l3build is also used to generate tables for all provided fonts and to
implement regression testing (though this will not, unfortunately, pick up the
likely regressions due to the 2020 changes).

A more detailed history is included in the documentation and sources.

# Documentation

See cfr-lm.pdf for information about installation, requirements and usage.
For sparse comments on the source, see cfr-lm.pdf for the LaTeX package and
cfr-lm-build.pdf for the fontinst sources. Note that cfr-lm-build.pdf is
completely horrible. As documentation, the kindest thing one can say about it is
that it exists, whereas the source was previously not in the typeset
documentaton at all. The document is so ghastly, however, that I strongly
recommend reading cfr-lm-build.dtx instead. The only reason to include the PDF
at all is that it contains an index of the code. Auch indexes are automatically
generated with all the usual limitations consequent on that and this one is no
exception. It is, however, arguably better than no index at all.

# Code Repositories

Code for the LaTeX support package is hosted at 
  https://codeberg.org/cfr/nfssext
For convenience, the repository is mirrored at
  https://github.com/cfr42/nfssext

# Contact Details

Bug reports, feature requests etc. concerning the LaTeX support or packaging
should be filed at
  https://codeberg.org/cfr/nfssext/issues

If you have comments about the fonts themselves, please contact GUST.


Clea F. Rees
Version 1.7
2024-09-17

=================================================
vim: et:tw=80:sw=2:
