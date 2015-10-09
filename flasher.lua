-------------------------------------------------------------------------------
-- DELLEREN
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

-- unitframe flasher

local Delleren = DellerenAddon

Delleren.Flasher = {
	active    = false;
	player    = nil;
	frames    = {};
	fcount    = 0;
	flashtime = 0;
};

-------------------------------------------------------------------------------
-- Iterate over unit buttons that are linked to a certain player.
--
-- @param name Name of player.
--
local function IterateUnitButtons( name )
	local unitid = UnitInRaid( name )
	if not unitid then return function() end end
	unitid = "raid" .. unitid
	
	local frame = nil
	
	return function()
	
		while true do
			
			frame = EnumerateFrames( frame )
			if not frame then return end
			
			if frame:GetAttribute( "unit" ) == unitid
			   and frame:GetScript( "OnClick" ) == SecureUnitButton_OnClick then
			   --thanks Semler!
			   
				return frame
			end
		end
	end
end

-------------------------------------------------------------------------------
function Delleren.Flasher:CreateNewFrame()
	local frame = CreateFrame( "Frame" )
	
	frame.tex = frame:CreateTexture( nil )
	frame.tex:SetAllPoints()
	frame.tex:SetBlendMode( "ADD" )
	return frame
end

-------------------------------------------------------------------------------
function Delleren.Flasher:SetupFrame( index, parent )
	
	local frame = self.frames[index]
	if not frame then
		frame = self:CreateNewFrame()
		self.frames[index] = frame
	end
	
	frame.tex:SetTexture( 0,0,0,0 )
	frame:ClearAllPoints()
	frame:SetParent( parent )
	frame:SetAllPoints()
	frame:Show()
	frame:SetFrameStrata( "HIGH" )
end

-------------------------------------------------------------------------------
-- Setup the module to flash a given player.
--
-- @param name Name of player.
--
function Delleren.Flasher:Start( name )
	
	local count = 0
	for frame in IterateUnitButtons( name ) do
	
		count = count + 1
		self:SetupFrame( count, frame )
	end
	self.fcount = count
	
	for i = self.fcount+1,#self.frames do
		self.frames[i]:Hide()
	end
	
	self.flashtime = -10
	
	self.active = true
end

-------------------------------------------------------------------------------
-- Emit a flash.
--
function Delleren.Flasher:Flash()
	self.flashtime = GetTime()
end

-------------------------------------------------------------------------------
-- Frame update function.
--
function Delleren.Flasher:Update()
	if not self.active then return end
	
	local flash = GetTime() - self.flashtime 
	
	flash = flash * 2.0
	flash = 1.0 - flash
	flash = math.min( flash, 1.0 )
	flash = math.max( flash, 0.0 ) 
	
	flash = math.pow( flash, 2.5 )
	
	---
	flash = math.min( flash, 1.0 )
	flash = math.max( flash, 0.0 )
	
	for i = 1, self.fcount do
		self.frames[i].tex:SetTexture( flash, flash, flash, 1 )
	end
	
end

-------------------------------------------------------------------------------
-- Stop flashing a unit.
--
function Delleren.Flasher:Stop()
	if not self.active then return end
	
	for _,frame in pairs(self.frames) do
		frame:Hide()
	end
	self.active = false
end
