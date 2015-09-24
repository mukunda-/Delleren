-------------------------------------------------------------------------------
-- DELLEREN
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com) 
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

local Delleren = DellerenAddon

-------------------------------------------------------------------------------
Delleren.Status = {

	-- indexed by player name
	players = {};
	
	-- players structure:
	-- players
	--   [playername]
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
	subs     = {};
	submap   = {};
	
	-- subs filtered containing only spells that we know, sorted
	fsubs    = {};
	
	-- fsubs as a map indexed by spellid, subbed spells are set to true
	fsubmap  = {};
	
	-- spells that we have subscribed to
	mysubs   = {};
	mysubmap = {};
	
	-- program options
	MAX_SUBS = 16;
	
	refresh = {
		queued = false; -- refresh operation is queued
		send   = false; -- send status message after
		subs   = false; -- rebuild sub data
	};
	
	sending    = false;
	poll       = false;
	
	reloaded   = true;
}

-------------------------------------------------------------------------------
-- Record the status of a player.
--
-- @param name Name of player. (sender)
-- @param data The data of the STATUS comm message.
--
function Delleren.Status:UpdatePlayer( name, data )

	print( "STATUS", name, #data.cds, #data.sub, data.poll )
	for i = 1,#data.cds,5 do
		print( data.cds[i], data.cds[i+1], data.cds[i+2], data.cds[i+3], data.cds[i+4] )
	end
	
	print( "SUBS", data.sub[1], data.sub[2], data.sub[3], data.sub[4], data.sub[5], data.sub[6], data.sub[7] )
	
	-- filter bad or potentially malicious data
	if data.cds == nil then data.cds = {} end
	if data.sub == nil then data.sub = {} end
	if #data.sub > self.MAX_SUBS then return end
	if not UnitInParty( name ) then return end -- who is this?!
	if name == UnitName( "player" ) then return end
	
	-- convert data into friendly structure
	local p = {
		spells = {};
		subs   = {};
		time   = GetTime();
	}
	
	for i = 1,#data.cds,5 do
		
		-- unpack
		local spellid, duration, charges, maxcharges, time = 
					data.cds[i], data.cds[i+1], data.cds[i+2], 
					data.cds[i+3], data.cds[i+4]
		
		-- and store
		p.spells[ spellid ] = {
			duration   = duration / 1000;
			charges    = charges;
			maxcharges = maxcharges;
			time       = time;
		}
	end
	
	for k,v in ipairs( data.sub	) do
		table.insert( p.subs, v )
	end
	
	table.sort( p.subs )
	
	self.players[name] = p
	self:Refresh( true, data.poll )
end

-------------------------------------------------------------------------------
-- Queue a status refresh.
--
-- @param subs Rebuild subscription data.
-- @param send Force send a status message afterwards.
--
function Delleren.Status:Refresh( subs, send )
	if subs then self.refresh.subs = true end
	if send then self.refresh.send = true end
	
	if not self.refresh.queued then
		self.refresh.queued = true
		Delleren:ScheduleTimer( 
			function() 
		        Delleren.Status:DoRefresh() 
			end, 1 )
	end
end

-------------------------------------------------------------------------------
-- Remove entries in the status table that are no longer in the party.
--
function Delleren.Status:PrunePlayers()
	
	for name,_ in pairs( self.players ) do
		if not UnitInParty( name ) then
			self.players[name] = nil
		end
	end
end

-------------------------------------------------------------------------------
-- Returns a table of all spells subbed by the raid.
--
function Delleren.Status:MergeSubLists()
	-- merge all sublists from each player into one sub list
	local submap = {}
	local subs   = {}
	
	for _,p in pairs( self.players ) do 
		for _,v2 in pairs( p.subs ) do
			submap[v2] = true
		end 
	end
	
	for spell,_ in pairs( submap ) do
		table.insert( subs, spell )
	end
	
	-- needs to be sorted for certain optimizations
	table.sort( subs )
	
	return subs, submap
end

-------------------------------------------------------------------------------
function Delleren.Status:DoRefresh()
	self:PrunePlayers()
	
	self.subs, self.submap = self:MergeSubLists()
	
	local fsubs   = {}
	local fsubmap = {}
	
	local newsubs = false -- flag if new (known) subs were added to our list
	
	-- build the new filtered sub list and map
	-- if there are new spells that weren't there before, set the newsubs flag
	for _,spell in ipairs( self.subs ) do
		if IsSpellKnown( spell ) then
			if not self.fsubmap[spell] then
				newsubs = true
			end
				
			table.insert( fsubs, spell )
			fsubmap[spell] = true
		end
	end
	
	self.fsubs   = fsubs
	self.fsubmap = fsubmap
	
	-- if there are new subs or a poll was requested, send a status response.
	if newsubs or self.refresh.send then
		self:Send()
	end
	
	self.refresh.queued = false
	self.refresh.subs   = false
	self.refresh.send   = false
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
	self.Status:SendDelayed()
end

-------------------------------------------------------------------------------
-- Actual sending function, delayed.
--
function Delleren.Status:SendDelayed()
	print( "DEBUG: sending status" )
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
						sp_time = start + duration
					else
						sp_time = 0
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
	
	self.sending = false
	self.poll    = false
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
		else
			break
		end
		
	end
end

-------------------------------------------------------------------------------
-- Called when a spell is used by a player.
--
-- @param unit  UnitID of player.
-- @param spell ID of spell used.
--
function Delleren.Status:OnSpellUsed( unit, spell )
	
	-- check if we have a raid# unitid if in a raid, or a party# unitid 
	-- if not in a raid, the same spellcast may trigger multiple events
	-- with different unitids
	
	if ( IsInRaid() and string.find(unit, "raid") 
	                and not string.find( unit, "target" ))
					   
	        or (not IsInRaid() and string.find( unit, "party" )
                               and not string.find( unit, "target" )) then
	   
		unit = UnitName( unit )
	else
		return -- not in party.
	end
	
	local p = self.players[unit]
	if not p then return end
	
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

	local p = self.players[UnitName(unit)]
	if not p then return nil end
	
	for _,spell in ipairs( list ) do
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
function Delleren.Status:NewGroup()

	-- discard old player data
	self.players = {}
	
	-- send status to everyone and request theirs
	self:Send( true )
end

-------------------------------------------------------------------------------
function Delleren.Status:UpdateTrackingConfig( dontsend )
	self.mysubs = {}
	self.mysubmap = {}
	
	for k,v in ipairs( Delleren.Config.tracked_spell_data ) do
		table.insert( self.mysubs, v.spell )
		self.mysubmap[v.spell] = true
	end
	
	if not dontsend then
		self:Send()
	end
end
