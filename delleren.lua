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
	
	if not DellerenAddonSaved then
		DellerenAddonSaved = {}
	end
	
	self.saved = DellerenAddonSaved
	
	local data = DellerenAddonSaved
	data.size = data.size or 48
	
	self.Indicator:SetFrameSize( data.size )
	
	if not self.saved.init then
		self.saved.init = true
		-- stuff...
	end
	
	if not self.saved.locked then
		Delleren:Unlock() 
	end
	
	self:RegisterEvent( "UNIT_SPELLCAST_SUCCEEDED", 
						"OnUnitSpellcastSucceeded" )
	
	self:RegisterComm( "DELLEREN" )
end

-------------------------------------------------------------------------------
function Delleren:OnUnitSpellcastSucceeded( event, unitID, rank, 
												 lineID, spellID )
	self.Status:OnSpellUsed( unitID, spellID )
	
	if self.query.active and not self.query.buff 
	   and spellID == self.query.spell 
	   and UnitGUID( unitID ) == UnitGUID( self.query.unit ) then
		
		self.Indicator:SetAnimation( "QUERY", "SUCCESS" )
		self.query.active = false
	end
	
	if self.help.active and not self.help.buff
	   and spellID == self.help.spell then
	   
		self.Indicator:SetAnimation( "HELP", "SUCCESS" )
		self.help.active = false
	end
end

-------------------------------------------------------------------------------
-- Called when a party or raid member applies a buff or debuff to someone.
--
-- @param spellID     Spell ID of buff.
-- @param source,dest GUID of player who buffed and target
--
function Delleren:OnAuraApplied( spellID, source, dest ) 

	if self.query.active and self.query.buff 
	   and source == UnitGUID( self.query.unit )
	   and spellID == self.query.spell then
	   
		if dest == UnitGUID( "player" ) then
			
			self.Indicator:SetAnimation( "QUERY", "SUCCESS" )
			self.query.active = false
			
		else
			-- cd was cast on someone else! find another one!
			self.query.requested = false
		end
	end
	
	if self.help.active and self.help.buff 
	   and source == UnitGUID( "player" ) 
	   and spellID == self.help.spell then
 
		if dest == UnitGUID( self.help.unit ) then
			
			self.Indicator:SetAnimation( "HELP", "SUCCESS" )
			self.help.active = false
			
		else
			
			self:PlaySound( "FAIL" )
			self.Indicator:SetAnimation( "HELP", "FAILURE" )
			self.help.active = false
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
function Delleren:UnlockFrames()
	if self.unlocked then return end
	
	--if UnitAffectingCombat( "player" ) then
	--	print( "Cannot unlock in combat!" )
	--	return
	--end
	
	--if self.query.active or self.help.active then
	--	print( "Cannot unlock when busy!" )
	--	return
	--end
	
	self.Indicator:EnableDragging()
	
	self.unlocked = true
	self.saved.locked = false
end

-------------------------------------------------------------------------------
function Delleren:LockFrames()
	if not self.unlocked then return end
	if not self.drag_stuff then return end
	
	self.unlocked = false
	self.saved.locked = true
	
	self.Indicator:DisableDragging()
end

-------------------------------------------------------------------------------
function Delleren:Scale( size )
	
	size = tonumber( size )
	if size == nil then return end
	
	self.frames.indicator.text:SetFont( 
			"Fonts\\FRIZQT__.TTF", math.floor(16 * size/48), "OUTLINE" )
	
	size = math.max( size, 16 )
	size = math.min( size, 256 )
	
	self.saved.size = size
	self.frames.indicator:SetSize( size, size )

	if self.masque_group then
		self.masque_group:ReSkin()
	end
end

-------------------------------------------------------------------------------
-- Returns a raid or party unit id from a name given.
--
local function UnitIDFromName( name )
	-- TODO check what format name is in!

	local r = UnitInRaid( name )
	if r ~= nil then return "raid" .. r end
	
	for i = 1,4 do
		local n  = UnitName( "party" .. i )
		if n ~= nil then
			if n == name then return "party" .. i end
		end
	end
	
	return nil
end

-------------------------------------------------------------------------------
local function ColorLerp( r1, g1, b1, r2, g2, b2, a )
	a = math.min( a, 1 )
	a = math.max( a, 0 )
	return r1 + (r2-r1) * a, 
	       g1 + (g2-g1) * a, 
		   b1 + (b2-b1) * a
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
local function UnitShortRange( unit )
	return UnitDistance( unit ) < 35 * 35 and IsItemInRange( 34471, unit )
end

-------------------------------------------------------------------------------
local function UnitLongRange( unit )
	return IsItemInRange( 34471, unit )
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
local function HasCDReady( ignore_reserve, list, item )
	if not ignore_reserve and (self.help.active) then
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
				if charges ~= nil and charges >= 1 then return true end
				
				local start, duration, enable = GetSpellCooldown( v )
				if start == 0 then return true end
				
				-- if there is 1 second left on the cd, then it's ready enough
				-- also uh, account for gcd time which may interfere
				if duration - (GetTime() - start) < 1.6 then return true end
			end
		else
			if GetItemCount( v ) > 0 then
				local start, duration, enable = GetItemCooldown( v )
				if start == 0 then return true end
				
				if duration - (GetTime() - start) < 1.6 then return true end
			end
		end
	end
end

-------------------------------------------------------------------------------
function Delleren:OnCommReceived( prefix, packed_message, dist, sender )
	if prefix ~= COMM_PREFIX then return end -- discard unwanted messages
	
	sender = UnitIDFromName( sender )
	if sender == nil then return end -- bad message
	
	local result, msg, data = self:Deserialize( packed_message )
	if result == false then return end -- bad message
	if data.tar and UnitGUID("player") ~= data.tar then
		-- crossrealm whisper and we are not the intended target.
		return
	end
	
	if UnitGUID( sender ) == UnitGUID ("player") then
		-- ignore mirrored messages
		return
	end
	
	if msg == "CHECK" then
		-- player is checking if we have a cd ready
		
		local id = HasCDReady( false, data.id, data.item )
		
		if id then
			self:RespondReady( sender, data.rid, id )
		end
		
	elseif msg == "READY" then
		
		self.Query:HandleReadyMessage( sender, data )
		
	elseif msg == "GIVE" then
		-- player is asking for a CD
		
		if not HasCDReady( false, data.id, data.item ) then
		
			self:DeclineCD( sender, data.rid )
		else
			self:ShowHelpRequest( sender, data.id, data.item, data.buff )
		end
		
	elseif msg == "NO" then
		-- player denied our cd request
		
		if data.rid ~= self.query.request_id then
			return
		end
		
		-- end current request and try for another target.
		self.query.requested = false
		
	elseif msg == "STATUS" then
		RecordStatus( sender, data )
	elseif msg == "POLL" then
		SendStatus()
	end
end
 
-------------------------------------------------------------------------------
local function CrossesRealm( unit )
	local n,r = UnitName(unit)
	return r ~= nil
end

-------------------------------------------------------------------------------
-- Send a message to other players.
--
-- Handles cross-realm compatibility workarounds.
--
-- @param msg  Message type string
-- @param data Message data block
-- @param dist Distribution type.
-- @param unit WHISPER distribution target.
--
function Delleren:Comm( msg, data, dist, unit )
	
	if unit ~= nil and dist == "WHISPER" and CrossesRealm( unit ) then
		dist = "RAID"
		data.tar = UnitGUID( unit )
	end
	
	local packed = self:Serialize( msg, data )
	
	if dist == "WHISPER" then
	
		self:SendCommMessage( COMM_PREFIX, packed, dist, UnitName(unit) )
	else
		self:SendCommMessage( COMM_PREFIX, packed, dist )
	end
end

-------------------------------------------------------------------------------
-- Send a READY response.
--
-- @param target unitID to respond to.
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
-- @param target Unit ID of person we are denying.
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
	if self.query.active then self.Query:Update() end
	if self.help.active  then self.Help:Update()  end
	
	self.Indicator:UpdateAnimation()
	
	if not self.query.active and not self.help.active 
	    and self.ani.finished then
		
		self:DisableFrameUpdates()
		self.Indicator:Hide()
	end
end

-------------------------------------------------------------------------------
-- Enable animations and combat log parsing.
--
function Delleren:EnableFrameUpdates()
	
	self.Indicator.frame:SetScript( "OnUpdate", 
							  function() Delleren:OnFrame() end )
							  
	self:RegisterEvent( "COMBAT_LOG_EVENT_UNFILTERED", "OnCombatLogEvent" )
end

-------------------------------------------------------------------------------
-- Disable animations and combat log parsing.
--
function Delleren:DisableFrameUpdates()
	self.Indicator.frame:SetScript( "OnUpdate", nil )
	self:UnregisterEvent( "COMBAT_LOG_EVENT_UNFILTERED", "OnCombatLogEvent" )
end

-------------------------------------------------------------------------------
-- Slash command for macro binding.
--
function SlashCmdList.DELLEREN( msg )
	local args = {}
	
	for i in string.gmatch( msg, "%S+" ) do
		table.insert( args, i )
	end
	
	if args[1] == nil then return end
	args[1] = tolower( args[1] )
	
	if args[1] == "unlock" then
		Delleren:Unlock()
	elseif args[1] == "call" then
		Delleren:CallCD() 
	elseif args[1] == "config" then
		Delleren:ShowConfig() 
		
	elseif args[1] == "fuck" then
		
		print( "My what a filthy mind you have!" )
		 
	else
		print( "/delleren unlock - Unlock the frame." )
		print( "/delleren config - Open configuration." )
		print( "/delleren call - Call for a cd." )
	end
	  
end

-------------------------------------------------------------------------------
function Delleren:ReMasque()
	if self.masque_group then
		self.masque_group:ReSkin()
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
				return unit
			end
		end
		
	end
end
