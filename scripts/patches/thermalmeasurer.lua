--[[
Dependencies:
none
]]

-- Not needed, it's imported from below this in the modmain
-- if not GLOBAL.TheNet:GetIsServer() then return end

GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.WINTEROMETER = {
	"I'd better wear something warm!",
	"I might need a sweater.",
	"it's a bit chilly.",
	"nice weather.",
	"it's a bit hot.",
	"I should keep out of the sun.",
	"I'd better bring something cold with me.",
}
GLOBAL.STRINGS.CHARACTERS.WILLOW.DESCRIBE.WINTEROMETER = {
	"Let's light a raging fire to stay warm!",
	"cold enough to light a bonfire.",
	"there's a chilly breeze.",
	"the weather is nice enough.",
	"there's a hot breeze.",
	"I could get a sunburn... I prefer other kinds of burning.",
	"too hot to even think about fire.",
}
GLOBAL.STRINGS.CHARACTERS.WOLFGANG.DESCRIBE.WINTEROMETER = {
	"need very warm hat!",
	"need warm hat!",
	"is chilly.",
	"is good weather.",
	"is hot.",
	"sun is stronger than Wolfgang today.",
	"sky is like fire!",
}
GLOBAL.STRINGS.CHARACTERS.WENDY.DESCRIBE.WINTEROMETER = {
	"the air is colder than my heart...",
	"I'll need something to stave off the cold.",
	"I feel a chill.",
	"perfectly boring weather.",
	"it's rather warm.",
	"it's miserably hot out.",
	"I shall perish without something to cool me down...",
}
GLOBAL.STRINGS.CHARACTERS.WX78.DESCRIBE.WINTEROMETER = {
	"TEMPERATURE: EXTREMELY LOW",
	"TEMPERATURE: MODERATELY LOW",
	"TEMPERATURE: LOW",
	"TEMPERATURE: ACCEPTABLE",
	"TEMPERATURE: HIGH",
	"TEMPERATURE: MODERATELY HIGH",
	"TEMPERATURE: EXTREMELY HIGH",
}
GLOBAL.STRINGS.CHARACTERS.WICKERBOTTOM.DESCRIBE.WINTEROMETER = {
	"we'll need a hot fire and plenty of warm clothing!",
	"a warm sweater might be in order.",
	"it's rather chilly.",
	"lovely weather.",
	"it's rather hot.",
	"it's positively sweltering.",
	"we'll require some sort of endothermic reaction to survive this heat!",
}
--TODO
GLOBAL.STRINGS.CHARACTERS.WOODIE.DESCRIBE.WINTEROMETER = {
	"brr! Quite the freeze.",
	"I'll need something warmer than plaid today.",
	"plaid's warm enough for this weather.",
	"nice weather, eh?",
	"it's a tad hot out.",
	"I should get something to keep the sun off my head.",
	"hotter than a burning forest!",
}
GLOBAL.STRINGS.CHARACTERS.WAXWELL.DESCRIBE.WINTEROMETER = {
	"glacial temperatures.",
	"the cold is less fun when I'm the one subjected to it.",
	"colder than I'd like.",
	"completely ordinary weather.",
	"hotter than I'd like.",
	"dreadfully hot.",
	"infernal temperatures.",
}
GLOBAL.STRINGS.CHARACTERS.WATHGRITHR.DESCRIBE.WINTEROMETER = {
	"I shall warm myself with the fury of combat!",
	"the forces of winter are upon us.",
	"Skadi has sent us chilling warnings.",
	"excellent weather for a brawl!",
	"it's a bit toasty.",
	"this heat is unbearable, even for a warrior.",
	"the world is not ready for Surtr's flames!",
}
GLOBAL.STRINGS.CHARACTERS.WEBBER.DESCRIBE.WINTEROMETER = {
	"if only we had my father's fur coat!",
	"a silky beard might be enough.",
	"chilly.",
	"the best weather!",
	"it's a bit hot.",
	"our fur is too warm for this weather.",
	"jeepers, it's hot!",
}

--Make Thermal Measurer tell the actual temperature
local function GetWorldTemperature(inst, viewer)
	-- print(viewer.prefab:upper(), GLOBAL.STRINGS.CHARACTERS[viewer.prefab:upper()])
	local strings = GLOBAL.STRINGS.CHARACTERS[viewer.prefab:upper()] or GLOBAL.STRINGS.CHARACTERS.GENERIC
	strings = strings.DESCRIBE.WINTEROMETER
	if type(strings) ~= "table" or #strings < 7 then
		--custom character which doesn't have the new strings, default to Wilson
		strings = GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.WINTEROMETER
	end
	local temp =  math.floor(GLOBAL.TheWorld.state.temperature + 0.5)
	local str = temp .. "\176, "
	if temp < -10 then
		str = str .. strings[1]
	elseif temp < 0 then
		str = str .. strings[2]
	elseif temp < 10 then
		str = str .. strings[3]
	elseif temp < 60 then
		str = str .. strings[4]
	elseif temp < 70 then
		str = str .. strings[5]
	elseif temp < 80 then
		str = str .. strings[6]
	else
		str = str .. strings[7]
	end
	return str
end

AddPrefabPostInit("winterometer", function(inst)
	inst.components.inspectable.getspecialdescription = GetWorldTemperature
end)