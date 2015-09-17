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
	rid     = 0;     -- request id
	cdcheck = 0;
}

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
function Delleren.Help:OnHelpUpdate()
	
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
			Delleren.Indicator:SetAnimation( "HELP", "FAILURE" )
			self.help.active = false
			return
		end
	else
		self.cdcheck = GetTime()
	end
	
	if t >= CD_WAIT_TIMEOUT then
		-- they took too long to cast the spell, fail the request
		
		Delleren:PlaySound( "FAIL" )
		Delleren.Indicator:SetAnimation( "HELP", "FAILURE" )
		self.help.active = false
		return
	end
	
end

