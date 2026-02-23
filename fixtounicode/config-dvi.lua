-- $Id: config-dvi.lua 11674 2026-02-23 16:32:06Z cfrees $
-------------------------------------------------------------------------------
checkopts = "-interaction=nonstopmode --output-format=dvi"
checkengines = { "pdftex", "luatex" }
testfiledir = "testfiles-dvi"
test_order = {"log"}
checkruns = 1
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- vim: ts=2:sw=2:tw=80
