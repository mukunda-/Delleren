-------------------------------------------------------------------------------
-- DELLEREN
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

-- Handles inspecting non-delleren players for their talents 
-- and update their status.

local Delleren = DellerenAddon

local INSPECT_TIMEOUT = 5

-------------------------------------------------------------------------------
Delleren.Inspect = {
	busy = false;
	name = nil;
	guid = nil;
	timeout_timer = nil;
}

-------------------------------------------------------------------------------
-- Start inspecting a player if we aren't already.
--
-- @param name Name of player
--
function Delleren.Inspect:TryStart( name )
	
	if self.busy then return end
	
	self.busy = true
	self.name = name
	
	NotifyInspect( name )
	
	self.timeout_timer = Delleren:ScheduleTimer( 
		function() 
			Delleren.Inspect:Timeout()
		end, INSPECT_TIMEOUT )
end

-------------------------------------------------------------------------------
-- Called when we don't get an INSPECT_READY event via a timer.
--
function Delleren.Inspect:Timeout() 
	
	self.busy  = false 
	self.timeout_timer = nil
	
end

-------------------------------------------------------------------------------
-- Called by core on event INSPECT_READY.
--
function Delleren.Inspect:OnInspectReady( guid )
	if not self.busy then return end
	if guid ~= UnitGUID(self.name) then return end
	
	Delleren:CancelTimer( self.timeout_timer )
	self.timeout_timer = nil 
	self.busy = false
	
	self:GetPlayerInfo( self.name )
end

-------------------------------------------------------------------------------
function Delleren.Inspect:GetPlayerInfo( name )
	local data = {
		spec = GetInspectSpecialization( name );
		talents = "";
		glyphs = {};
	}
	
	for tier = 1,7 do
		if GetTalentInfo( tier, 1, nil, true, name ) then
			data.talents = data.talents .. "1"
		elseif GetTalentInfo( tier, 2, nil, true, name ) then
			data.talents = data.talents .. "2"
		elseif GetTalentInfo( tier, 3, nil, true, name ) then
			data.talents = data.talents .. "3"
		else
			data.talents = data.talents .. "0"
		end
	end 
	
	for g = 1,NUM_GLYPH_SLOTS do
		local enabled, _, _, spellid = GetGlyphSocketInfo( g, nil, true, name )
		
		if enabled and Delleren.SpellData:GlyphFilter( spellid ) then
			table.insert( data.glyphs, spellid )
		end
	end
	
	table.sort( data.glyphs )
	
	-- Do something with it.
	Delleren.Status:UpdatePlayerFromInspect( data )
end
