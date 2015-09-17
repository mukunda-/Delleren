-------------------------------------------------------------------------------
-- DELLEREN
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com) 
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

local Delleren = DellerenAddon

-------------------------------------------------------------------------------
Delleren.Status = {

	-- indexed 1-4 in party (party1-4), and 1-40 in raid (raid1-40)
	players = {};
	
	-- players structure:
	-- players
	--   [1-40] or [1-4] (party)
	--     guid = player guid
	--     subs = { subbed spell ids, sorted }
	--     spells[spellid] = { 
	--                         duration;   -- the length of the cd
	--                         charges;    -- number of charges that are ready
	--                         maxcharges; -- the max number of charges 
	--                         time;       -- time when the cooldown started
    --                       }
	--                         
	--
	
	-- combined list of spells subscribed to by the raid, sorted
	subs = {};
	submap = {};
	
	-- subs filtered containing only spells that we know, sorted
	fsubs = {};
	
	-- fsubs as a map indexed by spellid, subbed spells are set to true
	fsubmap = {};
	
	-- spells that we have subscribed to
	mysubs = {};
	
	-- program options
	MAX_SUBS = 16;
	
	sending = false;
	poll    = false;
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

--	if a.guid ~= b.guid then return true end
--	
--	if #a.subs ~= #b.subs then
--		return true
--	end
--	
--	-- subs are sorted.
--	for i = 1,#a.subs do
--		if b.subs[i] ~= a.subs[i] then return true end
--	end
	
--	for k,v in pairs( a.spells ) do
--		local v2 = b.spells[k]
--		if v2 == nil then return true end
--		
--		
--		if b.spells[k] == nil then return true end
--		if b.spells[
--	end
end

-------------------------------------------------------------------------------
-- Record the status of a player.
--
-- @param unit UnitID of player. Must be a party or raid unit ID.
-- @param data The data of the STATUS comm message.
--
function Delleren.Status:UpdatePlayer( unit, data )
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
	
	self.players[index] = p
	self:Refresh()
	
	if data.poll then
		self:Send()
	end
}

-------------------------------------------------------------------------------
-- Remove entries that do not match their player guid.
--
function Delleren.Status:PrunePlayers()
	if IsInRaid() then
		for i = 1,40 do
			local p = self.players[i]
			if p ~= nil then
				if p.guid ~= UnitGUID( "raid" .. k ) then
					self.players[i] = nil
				end
			end
		end
	else
		for i = 1,4 do
			local p = self.players[i]
			if p ~= nil then
				if p.guid ~= UnitGUID( "party" .. k ) then
					self.players[i] = nil
				end
			end
		end
	end
end

-------------------------------------------------------------------------------
-- Refresh the status data after receiving an update from a player.
--
function Delleren.Status:Refresh()
	
	local submap = {}
	
	self:PrunePlayers()
	
	for _,p in pairs( self.players ) do
		
		for k2,v2 in ipairs( p.subs ) do
			submap[v2] = true
		end
		
	end
	
	local subs = {}
	
	for _,spell in pairs( submap ) do
		table.insert( subs, spell )
	end
	
	-- needs to be sorted for certain optimizations
	table.sort( subs )
	self.subs = subs
	
	local mysubs = {}
	local mysubmap = {}
	
	-- set to true if new (known) subs were added to our list
	local newsubs = false
	
	-- build the new filtered sub list and map
	-- if there are new spells that werent there before, set the newsubs flag
	for _,spell in ipairs( subs ) do
		if IsSpellKnown( spell ) then
			if not self.fsubsmap[spell] then
				newsubs = true
			end
				
			table.insert( mysubs, spell )
			mysubmap[spell] = true
		end
	end
	
	self.fsubs   = mysubs
	self.fsubmap = mysubmap
	
	-- if there are new subs, send a status response.
	if newsubs then
		self:Send()
	end
end

-------------------------------------------------------------------------------
-- Send a status message to the raid. Will delay a while first.
--
function Delleren.Status:Send( poll )
	if self.sending then return end
	
	self.sending = true
	self.poll    = poll
	
	Delleren:ScheduleTimer( "SendStatusDelayed", 5 )
end

-------------------------------------------------------------------------------
function Delleren:SendStatusDelayed()
	self.Status.SendDelayed()
end

-------------------------------------------------------------------------------
-- Actual sending function, delayed.
--
function Delleren.Status:SendDelayed()
	
	-- build status message
	local data = {}
	
	data.cds = {}
	data.sub = {}
	data.poll = self.poll
	
	for _,spellid in ipairs(self.fsubs) do
		if IsSpellKnown( spellid ) then
			
			
			-- spellid, duration, charges, maxcharges, time 
			local sp_id, sp_duration, sp_charges, sp_maxcharges, sp_time
			sp_id = spellid
			
			do
				local cd_start, cd_duration = GetSpellCooldown( spellid )
				sp_duration = GetSpellBaseCooldown( spellid )
				
				-- TODO, get actual CD including talents and stuff
				
				local charges, maxcharges, start, duration2 = GetSpellCharges( spellid )
				-- todo
				
				if charges ~= nil then
					-- charge based spell
					
					sp_duration   = duration2
					sp_charges    = charges
					sp_maxcharges = maxcharges
					if charges ~= maxcharges then
						v5 = start + duration
					else
						v5 = 0
					end
				else
					-- normal spell
					
					if cd_duration <= 1.51 then 
						-- it is off cooldown, or it is a GCD cooldown 
						--                         (treat as off still)
						
						sp_charges = 1
						sp_time = 0
					else

						sp_charges = 0
						sp_time = cd_start + cd_duration
						sp_duration = cd_duration
					end
					
					sp_maxcharges = 1
				end
			end
			
			-- pack into data
			table.insert( data.cds, sp_spellid    )
			table.insert( data.cds, sp_duration   )
			table.insert( data.cds, sp_charges    )
			table.insert( data.cds, sp_maxcharges )
			table.insert( data.cds, sp_time       )
		end
	end
	
	-- send status message
	for _,spellid in ipairs( self.mysubs ) do
		table.insert( data.sub, spellid )
	end
	
	Delleren:Comm( "STATUS", data, "RAID" )
end

-------------------------------------------------------------------------------
-- Returns true if a spell is subbed by the raid.
--
function Delleren.Status:IsSubbed( spell )
	return self.submap[spell]
end

-------------------------------------------------------------------------------
-- Check if a spell has come off of cooldown and add a charge for it.
--
function Delleren.Status:UpdateSpellCooldown( sp )

	while sp.charges < sp.maxcharges do
		if GetTime() > sp.time + sp.duration then
			sp.time = sp.time + sp.duration
			sp.charges = sp.charges + 1
			if sp.charges >= sp.maxcharges then
				sp.charges = sp.maxcharges -- redundant
				sp.time = 0
			end
		end
	end
end

-------------------------------------------------------------------------------
-- Called when a spell is used by a player.
--
-- @param spell ID of spell used.
-- @param unit UnitID of player.
--
function Delleren.Status:OnSpellUsed( spell, unit )
	
	local p = self:GetPlayerData( unit )
	if p == nil then return end
	
	-- we have data for this player
	local sp = p.spells[spell]
	if sp then
		-- we have data for the spell that they cast
		
		-- add new spell charges
		local time = GetTime()
		self:UpdateSpellCooldown( sp )
		
		-- use a charge, and reset the time if there's a time error
		-- or if the time isn't set
		sp.charges = sp.charges - 1
		if sp.charges < 0 then 
			sp.charges = 0 
			sp.time = time
		else
			if sp.time == 0 then
				sp.time = GetTime()
			end
		end
		
		-- todo: update cooldown bar
	end

end

-------------------------------------------------------------------------------
-- Checks if a player has a spell ready.
--
-- @param unit unitID of player to check.
-- @param list List of spells to check for, they must be subscribed.
--
-- @returns spell ID of a spell that is ready or nil if none are available.
--
function Delleren.Status:HasSpellReady( unit, list )

	local p = self:GetPlayerData( unit )
	if p == nil then return nil end
	
	for _,spell in ipairs( list )
		local sp = p.spells[spell]
		if sp then
			self:UpdateSpellCooldown( sp )
			if sp.charges >= 1 then
				return spell
			end
		end
	end
	
	-- no spells available
	return nil
end

-------------------------------------------------------------------------------
-- Get status data from a unitid
--
function Delleren.Status:GetPlayerData( unit )
	local index = GetPlayerIndex( unit )
	if not index then return nil end
	
	local p = self.players[index]
	if p == nil then return nil end
	
	if p.guid ~= UnitGUID( unit ) then
		self.players[index] = nil
		return nil
	end
	
	return p
end
