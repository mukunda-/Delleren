-------------------------------------------------------------------------------
-- DELLEREN
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com) 
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

local Delleren = DellerenAddon

-------------------------------------------------------------------------------
local SOUND_LIST = {
	["FAIL"] = "Interface\\Addons\\Delleren\\sounds\\fail.ogg";
	["ASK"]  = "Interface\\Addons\\Delleren\\sounds\\ask.ogg";
	["HELP"] = "Interface\\Addons\\Delleren\\sounds\\help.ogg";
	["GOOD"] = "Interface\\Addons\\Delleren\\sounds\\good.ogg";
}

-------------------------------------------------------------------------------
function Delleren:PlaySound( sound )
	local s = SOUND_LIST[sound]
	if s == nil then return end
	
	-- todo: add sound channel to config
	PlaySoundFile( s, "Master" )
end
