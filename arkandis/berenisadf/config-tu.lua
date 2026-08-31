-- $Id: config-tu.lua 11968 2026-06-10 00:56:50Z cfrees $
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
fnt.suppluafiles()
--------------------------------------------------------------------------------
fnt.fnttestfds = {}
for _,i in ipairs(fnt.autotestfds) do
  if string.match(i, "^ly1") then
    table.insert(fnt.fnttestfds, (string.gsub(i, "ly1", "tu")))
  end
end
-- --------------------------------------------------------------------------------
-- function normalize_log_hook(line)
--   if string.match(line, "^ *luaotfload") then
--     line = (string.gsub(line, "%(function: 0x[a-z0-9]*%)", "(function: 0x...)"))
--   end
--   return line
-- end
--------------------------------------------------------------------------------
-- vim: ts=2:sw=2:et:
