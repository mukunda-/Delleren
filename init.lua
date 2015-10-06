-------------------------------------------------------------------------------
-- DELLEREN
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

local VERSION = "1.3.8"

-------------------------------------------------------------------------------
DellerenAddon = LibStub("AceAddon-3.0"):NewAddon( "Delleren", 
	             		  "AceComm-3.0", "AceEvent-3.0", "AceSerializer-3.0",
						  "AceTimer-3.0" ) 

local Delleren = DellerenAddon

-------------------------------------------------------------------------------
Delleren.version    = VERSION
Delleren.unlocked   = false
Delleren.init_funcs = {}

-------------------------------------------------------------------------------
function Delleren:AddSetup( func )
	
	table.insert( self.init_funcs, func )
end

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
	self:InitMasque()

	for _,init in pairs( self.init_funcs ) do
		init()
	end
	
end
