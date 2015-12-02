-------------------------------------------------------------------------------
-- DELLEREN
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com) 
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

local Delleren = DellerenAddon

local PLAYER_TIMEOUT_LENGTH = 60
local PING_TIMEOUT          = 180
local PING_REFRESH_TIME     = 60

local WAITINSPECT_NEW       = 30
local INSPECT_AGAIN_DELAY   = 30

-------------------------------------------------------------------------------
Delleren.Status = {

	-- indexed by player name
	players = {};
	
	--[[
	PLAYERS STRUCTURE:

	[playername]
		version  = delleren version, nil if not installed
		protocol = protocol version
		compat   = if they have delleren installed and are compatible with us
		loaded   = if player info is upto date
		ignore   = if the player is ignored by the system
		spec     = spec id
		talents  = talentstring 
		glyphs   = glyph list
		timeout  = time when their timeout expires, 
		          timeout is set when they dont respond to a help request
		time     = last ping or status time from another player using delleren
		waitinspect = time to wait until before inspecting them
		if spec, talents or glyphs changes, then the spells table is rebuilt
		
		-- spell table:
		spells[spellid] = {
			cd;         -- cd duration
			charges;    -- number of charges that are ready
			maxcharges; -- the max number of charges 
			time;       -- time when the cooldown started
		}
	    one spell entry is created per spell found in the spell data  
	]]
	
--	refresh = {
--		queued = false; -- refresh operation is queued
--		send   = false; -- send status message after 
--	};
	
	send = {
		queued = false; -- send operation is queued
		poll   = false; -- ask for other player status
	};
	
	lastping    = GetTime();
	
	myspec      = nil;
	mytalents   = nil;
	myglyphs    = nil;
	myserial    = 1;
	
	-- tracked spells
	mysubs      = {};
	mysubmap    = {};
	
	prune_time  = GetTime();
	scan_time   = GetTime();
	scan_index  = 1;
}

-------------------------------------------------------------------------------
-- Return player status data.
--
-- @param name   Name of player.
-- @param create Create an entry if they don't exist.
--
function Delleren.Status:GetPlayerData( name, create )
	local p = self.players[name]
	if not p and create then
		p = {
			loaded      = false;
			ignore      = Delleren.Ignore.ignored[name];
			spec        = GetInspectSpecialization( name );
			talents     = "?";
			glyphs      = {};
			serial      = 0;
			name        = name;
			
			spells      = {};
			time        = GetTime();
			waitinspect = GetTime() + WAITINSPECT_NEW;
			timeout     = 0;
		}
		 
		self:BuildSpellsTable( p )
		
		self.players[name] = p
	end
	
	return p
end

-------------------------------------------------------------------------------
local function TablesDiffer( a, b )
	if #a ~= #b then return true end
	
	for i = 1, #a do
		if a[i] ~= b[i] then return true end
	end
	
	return false
end

-------------------------------------------------------------------------------
function Delleren.Status:SetIncompatible( name, data )
	local p = self:GetPlayerData( name, true )
	p.protocol = data.pv
	p.version  = data.v 
end

-------------------------------------------------------------------------------
-- Record the status of a player.
--
-- @param name Name of player. (sender)
-- @param data The data of the STATUS comm message.
--
function Delleren.Status:UpdatePlayer( name, data )
 

	-- filter bad or potentially malicious data
	if not UnitInParty( name ) then return end -- unknown source!
	if name == UnitName( "player" ) then return end
	
	-- convert data into friendly structure
	local p = self:GetPlayerData( name, true )
	p.compat  = true
	p.version = data.v
	p.time    = GetTime()
	p.loaded  = true
	p.protocol = data.pv
	
	if p.spec ~= data.s or p.talents ~= data.t
       or TablesDiffer( p.glyphs, data.g ) then
	
		p.spec    = data.s
		p.talents = data.t
		p.glyphs  = data.g -- make sure this is immutable!
		
		self:BuildSpellsTable( p )
	end
	
	if data.p then
		self:Send()
	end
	--self:Refresh( data.poll )
end

-------------------------------------------------------------------------------
function Delleren.Status:UpdatePlayerFromInspect( name, data ) 
	if not UnitInParty( name ) then return end -- unknown source!
	if name == UnitName( "player" ) then return end
	
	local p = self:GetPlayerData( name, true )
	
	if p.spec ~= data.spec or p.talents ~= data.talents 
	   or p.glyphs ~= data.glyphs then
	
		p.spec    = data.spec
		p.talents = data.talents
		p.glyphs  = data.glyphs
		
		self:BuildSpellsTable( p )
	end
	
	p.loaded = true
	
	--self:Refresh()
end

-------------------------------------------------------------------------------
-- Construct or update the player spells table.
--
-- @param player Player status data.
--
function Delleren.Status:BuildSpellsTable( player )
	
	local _,cls = UnitClass( player.name )
	
	local spells = Delleren.SpellData:GetSpells( cls, player.spec,
												 player.talents, 
												 player.glyphs )
												 
	for k,v in pairs( spells ) do
		
		local old = player.spells[k]
		if old then
			v.time    = old.time
			v.charges = old.charges
		else
			v.time    = 0
			v.charges = v.maxcharges
		end
	end
	
	player.spells = spells
end

-------------------------------------------------------------------------------
-- Queue a status refresh.
--
-- @param send Force send a status message afterwards.
--
--[[
function Delleren.Status:Refresh( send )
	if send then self.refresh.send = true end
	
	if not self.refresh.queued then
		self.refresh.queued = true
		Delleren:ScheduleTimer( 
			function() 
		        Delleren.Status:DoRefresh() 
			end, 1 )
	end
end]]

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
--[[
-------------------------------------------------------------------------------
function Delleren.Status:DoRefresh()
	--self:PrunePlayers() TODO move this to a routine function
	 
	-- if there are new subs or a poll was requested, send a status response.
	if self.refresh.send then 
		self:Send()
	end
	
	self.refresh.queued = false
	self.refresh.send   = false
end]]

-------------------------------------------------------------------------------
-- Send a status message to the raid. Will delay a while first.
--
function Delleren.Status:Send( poll ) 

	if poll then self.send.poll = true end
	
	if not self.send.queued then
		self.send.queued = true
		Delleren:ScheduleTimer( function() Delleren.Status:SendDelayed() end, 2 )
	end
end

-------------------------------------------------------------------------------
-- Actual sending function, delayed.
--
function Delleren.Status:SendDelayed()
	 
	-- build status message
	local data = {
		z = self.myserial;
		s = self.myspec;
		t = self.mytalents;
		g = self.myglyphs;
		p = self.send.poll;
		v = Delleren.version;
	} 
	
	Delleren:Comm( "STATUS", data, "RAID" )
	
	self.send.queued = false
	self.send.poll   = false
	self.lastping    = GetTime()
end

-------------------------------------------------------------------------------
function Delleren.Status:CheckPlayer( name ) 
	local player = self:GetPlayerData( name, true )
	
	-- 10 seconds have passed and we haven't received data from the player yet
	--
	if not player.loaded and GetTime() > player.waitinspect  
	   and UnitIsConnected( name ) then
		if Delleren.Inspect:TryStart( name ) then
			player.waitinspect = GetTime() + INSPECT_AGAIN_DELAY
		end
	end
end

-------------------------------------------------------------------------------
function Delleren.Status:PeriodicRefresh()

	local time = GetTime()

	if time >= self.prune_time 
	   and not UnitAffectingCombat( "player" ) then
	   
	    -- 5 minutes have passed since last prune and we aren't in combat.
		self.prune_time = time + 5 * 60
		self:PrunePlayers()
		
	end
	
	if time >= self.scan_time then
		self.scan_time = time + 0.1
		self.scan_index = self.scan_index + 1
		
		local unitid 
		
		if IsInRaid() then
			if not UnitExists( "raid" .. self.scan_index ) then
				self.scan_index = 1
			end
			
			unitid = "raid" .. self.scan_index 
		else
			if not UnitExists( "party" .. self.scan_index ) then
				self.scan_index = 1
			end
			
			unitid = "party" .. self.scan_index
		end
		
		if UnitExists( unitid ) 
		   and UnitGUID( unitid ) ~= UnitGUID( "player" ) then
		
			self:CheckPlayer( Delleren:UnitFullName( unitid ))
		end
	end
end
 
-------------------------------------------------------------------------------
-- Notify system that a player has changed their talents.
--
-- @param name        Name of player.
-- @param waitinspect Seconds to wait before inspecting them.
--
function Delleren.Status:PlayerTalentsChanged( name, waitinspect )
	local player = self:GetPlayerData( name )
	if not player then return end
	
	if not player.compat then
		player.loaded = false
		player.waitinspect = GetTime() + (waitinspect or 0)
	end
end

-------------------------------------------------------------------------------
-- Check if a spell has come off of cooldown and add a charge for it.
--
function Delleren.Status:UpdateSpellCooldown( sp )
 
	while sp.charges < sp.maxcharges do
		if GetTime() > sp.time + sp.cd then
			sp.time = sp.time + sp.cd
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
function Delleren.Status:OnSpellUsed( unit, spell, half )
	
	unit = Delleren:UnitFullName( unit )
	
	local p = self.players[unit]
	if not p then return end
	
	-- we have data for this player
	local sp = p.spells[spell]
	if sp then
		
		-- we are tracking the spell that they cast.
		
		if sp.maxcharges == 1 then
			-- easy non-charge mode
			sp.charges = 0
			sp.time = GetTime()
			
			if half then sp.time = sp.time - sp.cd/2 end
		else
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
			
			if half then sp.time = sp.time - sp.cd/2 end
		end
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

	local p = self.players[Delleren:UnitFullName(unit)]
	if not p then return nil end
	
	if p.ignore then 
		-- ignore ping timeout player
		return nil 
	end	
	
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
-- Read tracked spell list/data from the config module.
--
-- @param dontsend Prevent sending a STATUS message. (useful during plugin load
--                 when you want to delay.)
--
function Delleren.Status:UpdateTrackingConfig( dontsend )
	self.mysubs = {}
	self.mysubmap = {}
	
	for k,v in ipairs( Delleren.Config.tracked_spell_data ) do
		table.insert( self.mysubs, v.spell )
		self.mysubmap[v.spell] = true
	end
end

-------------------------------------------------------------------------------
function Delleren.Status:BuildCDBarData()

	local datamap = {}
	
	for k,v in pairs( self.mysubs ) do
		datamap[v] = { spell = spellid, 
				    stacks = 0, 
					time = 999, -- cd time remaining (find lowest)
					duration = 0, 
					outrange_cd = true,
					outrange_ready = true,
					value = 0 }
	end
	
	-- values:
	-- 0 = dont show (not available by any player)
	-- 1 = all players who can provide it are dead (show as disabled)
	-- 2 - on cooldown and out of range (show cd overlay and color red)
	-- 3 - on cooldown and in range (show cd overlay and color normal)
	-- 4 - ready and out of range (color red, show stacks) 
	-- 5 - ready and in range (color normal, show stacks)
	
	for playername in Delleren:IteratePlayers() do
		local player = self.players[playername]
		if player ~= nil and not player.ignore then
			local inrange = Delleren:UnitNearby( playername )
			
			for spellid,sp in pairs(player.spells) do
				if self.mysubmap[spellid] then
					local entry = datamap[spellid]
					entry.duration = sp.cd
					
					if UnitIsDeadOrGhost( playername ) or not UnitIsConnected(playername) then
					
						-- only show disabled button if there is no other data
						
						if entry.value < 1 then
							entry.value = 1
						end
						
					else
						self:UpdateSpellCooldown( sp )
						
						if sp.charges > 0 then
							entry.stacks = entry.stacks + sp.charges
							if inrange then
								entry.value = 5
							elseif entry.value < 4 then
								entry.value = 4
							end
						else
							local timeleft = sp.time + sp.cd - GetTime()
							entry.time = math.min( entry.time, timeleft )
							if inrange and entry.value < 3 then
								entry.value = 3
							elseif entry.value < 2 then
								entry.value = 2
							end
						end
					end
				end
			end
		end
	end
	
	local cdbar_data = {}
	 
	for k,spellid in ipairs( self.mysubs ) do
		local entry = datamap[spellid]
		if entry.value > 0 then
			if entry.value <= 1 then
				table.insert( cdbar_data, 
					{ spell = spellid, stacks = 0, disabled = true, 
					  time = 0, duration = 0, outrange = false 
					})
			elseif entry.value <= 3 then
				table.insert( cdbar_data, 
					{ spell = spellid, stacks = 0, disabled = false,  
					  time = GetTime() + entry.time - entry.duration, 
					  duration = entry.duration, outrange = (entry.value == 2)
					})
			elseif entry.value <= 5 then
				table.insert( cdbar_data, 
					{ spell = spellid, stacks = entry.stacks, disabled = false,
					time = 0, duration = 0, outrange = (entry.value == 4) 
					})
			end
		end
	end
	
	return cdbar_data
end

