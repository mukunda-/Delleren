-------------------------------------------------------------------------------
-- Delleren
-- External CD caller.
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
--
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
DellerenAddon.Status = {

	-- indexed 1-4 in party (party1-4), and 1-40 in raid (raid1-40)
	players = {} 
	
	-- players structure:
	-- players
	--   [1-40]
	--     guid = player guid
	--     [spellid]
	--
	
	-- list of registered spells
	registered = {}
}

-------------------------------------------------------------------------------
local function GetPlayerIndex( unit )
	local a = UnitInRaid( unit )
	if a ~= nil then return a end
	if string.find( unit, "party" ) then
		-- TODO find real name of these functions
		return to_integer( string.sub( unit, 6 ) )
	end
	
	return nil
end

-------------------------------------------------------------------------------
-- Record the status of a player.
--
-- @param unit UnitID of player. Must be a party or raid unit ID.
-- @param data The data of the STATUS comm message.
--
function DellerenAddon.Status:UpdatePlayer( unit, data ) {
	local index = GetPlayerIndex( unit )
	if index == nil then return end
	
	
}
