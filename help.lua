-------------------------------------------------------------------------------
-- DELLEREN
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

local Delleren = DellerenAddon

local HELP_TIMEOUT    = 7.0  -- time to allow user to cast a spell.

-------------------------------------------------------------------------------
Delleren.Help = {
	active  = false; -- if we are currently being asked for a cd
	unit    = nil;   -- unitid that is asking for the cd
	spell   = nil;   -- spellid they are asking for
	item    = false; -- 
	pulse   = 0;     -- time for the next pulse animation
	time    = 0;     -- request start time
	rid     = 0;     -- request id
	cdcheck = 0;
}

-------------------------------------------------------------------------------
-- Start a help request.
--
-- @param unit unitID that is making the request.
-- @param id   ID of spell/item being requested.
-- @param item True if this is an item request.
-- @param buff True if we are expecting an aura to be cast on us.
--
function Delleren.Help:Start( unit, id, item, buff )
	self.active = true
	self.unit   = unit
	self.spell  = id
	self.item   = item
	self.buff   = buff
	self.time   = GetTime()
	self.pulse  = GetTime() + 1
	
	Delleren:PlaySound( "HELP" )
	
	local unit_name = Delleren:UnitNameColored( self.unit )
	local request_text
	local request_icon
	
	if not self.item then
		local name, _, icon = GetSpellInfo( self.spell )
		request_text = name
		request_icon = icon
	else
		local name,_,_,_,_,_,_,_,_,texture = GetItemInfo( self.spell )
		request_text = name
		request_icon = texture
	end
	
	request_text = request_text or "???"
	request_icon = request_icon or ""
	
	Delleren.Indicator:SetText( request_text .. "\n" .. unit_name )
	Delleren.Indicator:SetIcon( request_icon )
	Delleren.Indicator:SetAnimation( "HELP", "HELP" )
	Delleren.Indicator:Show()
	
	Delleren:EnableFrameUpdates()
end

-------------------------------------------------------------------------------
-- Returns true if the requested spell or item is on cooldown.
--
function Delleren.Help:RequestOnCD()
	if not self.item then
		local start, duration, enable = GetSpellCooldown( self.spell )
		if duration == 0 then return false end
		if duration <= 1.6 then return false end
		local t = GetTime() - start
		t = duration - t
		if t < 2 then return false end
		
		-- on cd
		return true
	else
		-- TODO
	end
end

-------------------------------------------------------------------------------
function Delleren.Help:Fail()
	Delleren:PlaySound( "FAIL" )
	Delleren.Indicator:SetAnimation( "HELP", "FAILURE" )
	self.active = false
end

-------------------------------------------------------------------------------
function Delleren.Help:Update()
	
	local t = GetTime() - self.time
	
	if GetTime() >= self.pulse then
		self.pulse = self.pulse + 1
		Delleren.Indicator:SetAnimation( "HELP", "HELP" )
		Delleren:PlaySound( "HELP" )
	end
	
	-- if the requested spell or item is on cd, cancel the help request
	-- normally this shouldn't ever be the case, but it may happen in
	-- certain corner cases
	if self:RequestOnCD() then
	
		-- we use a bit of a delay to make sure that we didn't miss the
		-- spellcast events
		
		if GetTime() - self.cdcheck >= 0.25 then
			self:Fail()
			
			return
		end
	else
		self.cdcheck = GetTime()
	end
	
	if UnitIsDeadOrGhost( self.unit ) or UnitIsDeadOrGhost( "player" ) then
		self:Fail()
		return
	end
	
	if t >= HELP_TIMEOUT then
		-- they took too long to cast the spell, fail the request
		self:Fail()
		return
	end
	
end

