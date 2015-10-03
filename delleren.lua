-------------------------------------------------------------------------------
-- DELLEREN
-- External CD caller.
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
--
-- See LICENSE-DELLEREN.TXT 
-------------------------------------------------------------------------------

local Delleren = DellerenAddon
 
local COMM_PREFIX      = "DELLEREN"
local PROTOCOL_VERSION = 2

-------------------------------------------------------------------------------		  
function Delleren:OnInitialize()

	SLASH_DELLEREN1 = "/delleren"
	
	self.update_dummy_frame = CreateFrame("Frame")
	
	self.Config:CreateDB()
end

-------------------------------------------------------------------------------
function Delleren:OnEnable()

	self.Status:CacheTalents()
	
	self:ReMasque()
	
	self.Config:Apply( true )
	
	self:RegisterEvent( "UNIT_SPELLCAST_SUCCEEDED", 
						"OnUnitSpellcastSucceeded" )
	self:RegisterEvent( "GROUP_JOINED", "OnGroupJoined" )
	
	self:RegisterEvent( "PLAYER_TALENT_UPDATE", "OnMyTalentsChanged" )
	self:RegisterEvent( "GLYPH_ADDED", "OnMyTalentsChanged" )
	self:RegisterEvent( "PLAYER_SPECIALIZATION_CHANGED", 
	                    "OnPlayerSpecializationChanged" )
	self:RegisterEvent( "INSPECT_READY", "OnInspectReady" )
	 
	self:RegisterComm( "DELLEREN" )
	
	self:Print( "Version: " .. self.version )
	
	Delleren.Ignore:Load()
				
	self:ScheduleTimer( 
		function() 
			if IsInGroup() then
				Delleren.Status:Send(true) 
			else
				Delleren.Ignore:Reset()
			end
		end, 10 )
	
	self.update_dummy_frame:SetScript( "OnUpdate", 
							  function() Delleren:OnFrame() end )
							  
	self:ScheduleRepeatingTimer( "CheckPing", 30 )
end

-------------------------------------------------------------------------------
function Delleren:CheckPing()
	self.Status:CheckPing()
end

-------------------------------------------------------------------------------
function Delleren:OnGroupJoined()
	self.Status:NewGroup()
end

-------------------------------------------------------------------------------
function Delleren:OnInspectReady( event, guid )
	self.Inspect:OnInspectReady( guid )
end

-------------------------------------------------------------------------------
function Delleren:OnMyTalentsChanged()
	self.Status:CacheTalents()
	self.Status:Send()
end

-------------------------------------------------------------------------------
function Delleren:OnPlayerSpecializationChanged( event, player )
	if player ~= nil and player ~= "player" then
		self.Status:PlayerTalentsChanged( self:UnitFullName(player) )
	end
end

-------------------------------------------------------------------------------
local RAID_UNIT_IDS = {}
for i = 1,40 do RAID_UNIT_IDS["raid" .. i] = i end

-------------------------------------------------------------------------------
local PARTY_UNIT_IDS = {}
for i = 1,10 do PARTY_UNIT_IDS["party" .. i] = i end

-------------------------------------------------------------------------------
function Delleren:IsPartyOrRaidUnit( unit )
	if (IsInRaid() and RAID_UNIT_IDS[unit])
	        or (not IsInRaid() and PARTY_UNIT_IDS[unit]) then
		return true
	end
	return nil
end

-------------------------------------------------------------------------------
function Delleren:OnUnitSpellcastSucceeded( event, unitID, spell, rank, 
											lineID, spellID )
	
	-- check if we have a raid# unitid if in a raid, or a party# unitid
	-- if not in a raid, the same spellcast may trigger multiple events
	-- with different unitids
	--

	if self:IsPartyOrRaidUnit( unitID ) then
	
		self.Status:OnSpellUsed( unitID, spellID )
		
		-- remove talent or remove glyph
		if spellID == 113873 or spellID == 111621 then
			self.Status:PlayerTalentsChanged( self:UnitFullName(unitID), 10 )
		end
		
		if self.Query.active and not self.Query.buff 
		   and UnitGUID( unitID ) == UnitGUID( self.Query.unit ) then
		
			if (not self.Query.item and spellID == self.Query.spell) or
			   (self.Query.item and spell == GetItemSpell( self.Query.spell )) then
				
				self.Indicator:SetAnimation( "QUERY", "SUCCESS" )
				self.Query.active = false
			end
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
	if r and r ~= "" then
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
	
	LibStub("AceConfigRegistry-3.0"):NotifyChange( "Delleren" )
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
	y = y or 999999
	x = x or 999999
	local my,mx = UnitPosition( "player" )
	y,x = y - my, x - mx
	local d = x*x + y*y
	return d
