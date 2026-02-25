-- $Id: config-dvi.lua 11691 2026-02-25 04:36:47Z cfrees $
--------------------------------------------------------------------------------
checkengines = { "pdftex", "luatex" }
checkformat = "latex"
checkopts = "--output-format dvi"
testfiledir =  "testfiles-dvi"
recordstatus = true
fnt.suppluafiles()
--------------------------------------------------------------------------------
-- vim: ts=2:sw=2:et:
