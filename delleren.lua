-------------------------------------------------------------------------------
-- DELLEREN
-- External CD caller.
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
--
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------
-- version 1.1 beta
-------------------------------------------------------------------------------

local Delleren = DellerenAddon
 
local COMM_PREFIX = "DELLEREN"

-------------------------------------------------------------------------------		  
function Delleren:OnInitialize()

	SLASH_DELLEREN1 = "/delleren"
	
	self.update_dummy_frame = CreateFrame("Frame")
	
	self.Config:CreateDB()
end

-------------------------------------------------------------------------------
function Delleren:OnEnable()
	print("DEBUG enabled")
	--[[
	self.CDBar:UpdateButtons(
	
		{
			{ spell = 115072, stacks = 1,  disabled = false, time = 0,         duration = 0,  outrange = false };
			{ spell = 121253, stacks = 2,  disabled = false, time = GetTime(), duration = 60, outrange = true  };
			{ spell = 116841, stacks = 0,  disabled = true,  time = 0,         duration = 0,  outrange = false };
			{ spell = 137562, stacks = 0,  disabled = false, time = 0,         duration = 0,  outrange = true  };
			{ spell = 123986, stacks = 35, disabled = false, time = 0,         duration = 0,  outrange = false };
		}
	)]]
	
	self:ReMasque()
	
	self.Config:Apply( true )
	
	self:RegisterEvent( "UNIT_SPELLCAST_SUCCEEDED", 
						"OnUnitSpellcastSucceeded" )
	self:RegisterEvent( "GROUP_JOINED", "OnGroupJoined" )
	
	self:RegisterEvent( "PLAYER_TALENT_UPDATE", "OnTalentsChanged" )
	self:RegisterEvent( "GLYPH_ADDED", "OnTalentsChanged" )
	
	self:RegisterComm( "DELLEREN" )
	
	if IsInGroup() then
		-- exchange status with party
		
		-- add a longer delay to let shit load
		self:ScheduleTimer( function() Delleren.Status:Send(true) end, 15 )
		--self:ScheduleTimer( function() Delleren.Status:Send(true) end, 16 )
		
	end
	
	self.update_dummy_frame:SetScript( "OnUpdate", 
							  function() Delleren:OnFrame() end )
							  
	self:ScheduleRepeatingTimer( "SendPing", 120 )
end

-------------------------------------------------------------------------------
function Delleren:SendPing()
	self:Comm( "PING", {}, "RAID" )
end

-------------------------------------------------------------------------------
function Delleren:OnGroupJoined()
	
	self.Status:NewGroup()
end

-------------------------------------------------------------------------------
function Delleren:OnTalentsChanged()

	self.Status:Send()
end

-------------------------------------------------------------------------------
function Delleren:OnUnitSpellcastSucceeded( event, unitID, spell, rank, 
												 lineID, spellID )
	self.Status:OnSpellUsed( unitID, spellID )
	
	if self.Query.active and not self.Query.buff 
	   and UnitGUID( unitID ) == UnitGUID( self.Query.unit ) then
	
		if (not self.Query.item and spellID == self.Query.spell) or
		   (self.Query.item and spell == GetItemSpell( self.Query.spell )) then
			
			self.Indicator:SetAnimation( "QUERY", "SUCCESS" )
			self.Query.active = false
		end
	end
	
	if self.Help.active and not self.Help.buff and unitID == "player" then
	   
		if (not self.Help.item and spellID == self.Help.spell) or
		   (self.Help.item and spell == GetItemSpell( self.Help.spell )) then
			self.Indicator:SetAnimation( "HELP", "SUCCESS" )
			self.Help.active = false
		end
	end
end

-------------------------------------------------------------------------------
-- Called when a party or raid member applies a buff or debuff to someone.
--
-- @param spellID     Spell ID of buff.
-- @param source,dest GUID of player who buffed and target
--
function Delleren:OnAuraApplied( spellID, source, dest ) 

	if self.Query.active and self.Query.buff 
	   and self.Query.requested
	   and source == UnitGUID( self.Query.unit )
	   and ((not self.Query.item and spellID == self.Query.spell) 
	       or (self.Query.item and 
	       GetSpellInfo(spellID) == GetItemSpell(self.Query.spell))) then
	   
		if dest == UnitGUID( "player" ) then
		
			self.Indicator:SetAnimation( "QUERY", "SUCCESS" )
			self.Query.active = false
			
		else
		
			-- cd was cast on someone else! find another one!
			self.Query.requested = false
		end
	end
	
	if self.Help.active and self.Help.buff 
	   and source == UnitGUID( "player" ) 
	   and ((not self.Help.item and spellID == self.Help.spell)
	       or (self.Help.item 
		      and GetSpellInfo(spellID) == GetItemSpell(self.Help.spell))) then
 
		if dest == UnitGUID( self.Help.unit ) then
			
			self.Indicator:SetAnimation( "HELP", "SUCCESS" )
			self.Help.active = false
			
		else
			
			self:PlaySound( "FAIL" )
			self.Indicator:SetAnimation( "HELP", "FAILURE" )
			self.Help.active = false
		end
	end