end
 
-------------------------------------------------------------------------------
function Delleren:UnitNearby( unit )
	return UnitDistance( unit ) < 40*40 and IsItemInRange( 34471, unit )
end
 
-------------------------------------------------------------------------------
function Delleren:GetSpellReadyTime( spell, item )
	if not item then
		--if IsSpellKnown( spell ) then
		
		-- IsSpellKnown fails for certain talents
		-- workaround http://forums.wowace.com/showthread.php?t=20184
		--
		if GetSpellInfo( GetSpellInfo( spell )) then
			local charges = GetSpellCharges( spell ) 
			if charges ~= nil and charges >= 1 then return 0 end
			
			local start, duration, enable = GetSpellCooldown( spell )
			if start == 0 then return 0 end
			
			-- if there is 1 second left on the cd, then it's ready enough
			-- also uh, account for gcd time which may interfere
			return duration - (GetTime() - start) 
		end
	else
		if GetItemCount( v ) > 0 then
			local start, duration, enable = GetItemCooldown( v )
			if start == 0 then return 0 end
			
			return duration - (GetTime() - start)
		end
	end
	
	return nil
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
		local t = Delleren:GetSpellReadyTime( v, item )
		if t ~= nil and t <= 1.6 then return v end 
	end
end

-------------------------------------------------------------------------------
function Delleren:OnCommReceived( prefix, packed_message, dist, sender )
	if prefix ~= COMM_PREFIX then return end -- discard unwanted messages
	
	local result, msg, data = self:Deserialize( packed_message )
	if result == false then return end -- bad message
	
	if not UnitInParty( sender ) then
		-- malicious message from outside
		return
	end
	
	if data.pv ~= PROTOCOL_VERSION then
	
		-- incompatible protocols!
		if data.pv > PROTOCOL_VERSION then
			if not self.warned_protocol_outdated then
				self.warned_protocol_outdated = true
				self:Print( "One or more players in your raid are using a newer version of Delleren that isn't compatible with yours." )
			end
		end
		
		if msg == "STATUS" then
			self.Status:SetIncompatible( sender, data )
		end
		
		return
	end
	
	if sender == UnitName( "player" ) then
		-- ignore mirrored messages, (TODO does this happen?)
		return
	end
	
	if data.tar and UnitGUID("player") ~= data.tar then
		-- crossrealm whisper and we are not the intended target.
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
		
			if not data.item then
				
				self:DeclineCD( sender, data.rid, data.id )
			else
				self:DeclineCD( sender, data.rid )
			end
		else
			self.Help:Start( sender, data.id, data.item, data.buff )
		end
		
	elseif msg == "NO" then
		-- player denied our cd request
		
		if data.rid ~= self.Query.rid then
			return
		end
		
		if data.time then
			self.Status:SetSpellCooldown( sender, self.Query.spell, data.time )
		end
		
		-- end current request and try for another target.
		self.Query.requested = false
		
	elseif msg == "STATUS" then
		
		self.Status:UpdatePlayer( sender, data )
		
	elseif msg == "PING" then
		self.Status:OnPing( sender, data )
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
	
	if dist == "RAID" and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) 
	   and IsInInstance() and not C_Garrison:IsOnGarrisonMap() then
	
		dist = "INSTANCE_CHAT"
	end
	
	data.pv = PROTOCOL_VERSION
	
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
function Delleren:DeclineCD( target, rid, spell )
	local data = { rid = rid }
	
	if spell then
		local time = Delleren:GetSpellReadyTime( spell, false )
		if time ~= nil and time >= 3 then data.time = time end
	end
	
	self:Comm( "NO", data, "WHISPER", target )
end

-------------------------------------------------------------------------------
-- Frame update handler.
--
function Delleren:OnFrame()
	self.Status:PeriodicRefresh()
	
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
local CALL_SPELL_PRESETS = {
	painsups      = { 6940, 33206, 114030, 102342 };
	antimagiczone = { 51052  };
	ironbark      = { 102342 };
	sac           = { 6940   };
	bop           = { 1022   };
	psup          = { 33206  };
	smokebomb     = { 76577  };
	vig           = { 114030 };
}

-------------------------------------------------------------------------------
local CALL_SPELL_PRESETS_ITEMS = {
	jeeves   = { 49040 };
}

-------------------------------------------------------------------------------
local function TableContainsValue( table, value )
	for k,v in pairs(table) do
		if v == value then return k end
	end
	
	return nil
end

-------------------------------------------------------------------------------
local function PushCallSpell( spells, arg )

	local list = nil
	
	local makeitem = false
	
	if CALL_SPELL_PRESETS[arg] then
	
		list = CALL_SPELL_PRESETS[arg]
		
	elseif CALL_SPELL_PRESETS_ITEMS[arg] then
	
		list = CALL_SPELL_PRESETS_ITEMS[arg]
		makeitem = true
		
	else
	
		local spellid = tonumber( arg )
		if not spellid then
			print( "[Delleren] Invalid Spell ID: " .. arg )
			return
		end
		
		list = { spellid }
	end
	
	for _,spell in ipairs(list) do
	
		if not TableContainsValue( spells, spell ) then
			table.insert( spells, spell )
		end
	end
	
	return makeitem
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
				Delleren:Print( "Unknown option: " .. arg )
			end
			
		else
		
			if mode == "SPELLS" then
			
				if PushCallSpell( spells, arg ) then
					item = true
				end
				
			elseif mode == "PLAYERS" then
			
				table.insert( players, string.lower(arg) )
			end
		end
	end
	
	if #spells == 0 then
		Delleren:Print( "No spell IDs given!" )
		return
	end
	 
	self.Query:Start( spells, item, buff, manual, players )
end

-------------------------------------------------------------------------------
function Delleren:WhoCommand()
	
	local players_with    = {}
	local players_without = {}
	
	Delleren:Print( "Your version: |cff00ff00" .. self.version .. "|r" )
	
	local count = 0
	
	for player in self:IteratePlayers() do
		local data = self.Status.players[player]
		 
		if data then
			
			if data.compat then
				table.insert( players_with, data.name .. ": |cff00ff00" .. data.version .. "|r" )
			else
				if data.version then
					table.insert( players_without, data.name .. ": |cff900f90" .. data.version .. " (Incompatible)|r" )
				else
					table.insert( players_without, data.name .. ": |cffff0000Not installed.|r" )
				end
				
			end
		else
			table.insert( players_without, data.name .. ": |cff808080Unknown.|r" )
		end	
		count = count + 1
	end
	
	for _,v in pairs( players_with ) do
		Delleren:Print( v )
	end
	
	for _,v in pairs( players_without ) do
		Delleren:Print( v )
	end
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
	
	elseif args[1] == "ignore" then
	
		Delleren.Ignore:OpenPanel()
		
	elseif args[1] == "config" then
	
		Delleren.Config:Open()
		
	elseif args[1] == "who" or args[1] == "version" then
	
		Delleren:WhoCommand()
		
	elseif args[1] == "fuck" then
		 
		-- this is a police quest reference
		Delleren:Print( "My what a filthy mind you have!" )
		
	else
		
		Delleren:Print( "Command listing:" )
		Delleren:Print( "  /delleren config - Open configuration."  )
		Delleren:Print( "  /delleren call - Call for a cd. (See User's Manual.)" )
		Delleren:Print( "  /delleren who - List player versions." )
		Delleren:Print( "  /delleren ignore - Open ignore panel." )
	
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
-- Note that the iterator is not valid across frames.
--
function Delleren:IteratePlayers()
	local raid   = IsInRaid()
	local index  = 0
	local player = UnitGUID("player")
	
	return function()
		
		while true do
			index = index + 1
			local unit = (raid and "raid" or "party") .. index
			if not UnitExists( unit ) then
				return nil
			end
			
			if UnitGUID( unit ) ~= player then
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

-------------------------------------------------------------------------------
function Delleren:Print( text )
	local prefix = "|cffa7000c<Delleren>|r "
	print( prefix .. text )
end
