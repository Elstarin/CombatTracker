local http = require "socket.http"
local json = require "json"

local outFile = io.open("CSC.lua", "w")
if not outFile then
	print("CANT OPEN OUTFILE")
end

local out = "local Cache = {\n"

local blacklist = {
	[165201] = true,
}

out = out .. "\t[" .. 1 .. "] = {"

local content = http.request("http://www.wowhead.com/class=" .. 1)

local data = json.decode(content:match("name: LANG.tab_spells.-data: (%b[])"), nil)
for k, v in pairs(data) do
	if v.cat == 7 or v.cat == -12 or v.cat == -2 and not blacklist[v.id] then
		local spellContent = http.request("http://www.wowhead.com/spell=" .. v.id)
		local reductionTypes, damageReduction = spellContent:match("Mod %% Damage Taken (%b())<small><br />Value: -(%-%d+)%%") -- (%-%d+)%%

		if reductionTypes == "(Arcane, Fire, Frost, Holy, Nature, Physical, Shadow)" then
			reductionTypes = "All"
		end
		-- if matchedValue then
		-- 	local damageReduction = json.decode(matchedValue, nil) -- Mod % Damage Taken.(%d+)
		-- end
		print("PRINT", reductionTypes, damageReduction)
		if damageReduction then
			out = out .. v.id .. ", " .. damageReduction .. "%,"
		else
			out = out .. v.id .. ","
		end
	end
	break
end

out = out .. "},\n"

print(out)

outFile:write(out)

Cat 7 is abilities
Cat -14 is perks
Cat -13 is glyphs
Cat -12 is specializations
Cat -11 is proficiencies, like weapon and armour types that can be used
Cat -2 is talents
for monk, default URL for spell list is http://www.wowhead.com/class=10/monk#spells, but adding :spec=268 specifies brewmaster spells
http://www.wowhead.com/class=10/monk#spells:type=-14:spec=268 is brewmaster perks, since -14 is perks and spec 268 is brewmaster
All abilities, Cat 7, seem to be completely shared, at least in the case of monks
Many glyphs and talents are also shared
When filtered for any spec, talents seem to only show their level 100 ones. Is that because those are the only ones that change spec to spec
