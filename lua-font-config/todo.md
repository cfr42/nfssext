# TO DOs

These are not in any particular order, though there is some tendency for higher priority items to be earlier.

## Conceptual

  - Abandon the whole thing since packages are not supposed to meddle with fonts?

## NFSS

  - Multiple font configurations are now supported, but there is zero integration with e.g. for multiple languages with multiple scripts.
    
      - Support for `babel`?
        This!!!
      -[] `babel` provides e.g. `\babelfont`, which uses `\fontspec`.
        Should `lua-font-config` provide this?
    
 
## Interface

  - Provide a proper user interface (more similar to Con\TeX{}t, since we're using the same (MKIV) sorting?
    The interface is now not too dissimilar to a LaTeX-ified version of this, I suppose, except there are no goodies or pre-configured typefaces and our families are a bit richer and more flexible.
  - Information for user - a bit better now, hopefully, as we use the standard mechanisms, except for debug messages.
  - Accommodate `.ttc`. 
  
    - The basis is done, but not sure what, if any, interface is needed?
    - How to test this??
  

## Loader

  - Test with `.ttf`. 
    
      - What needs testing exactly??
        Or is this all on the loader?
    
  - Variable fonts.
    
      - How to do or test??
    
  - Colour. 
    Do??
    
      - What does ‘Do??’ refer to?
    
  - Cope with (text) symbol fonts?
    Not sure is that really needed?
  - Combo, fallback & all that.

## Cache

  - Cached data should depend on db/fnt versions.
    
      - Or is this automatic?
      - Or maybe it shouldn't?
    

## Documentation

  - Not everything implemented in terms of the UI is in the user doc.
  - The Lua code has some comments, but these don't always amount to documentation.
  - The overall infrastructure isn't really documented, except for a partially accurate ASCII database schema included inline.
  - Registered Lua functions mapped to `expl3` names are not documented.
  - Use of callbacks, hooks etc. is more-or-less undocumented.

## Code

  - Should be cleaned up -- I cannot need 2,500 lines to load a font!
  -[Unnumbered Gripe] The code is too long, too complex, too clunky and too simplistic.
     (Yes, of course, it can be both.)
  - Some remaining cleanup in the ConTeXt file, though this is much better than it was.
  - Lots of cleanup in the main module, which has got slightly tidier and then much more messy again.
  - Improve performance.
    
      - There is some duplication and too many pre-definitions for my taste.
    
  - Possibly modify database creation to avoid correcting the data again??

## Test suite

  - There are no unit tests (cf. `nfssext-cfr`, where the tests are much more focused).
    I don't know how to implement this for (non-public) Lua functions.
    
