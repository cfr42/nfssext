$Id: README.md 10837 2025-02-21 03:21:27Z cfrees $

=================================================
# fontscripts
=================================================

This work, which consists of all files listed in manifest.txt, is released 
under the LaTeX Project Public Licence version 1.3c or later. See individual 
files for details.

=================================================
## Purpose 
=================================================

The package provides variant font encodings, support metrics and Lua script 
fragments to automate the creation of TeX/LaTeXe font files for 8-bit engines 
using l3build. A template-based system enables the automatic generation of 
font tables and l3build tests. 

The scripts make it possible to automate the generation of TeX fonts (TeX font
metrics, virtual fonts, map files etc.). For tools which do not otherwise
support it, such as fontinst, the scripts enable the automatic addition of
variable scaling in font definition files. A semi-automatic system tries to
ensure font encoding names are unique.

The script fragments are primarily designed for fontinst, but can be adapted 
for use with other programmes. The default configuration is intended to be 
cross-platform and requires only tools included in TeX Live, but the 
documentation includes a simple adaption for integration with FontForge and 
GNU make.

The encoding and metric files support fonts which use variant names for
characters. For example, fonts may use 'emdash' and 'endash' or 'f_f'. They also
support some fonts converted from opentype which use suffixes to distinguish
small-caps, for example, rather than placing these characters in separate fonts.

=================================================
## Revision History
=================================================

- v0.1 Initial release.
- v0.2 Restructuring of code to use a more modular and (hopefully) flexible
approach. Other tool chains can now use functions to build and keep font support
files and ensure unique encoding names. Facilities for 'sandboxing' the 
building and testing of font packages are now provided and utilised by default.  
Almost all package functions and variables are now in a dedicated namespace to 
prevent any possible conflicts. TDS locations are suggested to facilitate use 
if installed and default templates are provided for the template system. 
fntbuild.lua can now insert font subset encoding declarations into font 
definition files, as recently requested by the LaTeX Project. Changes are
detailed in the documentation.

=================================================
## Code Repositories
=================================================

Code is hosted at 
	https://codeberg.org/cfr/nfssext
For convenience, the repository is mirrored at
  https://github.com/cfr42/nfssext

=================================================
## Contact Details
=================================================

Bug reports, feature requests etc.  should be filed at
  https://codeberg.org/cfr/nfssext/issues


Clea F. Rees 
Version 0.3
2025-02-21

=================================================
vim: et:tw=80:sw=0:
