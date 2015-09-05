-------------------------------------------------------------------------------
-- DELLEREN
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com) 
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
local SOUND_LIST = {
	["FAIL"] = "Interface\\Addons\\cdplease\\sounds\\fail.ogg";
	["ASK"]  = "Interface\\Addons\\cdplease\\sounds\\ask.ogg";
	["HELP"] = "Interface\\Addons\\cdplease\\sounds\\help.ogg";
	["GOOD"] = "Interface\\Addons\\cdplease\\sounds\\good.ogg";
}

-------------------------------------------------------------------------------
function DellerenAddon:PlaySound( sound )
	local s = SOUND_LIST[sound]
	if s == nil then return end
	
	-- todo: add sound channel to config
	PlaySoundFile( s, "Master" )
end