end

-------------------------------------------------------------------------------
function Delleren:OnCombatLogEvent( event, ... ) 
	local timestamp,evt,_,sourceGUID,_,_,_,destGUID,_,_,_,spellID = ...
	
	if evt == "SPELL_AURA_APPLIED" or evt == "SPELL_AURA_REFRESH" then
		self:OnAuraApplied( spellID, sourceGUID, destGUID )
		
	end
end

-------------------------------------------------------------------------------
function Delleren:UnitFullName( unit )
	local n,r = UnitName(unit)
	if r then
		return n .. '-' .. r
	end
	return n
end

-------------------------------------------------------------------------------
function Delleren:ToggleFrameLock()
	if self.unlocked then
		self:LockFrames()
	else
		self:UnlockFrames()
	end
end
  
-------------------------------------------------------------------------------
function Delleren:UnlockFrames()
	if self.unlocked then return end
	
	--if UnitAffectingCombat( "player" ) then
	--	print( "Cannot unlock in combat!" )
	--	return
	--end
	
	--if self.Query.active or self.Help.active then
	--	print( "Cannot unlock when busy!" )
	--	return
	--end
	
	self.Indicator:EnableDragging()
	self.CDBar:Unlock()
	
	self.unlocked = true
	self.Config.db.profile.locked = false
	
	LibStub( "AceConfigRegistry-3.0" ):NotifyChange( "Delleren" )
end

-------------------------------------------------------------------------------
function Delleren:LockFrames()
	if not self.unlocked then return end 
	
	self.unlocked = false
	self.Config.db.profile.locked = true
	
	self.Indicator:DisableDragging()
	self.CDBar:Lock()
	
	LibStub("AceConfigRegistry-3.0"):NotifyChange("Delleren")
end
 
-------------------------------------------------------------------------------
-- Returns the squared range to a friendly unit.
--
-- Note that the casting range is slightly longer, since this is the
-- range to their center, and casting extends to their hitboxes
--
-- @param unit unitID of friendly unit.
-- @returns distance squared.
--
local function UnitDistance( unit )
	local y,x = UnitPosition( unit )
	local my,mx = UnitPosition( "player" )
	y,x = y - my, x - mx
	local d = x*x + y*y
	return d
end

-------------------------------------------------------------------------------
function Delleren:UnitShortRange( unit )
	return UnitDistance( unit ) < 35 * 35 and IsItemInRange( 34471, unit )
end

-------------------------------------------------------------------------------
function Delleren:UnitLongRange( unit )
	return IsItemInRange( 34471, unit )
end

-------------------------------------------------------------------------------
function Delleren:UnitNearby( unit )
	return UnitDistance( unit ) < 40*40 and IsItemInRange( 34471, unit )
end

-------------------------------------------------------------------------------
-- Returns a range weight used for sorting the cd responses.
--
local function UnitRangeValue( unit )
	local a = UnitDistance( unit )
	
	if UnitShortRange( unit ) then
		return a
	elseif UnitLongRange( unit ) then
		return a + 100000
	else
		return a + 1000000
	end
end

-------------------------------------------------------------------------------
-- Returns true if we have a cd ready to give to someone, and it isn't
-- already being asked for.
--
-- @param ignore_reserve Don't return false if we have our CD reserved,
--                       (check the cooldown only)
-- @param list           List of spell IDs or item IDs to check. May be a 
--                       single id number too.
-- @param item           true if we are checking for items instead of spells.
--
-- @returns nil if no spells or items are ready, or returns the id of one
--          that is ready.
--
function Delleren:HasCDReady( ignore_reserve, list, item )
	if not ignore_reserve and (self.Help.active) then
		-- someone is already asking us!
		return nil
	end
	
	if UnitIsDeadOrGhost( "player" ) then 
		-- we are dead
		return nil
	end
	
	if type(list) == "number" then
		list = {list}
	end
	
	-- todo: spell reserves
	
	for k,v in ipairs( list ) do
		if not item then
			if IsSpellKnown( v ) then
				local charges = GetSpellCharges( v ) 
				if charges ~= nil and charges >= 1 then return v end
				
				local start, duration, enable = GetSpellCooldown( v )
				if start == 0 then return v end
				
				-- if there is 1 second left on the cd, then it's ready enough
				-- also uh, account for gcd time which may interfere
				if duration - (GetTime() - start) < 1.6 then return v end
			end
		else
			if GetItemCount( v ) > 0 then
				local start, duration, enable = GetItemCooldown( v )
				if start == 0 then return v end
				
				if duration - (GetTime() - start) < 1.6 then return v end
			end
		end
	end
end

-------------------------------------------------------------------------------
function Delleren:OnCommReceived( prefix, packed_message, dist, sender )
	if prefix ~= COMM_PREFIX then return end -- discard unwanted messages
	
	local result, msg, data = self:Deserialize( packed_message )
	if result == false then return end -- bad message
	if data.tar and UnitGUID("player") ~= data.tar then
		-- crossrealm whisper and we are not the intended target.
		return
	end
	
	if sender == UnitName( "player" ) then
		-- ignore mirrored messages, (TODO does this happen?)
		return
	end 
	
	if msg == "CHECK" then
		-- player is checking if we have a cd ready
		
		local id = self:HasCDReady( false, data.ids, data.item )
		
		if id then
			self:RespondReady( sender, data.rid, id )
		end
		
	elseif msg == "READY" then
		
		self.Query:HandleReadyMessage( sender, data )
		
	elseif msg == "GIVE" then
		-- player is asking for a CD
		
		if type(data.id) ~= "number" then return end -- bad message
		
		if not self:HasCDReady( false, data.id, data.item ) then
		
			self:DeclineCD( sender, data.rid )
		else
			self.Help:Start( sender, data.id, data.item, data.buff )
		end
		
	elseif msg == "NO" then
		-- player denied our cd request
		
		if data.rid ~= self.Query.rid then
			return
		end
		
		self.Status:Ping( sender )
		
		-- end current request and try for another target.
		self.Query.requested = false
		
	elseif msg == "STATUS" then
		
		self.Status:UpdatePlayer( sender, data )
		
	elseif msg == "PING" then
		self.Status:Ping( sender )
	end
end
 
-------------------------------------------------------------------------------
local function CrossesRealm( unit )
	local n,r = UnitName( unit )
	return r ~= nil
end

-------------------------------------------------------------------------------
-- Send a message to other players.
--
-- Handles cross-realm compatibility workarounds.
--
-- @param msg    Message type string
-- @param data   Message data block
-- @param dist   Distribution type.
-- @param target WHISPER distribution target name.
--
function Delleren:Comm( msg, data, dist, target )
	
	if target ~= nil and dist == "WHISPER" and CrossesRealm( target ) then
		dist = "RAID"
		data.tar = UnitGUID( target )
	end
	
	local packed = self:Serialize( msg, data )
	
	if dist == "WHISPER" then
	
		self:SendCommMessage( COMM_PREFIX, packed, dist, target )
	else
		self:SendCommMessage( COMM_PREFIX, packed, dist )
	end
end

-------------------------------------------------------------------------------
-- Send a READY response.
--
-- @param target Name of player to respond to.
-- @param rid    Request ID.
-- @param id     Spell or item ID that we have ready.
--
function Delleren:RespondReady( target, rid, id )

	local data = {
		rid = rid;
		id  = id;
	}
	
	self:Comm( "READY", data, "WHISPER", target )
end

-------------------------------------------------------------------------------
-- Decline giving a CD, sending a "NO" response
--
-- @param target Name of player we are denying.
-- @param rid    Request ID.
--
function Delleren:DeclineCD( target, rid )
	local data = { rid = rid }
	self:Comm( "NO", data, "WHISPER", target )
end

-------------------------------------------------------------------------------
-- Frame update handler.
--
function Delleren:OnFrame()
	if self.Query.active then self.Query:Update() end
	if self.Help.active  then self.Help:Update()  end
	
	if self.Indicator.shown then
		self.Indicator:UpdateAnimation()
		
		if not self.Query.active and not self.Help.active 
			and not self.Indicator:Animating() then
			
			self:DisableFrameUpdates()
			self.Indicator:Hide()
		end
	end
	
	if self.Config.db.profile.cdbar.enabled then
		self.CDBar:Refresh()
	end
