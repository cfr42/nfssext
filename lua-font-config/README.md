<!-- $Id: README.md 12146 2026-10-22 05:17:47Z cfrees $ -->

=================================================
# lua-font-config
=================================================

Fast and simple opentype font configuration for LuaLaTeX. Efficient 
auto-generation of font families providing easy access to the multiple 
shapes, weights, widths and features provided by many of today's fonts. 

Engine callbacks, LaTeX hooks and caching are used to eliminate pre-loading,
reduce lookups and minimise pre-defining. This allows very rich font families 
to be quicky generated, with minimal user input and zero configuration files. 

The core code consists of two Lua modules: one taken as-is from ConTeXt (MKIV)
and one providing the LaTeX interface and data processing.

The package is experimental and, while already usable in many cases, 
currently(?) provides only a small part of fontspec's functionality.

Implemented features include:
- configuration of the main document font families (roman, sans, 
    typewriter); 
- optional use of these families in maths mode;
- creation of additional families (text mode);
- support for Unicode maths (via lua-unicode-math).

Missing features include:
- support for multi-lingual typesetting;
- support for variable fonts;
- spot colours etc.;
- a user interface beyond the rudimentary.

While I have tested the package, I can only do this on Arch Linux (locally)
and Ubuntu (GitHub). Given how system-dependent Unicode font configuration
is, I would particularly welcome feedback on whether and how well it works
elsewhere.

=================================================
# Compatibility
=================================================

The package requires LuaLaTeX.

=================================================
# Licence
=================================================

-------------------------------------------------
## ConTeXt module
-------------------------------------------------

The file named lfc-context-font-syn.lua is a renamed copy of

  filename:     context-font-syn.lua 
  author:       Hans Hagen, PRAGMA-ADE, Hasselt NL
  copyright:    PRAGMA ADE / ConTeXt Development Team
  licence:      GPL v2

-------------------------------------------------
## LaTeX adaption
-------------------------------------------------

The following statement applies to all files except the ConTeXt module.

Copyright (C) 2026 Clea F. Rees.

This work may be distributed and/or modified under the conditions of the 
LaTeX Project Public License, either version 1.3c of this license or (at your 
option) any later version. The latest version of this license is in
  https://www.latex-project.org/lppl.txt
and version 1.3c or later is part of all distributions of LaTeX version 
2008-05-04 or later.

This work has the LPPL maintenance status `maintained'.

The Current Maintainer of this work is Clea F. Rees.

This work consists of all files listed in manifest.txt.

lua-font-config.dtx and lua-font-config.ins use infrastructure derived 
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
2026-10-15

=================================================
vim: et:tw=80:sw=2:
