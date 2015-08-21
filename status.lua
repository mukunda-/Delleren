-------------------------------------------------------------------------------
-- DELLEREN
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com) 
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
DellerenAddon.Status = {

	-- indexed 1-4 in party (party1-4), and 1-40 in raid (raid1-40)
	players = {};
	
	-- players structure:
	-- players
	--   [1-40]
	--     guid = player guid
	--     subs = { subbed spells }
	--     [spellid]
	--
	
	-- list of spells subscribed to by the raid
	subs = {};
	
	-- subs filtered containing only spells that we know
	filtered_subs = {};
	
	MAX_SUBS = 16;
}

-------------------------------------------------------------------------------
local function GetPlayerIndex( unit )
	local a = UnitInRaid( unit )
	if a ~= nil then return a end
	if string.find( unit, "party" ) then
		
		return tonumber( string.sub( unit, 6 ) )
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
	
	-- filter bad or potentially malicious data
	if data.cds == nil then data.cds = {} end
	if data.sub == nil then data.sub = {} end
	if #data.sub > self.MAX_SUBS then return end
	if UnitGUID( unit ) == nil then return end
	
	-- convert data into friendly structure
	local p = {
		guid = UnitGUID( unit )
		
	}
	
	for i = 1,#data.cds,5 do
		
		-- unpack
		local spellid, duration, charges, maxcharges, time = 
					data.cds[i], data.cds[i+1], data.cds[i+2], 
					data.cds[i+3], data.cds[i+4]
		
		-- and store
		p[ spellid ] = {
			duration   = duration;
			charges    = charges;
			maxcharges = maxcharges;
			time       = time;
		}
	end
	
	local changed = false
	
	local original = self.players[index]
	
	if original.guid ~= p.guid then changed = true end
	
}
 
-------------------------------------------------------------------------------
function DellerenAddon:UpdateStatus()

	local subs = {}
	
	for i = 1,40 do
		local p = self.players[i]
		if p ~= nil then
			if p.guid ~= UnitGUID( "raid" .. k ) the
				self.players[i] = nil
			end
		end
	end
	
	for k,v in pairs( self.players ) do
		
		for k2,v2 in ipairs( v.subs ) do
			subs[v2] = true
		end
		
	end
	
	local newsubs = false
	for k,v in pairs( subs ) do
		if self.
	end	
end