end

-------------------------------------------------------------------------------
-- Enable combat log parsing. (this used to be a bit more than that)
--
function Delleren:EnableFrameUpdates()

	if self.updates_enabled then return end
	self.updates_enabled = true
							  
	self:RegisterEvent( "COMBAT_LOG_EVENT_UNFILTERED", "OnCombatLogEvent" )
end

-------------------------------------------------------------------------------
-- Disable animations and combat log parsing.
--
function Delleren:DisableFrameUpdates()
	if not self.updates_enabled then return end
	self.updates_enabled = false
	
	self:UnregisterEvent( "COMBAT_LOG_EVENT_UNFILTERED", "OnCombatLogEvent" )
end

-------------------------------------------------------------------------------
-- Parse a call command and execute it.
--
function Delleren:CallCommand( args )

	if self.Query.active then return end
	
	local spells  = {}
	local players = {}
	local item    = false
	local manual  = false
	local buff    = true
	
	local mode = "SPELLS"
	
	for i = 2,#args do
		local arg = args[i]
		
		if string.sub(arg,1,1) == "-" then
			-- option
			
			if arg == "-s" then
				mode = "SPELLS"
			elseif arg == "-p" then
				mode = "PLAYERS"
			elseif arg == "-i" then
				item = true
			elseif arg == "-m" then
				manual = true
			elseif arg == "-c" then
				buff = false
			else
				print( "[Delleren] Unknown option: " .. arg )
			end
			
		else
		
			if mode == "SPELLS" then
				local spellid = tonumber( arg )
				if not spellid then
					print( "[Delleren] Invalid Spell ID: " .. arg )
				end
				table.insert( spells, spellid )
				
			elseif mode == "PLAYERS" then
				table.insert( players, string.lower(arg) )
			end
		end
	end
	
	if #spells == 0 then
		print( "[Delleren] No spell IDs given!" )
		return
	end
	
	if #players == 0 then
	
		local role = UnitGroupRolesAssigned( "player" )
		
		-- default player priority
		if role == "TANK" then
			-- if they're a tank, prioritize the other tank
			players = { "*t", "*h", "*d", "*" }
			
		else
			-- otherwise prioritize healers > dps > tanks
			players = { "*h", "*d", "*t", "*" }
			
		end
	end
	
	self.Query:Start( spells, item, buff, manual, players )
end

-------------------------------------------------------------------------------
-- Slash command for macro binding.
--
function SlashCmdList.DELLEREN( msg )
	local args = {}
	
	for i in string.gmatch( msg, "%S+" ) do
		table.insert( args, i )
	end
	
	if args[1] ~= nil then args[1] = string.lower( args[1] ) end
	
	if args[1] == "call" then
		Delleren:CallCommand( args ) 
	elseif args[1] == "config" then
		Delleren.Config:Open()
	elseif args[1] == "fuck" then

		print( "[Delleren] My what a filthy mind you have!" )
		
	else
		print( "/delleren config - Open configuration." )
		print( "/delleren call - Call for a cd. (See manual.)" )
	end
	  
end

-------------------------------------------------------------------------------
function Delleren:ReMasque()
	if self.masque then
		self.masque_group:ReSkin()
		self.masque_group_bar:ReSkin()
	end
end

-------------------------------------------------------------------------------
function Delleren:AddMasque( group, frame, data )
	if self.masque then
		if group == "BUTTON" then
			self.masque_group:AddButton( frame, data )
		elseif group == "CDBAR" then
			self.masque_group_bar:AddButton( frame, data )
		end
		
		self:ReMasque()
	end
end

-------------------------------------------------------------------------------
-- Iterates through unit IDs of your party or raid, excluding the player
--
function Delleren:IteratePlayers()
	local raid   = IsInRaid()
	local index  = 0
	local player = UnitGUID("player")
	
	return function()
		
		while true do
			index = index + 1
			if (raid and index > 40) or (not raid and index > 4) then 
				return nil 
			end
			
			local unit = (raid and "raid" or "party") .. index
			if UnitExists(unit) and UnitGUID( unit ) ~= player then
				return self:UnitFullName(unit)
			end
		end
		
	end
end

-------------------------------------------------------------------------------
-- Returns a unit name colored by their class.
--
function Delleren:UnitNameColored( unit )
	local _,cls = UnitClass(unit)
	
	return "|c" .. RAID_CLASS_COLORS[cls].colorStr .. UnitName(unit) .. "|r"
end
