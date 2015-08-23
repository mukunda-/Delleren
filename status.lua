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
	--     subs = { subbed spell ids, sorted }
	--     spells[spellid] = { spell info: duration,charges,maxcharges,time }
	--
	
	-- combined list of spells subscribed to by the raid
	subs = {};
	
	-- subs filtered containing only spells that we know
	filtered_subs = {};
	
	-- program options
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
-- Compare two status blocks to see if they are the same.
--
-- @param a,b Two converted status messages.
-- @returns true if they are different.
--
local function CompareStatus( a, b )
	if a.guid ~= b.guid then return true end
	
	if #a.subs ~= #b.subs then
		return true
	end
	
	-- subs are sorted.
	for i = 1,#a.subs do
		if b.subs[i] ~= a.subs[i] then return true end
	end
	
	for k,v in pairs( a.spells ) do
		local v2 = b.spells[k]
		if v2 == nil then return true end
		
		
		if b.spells[k] == nil then return true end
		if b.spells[
	end
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
	if UnitGUID( unit ) == UnitGUID( "player" ) then return end
	
	-- convert data into friendly structure
	local p = {
		guid   = UnitGUID( unit )
		spells = {}
		subs   = {}
	}
	
	for i = 1,#data.cds,5 do
		
		-- unpack
		local spellid, duration, charges, maxcharges, time = 
					data.cds[i], data.cds[i+1], data.cds[i+2], 
					data.cds[i+3], data.cds[i+4]
		
		-- and store
		p.spells[ spellid ] = {
			duration   = duration;
			charges    = charges;
			maxcharges = maxcharges;
			time       = time;
		}
	end
	
	for k,v in ipairs( data.sub	) do
		table.insert( p.subs, v )
	end
	
	table.sort( p.subs )
	
	if not CompareStatus( p, self.players[index] ) then
		self.players[index] = p
		self:Refresh()
	end
}

-------------------------------------------------------------------------------
function DellerenAddon:Status.Refresh()
	
	local subs = {}
	
	for i = 1,40 do
		local p = self.players[i]
		if p ~= nil then
			if p.guid ~= UnitGUID( "raid" .. k ) then
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