-------------------------------------------------------------------------------
-- Returns a list of information regarding players that can cast a spell
--
function Delleren.Status:GetSpellStatus( spellid )
	local data = {}
	
	for playername in Delleren:IteratePlayers() do
		local player = self.players[playername]
		if player and not player.ignore then
			local sp = player.spells[spellid]
			if sp then
				self:UpdateSpellCooldown( sp )
				
				local cd = 0
				if sp.time ~= 0 then
					cd = sp.time + sp.cd - GetTime()
				end
				
				table.insert( data, {	
						name       = playername;
						charges    = sp.charges;
						maxcharges = sp.maxcharges;
						cd         = cd;
						inrange    = Delleren:UnitNearby( playername );
						delleren   = self:PlayerHasDelleren( playername );
						dead       = UnitIsDeadOrGhost( playername ) 
						             or not UnitIsConnected( playername );
				})
			end
		end
	end
	
	local function sort_value( a )
		if a.dead then return 0 end
		if a.charges == 0 then return 1 end
		if not a.inrange then return 2 end
		return 3
	end
	
	table.sort( data, 
		function( a, b )
			return sort_value(a) > sort_value(b)
		end )
	
	return data
end

-------------------------------------------------------------------------------
-- Returns time remaining on player timeout or nil if not in timeout.
--
function Delleren.Status:PlayerInTimeout( name )
	if not self.players[name] then return nil end
	
	local t = self.players[name].timeout - GetTime()
	if t > 0 then
		return t
	end
	
	return nil
end

-------------------------------------------------------------------------------
function Delleren.Status:PlayerHasDelleren( name )
	if not self.players[name] then return false end
	return self.players[name].compat and not self:PingTimeout( name )
end

-------------------------------------------------------------------------------
function Delleren.Status:GivePlayerTimeout( name )
	if not self.players[name] then return end
	self.players[name].timeout = GetTime() + PLAYER_TIMEOUT_LENGTH
end

-------------------------------------------------------------------------------
function Delleren.Status:PingTimeout( name )
	local p = self.players[name]
	if not p then return false end
	
	return GetTime() > p.time + PING_TIMEOUT
end

-------------------------------------------------------------------------------
function Delleren.Status:CheckPing()

	if GetTime() - self.lastping > PING_REFRESH_TIME then
	        --and not UnitAffectingCombat( "player" ) then -- bug making it timeout in combat.
	
		--[[
		local data = {
			spellserial = self.spellserial;
			subserial   = self.subserial;
			ver         = Delleren.version;
		}
		
		self.lastping = GetTime()
		--Delleren:Comm( "PING", data, "RAID" )
		]]
		
		-- STATUS is super simple and lightweight to handle right now, 
		-- so just send that.
		
		-- if Legion makes things complicated, then we'll do something about it
		self:Send()
	end
end

-------------------------------------------------------------------------------
function Delleren.Status:OnPing( name, data )
	local p = self:GetPlayerData( name, true )
	p.time = GetTime()
	
	if not p.loaded then 
		self:Send( true )
	end
end

-------------------------------------------------------------------------------
function Delleren.Status:SetSpellCooldown( name, spell, time )
	local p = self:GetPlayerData( name )
	if not p then return end
	
	local sp = p.spells[spell]
	if not sp then return end
	
	sp.charges = 0
	sp.time = GetTime() - sp.cd + time
end

-------------------------------------------------------------------------------
local function TalentSelected( tier, col, name )
	local _,_,_,sel,avail = GetTalentInfo( tier, col, GetActiveSpecGroup() )
	return sel and avail
end

-------------------------------------------------------------------------------
function Delleren.Status:CacheTalents()
	self.myserial = self.myserial + 1
	self.myspec = GetSpecializationInfo(GetSpecialization() or 1)
	self.mytalents = ""
	
	for tier = 1,7 do
		if TalentSelected( tier, 1 ) then
			self.mytalents = self.mytalents .. "1"
		elseif TalentSelected( tier, 2 ) then
			self.mytalents = self.mytalents .. "2"
		elseif TalentSelected( tier, 3 ) then
			self.mytalents = self.mytalents .. "3"
		else
			self.mytalents = self.mytalents .. "0"
		end
	end
	
	self.myglyphs = {}
	
	for g = 1,NUM_GLYPH_SLOTS do
		local enabled, _, _, spellid = GetGlyphSocketInfo( g )
		
		if enabled and Delleren.SpellData:GlyphFilter( spellid ) then
			table.insert( self.myglyphs, spellid )
		end
	end
	
	table.sort( self.myglyphs )
	
end

-------------------------------------------------------------------------------
function Delleren.Status:CopyIgnore( player )
	local p = self:GetPlayerData( player )
	if not p then return end
	p.ignore = Delleren.Ignore:IsIgnored( player )
end
