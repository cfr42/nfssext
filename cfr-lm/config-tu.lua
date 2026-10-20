-- $Id: config-tu.lua 12136 2026-10-19 02:33:02Z cfrees $
--------------------------------------------------------------------------------
checkengines = { "luatex" }
testfiledir =  "testfiles-tu"
--------------------------------------------------------------------------------
fnt.checksuppfiles_add = fnt.checksuppfiles_add or {}
local str = kpse.var_value("TEXMFDIST")
-- if string.match(str,"%-") then str = string.gsub(str,"%-","%%-") end
-- print(str)
if direxists(str .. "/fonts/opentype/public/lm") then
  for _,i in ipairs(filelist(str .. "/fonts/opentype/public/lm", "lmroman*")) do
    table.insert(fnt.checksuppfiles_add, "/fonts/opentype/public/lm/" .. i)
  end
end
-- table.insert(fnt.checksuppfiles_add, "/tex/latex/base/tulmr.fd")
local checksuppfiles_add = {
  "lmmono10-italic.otf",
  "lmmono10-regular.otf",
  "lmmono12-regular.otf",
  "lmmono8-regular.otf",
  "lmmono9-regular.otf",
  "lmmonocaps10-oblique.otf",
  "lmmonocaps10-regular.otf",
  "lmmonolt10-bold.otf",
  "lmmonolt10-boldoblique.otf",
  "lmmonolt10-oblique.otf",
  "lmmonolt10-regular.otf",
  "lmmonoltcond10-oblique.otf",
  "lmmonoltcond10-regular.otf",
  "lmmonoprop10-oblique.otf",
  "lmmonoprop10-regular.otf",
  "lmmonoproplt10-bold.otf",
  "lmmonoproplt10-boldoblique.otf",
  "lmmonoproplt10-oblique.otf",
  "lmmonoproplt10-regular.otf",
  "lmmonoslant10-regular.otf",
  "lmroman10-bold.otf",
  "lmroman10-bolditalic.otf",
  "lmroman10-italic.otf",
  "lmroman10-regular.otf",
  "lmroman12-bold.otf",
  "lmroman12-italic.otf",
  "lmroman12-regular.otf",
  "lmroman17-regular.otf",
  "lmroman5-bold.otf",
  "lmroman5-regular.otf",
  "lmroman6-bold.otf",
  "lmroman6-regular.otf",
  "lmroman7-bold.otf",
  "lmroman7-italic.otf",
  "lmroman7-regular.otf",
  "lmroman8-bold.otf",
  "lmroman8-italic.otf",
  "lmroman8-regular.otf",
  "lmroman9-bold.otf",
  "lmroman9-italic.otf",
  "lmroman9-regular.otf",
  "lmromancaps10-oblique.otf",
  "lmromancaps10-regular.otf",
  "lmromandemi10-oblique.otf",
  "lmromandemi10-regular.otf",
  "lmromandunh10-oblique.otf",
  "lmromandunh10-regular.otf",
  "lmromanslant10-bold.otf",
  "lmromanslant10-regular.otf",
  "lmromanslant12-regular.otf",
  "lmromanslant17-regular.otf",
  "lmromanslant8-regular.otf",
  "lmromanslant9-regular.otf",
  "lmromanunsl10-regular.otf",
  "lmsans10-bold.otf",
  "lmsans10-boldoblique.otf",
  "lmsans10-oblique.otf",
  "lmsans10-regular.otf",
  "lmsans12-oblique.otf",
  "lmsans12-regular.otf",
  "lmsans17-oblique.otf",
  "lmsans17-regular.otf",
  "lmsans8-oblique.otf",
  "lmsans8-regular.otf",
  "lmsans9-oblique.otf",
  "lmsans9-regular.otf",
  "lmsansdemicond10-oblique.otf",
  "lmsansdemicond10-regular.otf",
  "lmsansquot8-bold.otf",
  "lmsansquot8-boldoblique.otf",
  "lmsansquot8-oblique.otf",
  "lmsansquot8-regular.otf",
}
fnt.checksuppfiles_add = fnt.checksuppfiles_add or {}
for _,i in ipairs(checksuppfiles_add) do table.insert(fnt.checksuppfiles_add, i) end
fnt.suppluafiles()
--------------------------------------------------------------------------------
fnt.fnttestfds = {}
for _,i in ipairs(fnt.autotestfds) do
  if string.match(i, "^t1") then
    table.insert(fnt.fnttestfds, (string.gsub(i, "t1", "tu")))
  end
end
--------------------------------------------------------------------------------
-- vim: ts=2:sw=2:et:
