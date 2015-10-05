-------------------------------------------------------------------------------
-- DELLEREN
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

local VERSION = "1.3.7"

-------------------------------------------------------------------------------
DellerenAddon = LibStub("AceAddon-3.0"):NewAddon( "Delleren", 
	             		  "AceComm-3.0", "AceEvent-3.0", "AceSerializer-3.0",
						  "AceTimer-3.0" ) 

local Delleren = DellerenAddon

-------------------------------------------------------------------------------
Delleren.version  = VERSION
Delleren.unlocked = false

-------------------------------------------------------------------------------
function Delleren:InitMasque()
	local masque = LibStub( "Masque", true )
	
	if masque then
		self.masque_group = masque:Group( "Delleren", "Button" )
		self.masque_group_bar = masque:Group( "Delleren", "CDBar" )
		self.masque = true
	end
	
end

-------------------------------------------------------------------------------
function Delleren:Setup()
	self.MinimapButton:Init()
	self:InitMasque()
	
	self.Indicator:Init()
	self.CDBar:Init()
	self.QueryList:Init()
end
