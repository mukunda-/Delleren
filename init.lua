-------------------------------------------------------------------------------
-- Delleren
-- External CD caller.
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
--
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

DellerenAddon = LibStub("AceAddon-3.0"):NewAddon( "Delleren", 
	             		  "AceComm-3.0", "AceEvent-3.0", "AceSerializer-3.0",
						  "AceTimer-3.0" ) 
						  
local Delleren = DellerenAddon

-------------------------------------------------------------------------------
Delleren.unlocked   = false
			  
-------------------------------------------------------------------------------
function Delleren:InitMasque()
	local masque = LibStub( "Masque", true )
	
	if masque then
		self.masque_group = masque:Group( "Delleren", "Button" )
	end
	
end
 
-------------------------------------------------------------------------------
function Delleren:InitFrames()
 
--	local frame = CreateFrame( "Frame", "DellerenCDFrame" )
--	frame:SetMovable( true )
--	frame:EnableMouse( false )
--	frame:Show()
end

-------------------------------------------------------------------------------
function Delleren:Setup()
	self:InitMasque()
	
	self:InitFrames() 
	
	self.Indicator:Init()
	
	if self.masque_group then
		self.masque_group:ReSkin()
	end
end
